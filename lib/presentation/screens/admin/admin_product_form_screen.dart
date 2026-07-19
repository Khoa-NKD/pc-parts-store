import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';

import '../../../data/models/product_model.dart';
import '../../../data/services/product_service.dart';
import '../../providers/product_provider.dart';

class AdminProductFormScreen extends ConsumerStatefulWidget {
  final String? productId;
  const AdminProductFormScreen({super.key, this.productId});
  @override
  ConsumerState<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends ConsumerState<AdminProductFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _salePriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  String _category = 'cpu';
  bool _isFeatured = false, _loading = false;
  ProductModel? _editing;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) _load();
  }

  Future<void> _load() async {
    final p = await ref.read(productServiceProvider).getProductById(widget.productId!);
    if (p != null && mounted) {
      setState(() {
        _editing = p;
        _nameCtrl.text = p.name;
        _descCtrl.text = p.description;
        _priceCtrl.text = p.price.toString();
        _salePriceCtrl.text = p.salePrice?.toString() ?? '';
        _stockCtrl.text = p.stock.toString();
        _brandCtrl.text = p.brand;
        _imageCtrl.text = p.images.isNotEmpty ? p.images.first : '';
        _category = p.category;
        _isFeatured = p.isFeatured;
      });
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final images = _imageCtrl.text.trim().isNotEmpty ? [_imageCtrl.text.trim()] : <String>[];
      final product = ProductModel(
        id: _editing?.id ?? const Uuid().v4(),
        name: _nameCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        category: _category,
        brand: _brandCtrl.text.trim(),
        price: double.parse(_priceCtrl.text),
        salePrice: _salePriceCtrl.text.isNotEmpty ? double.tryParse(_salePriceCtrl.text) : null,
        stock: int.parse(_stockCtrl.text),
        images: images,
        isFeatured: _isFeatured,
        createdAt: _editing?.createdAt ?? DateTime.now(),
      );
      await ref.read(productServiceProvider).upsertProduct(product);
      ref.invalidate(productsProvider);
      ref.invalidate(featuredProductsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 1), 
            content: Text(_editing != null ? 'Đã cập nhật' : 'Đã thêm sản phẩm')));
        context.pop();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 1), content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _descCtrl.dispose(); _priceCtrl.dispose();
    _salePriceCtrl.dispose(); _stockCtrl.dispose(); _brandCtrl.dispose();
    _imageCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.productId != null ? 'Chỉnh sửa' : 'Thêm sản phẩm')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _field(_nameCtrl, 'Tên sản phẩm', required: true),
          const SizedBox(height: 12),
          _field(_brandCtrl, 'Thương hiệu', required: true),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Danh mục'),
            items: AppConstants.categories.map((c) =>
                DropdownMenuItem(value: c['id'], child: Text('${c['icon']} ${c['name']}'))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field(_priceCtrl, 'Giá gốc (VNĐ)', required: true, numeric: true)),
            const SizedBox(width: 12),
            Expanded(child: _field(_salePriceCtrl, 'Giá sale', numeric: true)),
          ]),
          const SizedBox(height: 12),
          _field(_stockCtrl, 'Số lượng kho', required: true, numeric: true),
          const SizedBox(height: 12),
          _field(_imageCtrl, 'URL hình ảnh'),
          const SizedBox(height: 12),
          _field(_descCtrl, 'Mô tả', maxLines: 4),
          const SizedBox(height: 12),
          SwitchListTile(
            title: const Text('Sản phẩm nổi bật'),
            value: _isFeatured,
            onChanged: (v) => setState(() => _isFeatured = v),
            activeThumbColor: DesignTokens.primary,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(widget.productId != null ? 'Cập nhật' : 'Thêm sản phẩm', style: const TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {bool required = false, bool numeric = false, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl, maxLines: maxLines,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(labelText: label),
      validator: required ? (v) => v!.isEmpty ? 'Nhập $label' : null : null,
    );
  }
}


