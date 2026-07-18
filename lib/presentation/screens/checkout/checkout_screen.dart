import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _payment = 'cod';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    if (user != null) {
      _addressCtrl.text = user.address ?? '';
      _phoneCtrl.text = user.phone ?? '';
    }
  }

  @override
  void dispose() { _addressCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _placeOrder() async {
    if (!_form.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    setState(() => _loading = true);
    try {
      final cart = ref.read(cartProvider);
      final orderId = await ref.read(orderServiceProvider).placeOrder(
        user: user, items: cart,
        shippingAddress: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        paymentMethod: _payment,
      );
      await ref.read(cartProvider.notifier).clear();
      // Invalidate products để cập nhật stock mới
      ref.invalidate(productsProvider);
      ref.invalidate(featuredProductsProvider);
      if (mounted) context.go('/order/$orderId');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thanh toán')),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Thông tin giao hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Số điện thoại', prefixIcon: Icon(Icons.phone)),
            validator: (v) => v!.isEmpty ? 'Nhập số điện thoại' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressCtrl, maxLines: 2,
            decoration: const InputDecoration(labelText: 'Địa chỉ giao hàng', prefixIcon: Icon(Icons.location_on)),
            validator: (v) => v!.isEmpty ? 'Nhập địa chỉ' : null,
          ),
          const SizedBox(height: 20),
          const Text('Phương thức thanh toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _PayOption(value: 'cod', label: 'Thanh toán khi nhận hàng (COD)', icon: Icons.money, selected: _payment, onTap: (v) => setState(() => _payment = v)),
          _PayOption(value: 'bank', label: 'Chuyển khoản ngân hàng', icon: Icons.account_balance, selected: _payment, onTap: (v) => setState(() => _payment = v)),
          _PayOption(value: 'momo', label: 'Ví MoMo', icon: Icons.wallet, selected: _payment, onTap: (v) => setState(() => _payment = v)),
          const SizedBox(height: 20),
          const Text('Đơn hàng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...cart.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              Expanded(child: Text('${item.product.name} x${item.quantity}', maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(CurrencyFormatter.formatVND(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          )),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tổng cộng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(CurrencyFormatter.formatVND(total),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
          ]),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loading ? null : _placeOrder,
            child: _loading
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Đặt hàng', style: TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  final String value, label, selected;
  final IconData icon;
  final ValueChanged<String> onTap;
  const _PayOption({required this.value, required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: sel ? AppTheme.primary : Colors.transparent, width: 2),
        ),
        child: ListTile(
          leading: Radio<String>(value: value, groupValue: selected, onChanged: (v) => onTap(v!), activeColor: AppTheme.primary),
          title: Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Expanded(child: Text(label))]),
        ),
      ),
    );
  }
}
