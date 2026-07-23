import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/order_service.dart';

final allOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(orderServiceProvider).getAllOrders();
});

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(allOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết đơn hàng')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Không tìm thấy')),
        data: (orders) {
          final order = orders.where((o) => o.id == orderId).firstOrNull;
          if (order == null) return const Center(child: Text('Không tìm thấy đơn hàng'));
          return ListView(padding: const EdgeInsets.all(16), children: [
            if (order.status == 'pending')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Row(children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 32),
                  SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Đặt hàng thành công!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Chúng tôi sẽ xác nhận sớm nhất', style: TextStyle(color: Colors.grey)),
                  ])),
                ]),
              ),
            const SizedBox(height: 16),
            _Card(title: 'Trạng thái', child: OrderStatusBadge(status: order.status)),
            const SizedBox(height: 12),
            _Card(title: 'Giao hàng', child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.userName, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(order.phone),
              Text(order.shippingAddress),
            ])),
            const SizedBox(height: 12),
            _Card(title: 'Sản phẩm', child: Column(children: order.items.map<Widget>((item) =>
              Padding(padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  Expanded(child: Text('${item.productName} x${item.quantity}')),
                  Text(CurrencyFormatter.formatVND(item.subtotal),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ]),
              )).toList(),
            )),
            const SizedBox(height: 12),
            _Card(title: 'Thanh toán', child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Phương thức'), Text(order.paymentMethod.toUpperCase()),
              ]),
              const Divider(),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tổng cộng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(CurrencyFormatter.formatVND(order.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: DesignTokens.primary)),
              ]),
            ])),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Tiếp tục mua sắm')),
          ]);
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }
}

class OrderStatusBadge extends StatelessWidget {
  final String status;
  const OrderStatusBadge({super.key, required this.status});

  static const _map = {
    'pending':   ('Chờ xác nhận', Colors.orange),
    'confirmed': ('Đã xác nhận',  Colors.blue),
    'shipping':  ('Đang giao',    Colors.purple),
    'delivered': ('Đã giao',      Colors.green),
    'cancelled': ('Đã hủy',       Colors.red),
  };

  @override
  Widget build(BuildContext context) {
    final info = _map[status] ?? ('Không rõ', Colors.grey);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: info.$2.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(info.$1,
          style: TextStyle(color: info.$2, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}


