import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/order_service.dart';
import '../order/order_detail_screen.dart';
import 'admin_users_screen.dart';

final _userDetailOrdersProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>((ref, userId) {
  return ref.watch(orderServiceProvider).getUserOrders(userId);
});

class AdminUserDetailScreen extends ConsumerWidget {
  final String userId;
  const AdminUserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return usersAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
      data: (users) {
        final user = users.where((u) => u.id == userId).firstOrNull;
        if (user == null) {
          return const Scaffold(body: Center(child: Text('Không tìm thấy')));
        }
        final isSelf = user.id == currentUser?.id;
        final ordersAsync = ref.watch(_userDetailOrdersProvider(userId));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Chi tiết tài khoản'),
            actions: [
              if (!isSelf)
                PopupMenuButton<String>(
                  onSelected: (action) =>
                      _handleAction(context, ref, user, action),
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: user.isAdmin ? 'demote' : 'promote',
                      child: Row(children: [
                        Icon(
                          user.isAdmin ? Icons.person : Icons.admin_panel_settings,
                          size: 18,
                          color: user.isAdmin ? Colors.orange : Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        Text(user.isAdmin ? 'Hạ xuống User' : 'Nâng lên Admin'),
                      ]),
                    ),
                    PopupMenuItem(
                      value: user.isLocked ? 'unlock' : 'lock',
                      child: Row(children: [
                        Icon(
                          user.isLocked ? Icons.lock_open : Icons.lock,
                          size: 18,
                          color: user.isLocked ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          user.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                          style: TextStyle(color: user.isLocked ? Colors.green : Colors.red),
                        ),
                      ]),
                    ),
                  ],
                ),
            ],
          ),
          body: ListView(padding: const EdgeInsets.all(16), children: [
            // Avatar + basic info
            Center(
              child: Column(children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: user.isAdmin ? Colors.amber : DesignTokens.primary,
                  child: Text(user.name[0].toUpperCase(),
                      style: const TextStyle(
                          fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(user.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  if (user.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                      child: const Text('ADMIN',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  if (isSelf)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(4)),
                      child: const Text('Bạn',
                          style: TextStyle(
                              fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // Info card
            _InfoCard(children: [
              _InfoRow(icon: Icons.email_outlined, label: 'Email', value: user.email),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Điện thoại',
                value: (user.phone?.isNotEmpty == true) ? user.phone! : '—',
              ),
              _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Địa chỉ',
                value: (user.address?.isNotEmpty == true) ? user.address! : '—',
              ),
              _InfoRow(
                icon: Icons.shield_outlined,
                label: 'Quyền',
                value: user.isAdmin ? 'Admin' : 'Người dùng',
                valueColor: user.isAdmin ? Colors.amber.shade700 : Colors.grey,
              ),
              _InfoRow(
                icon: user.isLocked ? Icons.lock : Icons.lock_open,
                label: 'Trạng thái',
                value: user.isLocked ? 'Đã khóa' : 'Hoạt động',
                valueColor: user.isLocked ? Colors.red : Colors.green,
              ),
            ]),
            const SizedBox(height: 16),

            // Orders
            const Text('Lịch sử đơn hàng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Lỗi: $e'),
              data: (orders) => orders.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Text('Chưa có đơn hàng nào',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : Column(
                      children: orders.map<Widget>((o) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OrderDetailScreen(orderId: o.id),
                            ),
                          ),
                          title: Text(
                              'Đơn #${o.id.substring(0, 8).toUpperCase()}',
                              style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                              '${o.items.length} sản phẩm • ${CurrencyFormatter.formatVND(o.totalAmount)}'),
                          trailing: OrderStatusBadge(status: o.status),
                        ),
                      )).toList(),
                    ),
            ),
          ]),
        );
      },
    );
  }

  void _handleAction(
      BuildContext context, WidgetRef ref, UserModel u, String action) async {
    if (action == 'lock' || action == 'unlock') {
      final locking = action == 'lock';
      final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(locking ? 'Khóa tài khoản' : 'Mở khóa tài khoản'),
          content: Text(locking
              ? 'Khóa tài khoản "${u.name}"? Người dùng sẽ không thể đăng nhập.'
              : 'Mở khóa tài khoản "${u.name}"?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(locking ? 'Khóa' : 'Mở khóa',
                  style: TextStyle(color: locking ? Colors.red : Colors.green)),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      await ref.read(dbProvider).setUserLocked(u.id, locking);
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 1), 
            content: Text(locking ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản')));
      }
    } else {
      final newRole = action == 'promote' ? 'admin' : 'user';
      await ref.read(dbProvider).setUserRole(u.id, newRole);
      ref.invalidate(adminUsersProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(duration: const Duration(seconds: 1), content: Text('Đã cập nhật quyền')));
      }
    }
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)]),
      child: Column(
        children: children
            .expand((w) => [w, const Divider(height: 16)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: Colors.grey),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      const Spacer(),
      Flexible(
        child: Text(value,
            textAlign: TextAlign.end,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: valueColor ?? Colors.black87)),
      ),
    ]);
  }
}


