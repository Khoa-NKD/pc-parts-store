import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import 'payos_webview_screen.dart';

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
      final total = ref.read(cartTotalProvider);
      
      final orderId = await ref.read(orderServiceProvider).placeOrder(
        user: user, items: cart,
        shippingAddress: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        paymentMethod: _payment,
      );

      // Nếu chọn PayOS, thực hiện thêm bước thanh toán
      if (_payment == 'payos') {
        final int orderCode = _generateNumericOrderCode(orderId);
        
        final paymentUrl = await ref.read(orderServiceProvider).createPayOSPaymentLink(
          orderId: orderId,
          amount: total,
          description: 'DH $orderCode', // Rút ngắn mô tả xuống dưới 25 ký tự
        );

        if (mounted) {
          final int orderCode = _generateNumericOrderCode(orderId);
          final result = await Navigator.push<String>(
            context,
            MaterialPageRoute(
              builder: (context) => PayOSWebViewScreen(
                url: paymentUrl,
                orderCode: orderCode,
              ),
            ),
          );

          if (result == 'success') {
            // Thanh toán thành công
            await _finalizeOrder(orderId);
          } else {
            // Thanh toán bị hủy hoặc lỗi
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanh toán đã bị hủy')),
              );
            }
          }
        }
      } else {
        // Nếu là COD hoặc bank khác
        await _finalizeOrder(orderId);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(duration: const Duration(seconds: 1), content: Text('Lỗi: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _finalizeOrder(String orderId) async {
    // Cập nhật trạng thái đơn hàng trong Database sang 'PAID'
    await ref.read(orderServiceProvider).updateOrderStatus(orderId, 'PAID');

    await ref.read(cartProvider.notifier).clear();
    ref.invalidate(productsProvider);
    ref.invalidate(featuredProductsProvider);
    if (mounted) context.go('/order/$orderId');
  }

  /// Helper để chuyển UUID String sang số nguyên cho PayOS (phải khớp với OrderService)
  int _generateNumericOrderCode(String uuid) {
    final String hex = uuid.replaceAll('-', '').substring(0, 8);
    return int.parse(hex, radix: 16);
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
          _PayOption(value: 'payos', label: 'Thanh toán qua PayOS (VietQR)', icon: Icons.qr_code, selected: _payment, onTap: (v) => setState(() => _payment = v)),
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
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DesignTokens.primary)),
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
          side: BorderSide(color: sel ? DesignTokens.primary : Colors.transparent, width: 2),
        ),
        child: ListTile(
          leading: Radio<String>(value: value, groupValue: selected, onChanged: (v) => onTap(v!), activeColor: DesignTokens.primary),
          title: Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Expanded(child: Text(label))]),
        ),
      ),
    );
  }
}


