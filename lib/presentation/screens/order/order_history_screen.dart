import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import 'order_detail_screen.dart';

final userOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(orderServiceProvider).getUserOrders(user.id);
});

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(userOrdersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Đơn hàng của tôi')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (orders) => orders.isEmpty
            ? const Center(child: Text('Chưa có đơn hàng nào'))
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(userOrdersProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        onTap: () => context.push('/order/${o.id}'),
                        title: Text('Đơn #${o.id.substring(0, 8).toUpperCase()}'),
                        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${o.items.length} sản phẩm • ${CurrencyFormatter.formatVND(o.totalAmount)}'),
                          const SizedBox(height: 4),
                          OrderStatusBadge(status: o.status),
                        ]),
                        trailing: const Icon(Icons.chevron_right),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}
