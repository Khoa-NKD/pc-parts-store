import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/services/order_service.dart';
import '../order/order_detail_screen.dart';

final adminAllOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) {
  return ref.watch(orderServiceProvider).getAllOrders();
});

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(adminAllOrdersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(adminAllOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý đơn hàng')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('Chưa có đơn hàng'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(adminAllOrdersProvider),
                child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (_, i) {
                  final o = orders[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      title: Text('Đơn #${o.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${o.userName} • ${CurrencyFormatter.formatVND(o.totalAmount)}'),
                        OrderStatusBadge(status: o.status),
                      ]),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('SĐT: ${o.phone}'),
                            Text('Địa chỉ: ${o.shippingAddress}'),
                            const SizedBox(height: 8),
                            ...o.items.map<Widget>((item) => Text(
                                '• ${item.productName} x${item.quantity} = ${CurrencyFormatter.formatVND(item.subtotal)}')),
                            const SizedBox(height: 12),
                            const Text('Cập nhật trạng thái:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                AppConstants.orderPending,
                                AppConstants.orderConfirmed,
                                AppConstants.orderShipping,
                                AppConstants.orderDelivered,
                                AppConstants.orderCancelled,
                              ].map((status) => ActionChip(
                                label: Text(_label(status)),
                                backgroundColor: o.status == status ? Colors.blue.shade100 : null,
                                onPressed: () async {
                                  await ref.read(orderServiceProvider).updateOrderStatus(o.id, status);
                                  ref.invalidate(adminAllOrdersProvider);
                                  ref.invalidate(allOrdersProvider);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(duration: const Duration(seconds: 1), content: Text('Đã cập nhật: ${_label(status)}')));
                                  }
                                },
                              )).toList(),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ),
      ),
    );
  }

  String _label(String s) => const {
    'pending': 'Chờ xác nhận', 'confirmed': 'Xác nhận',
    'shipping': 'Đang giao', 'delivered': 'Đã giao', 'cancelled': 'Hủy',
  }[s] ?? s;
}
