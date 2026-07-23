import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/local/database_helper.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/auth_service.dart';

final adminUsersProvider = FutureProvider.autoDispose<List<UserModel>>((ref) {
  return ref.watch(dbProvider).getAllUsers();
});

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(adminUsersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý tài khoản')),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (users) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(adminUsersProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (_, i) {
              final u = users[i];
              final isSelf = u.id == currentUser?.id;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  onTap: () => context.push('/admin/users/${u.id}'),
                  leading: CircleAvatar(
                    backgroundColor: u.isLocked
                        ? Colors.grey
                        : (u.isAdmin ? Colors.amber : DesignTokens.primary),
                    child: Text(u.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Row(children: [
                    Text(u.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: u.isLocked ? Colors.grey : null)),
                    const SizedBox(width: 6),
                    if (u.isAdmin)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('ADMIN',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    if (u.isLocked)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('KHÓA',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.red,
                                fontWeight: FontWeight.bold)),
                      ),
                    if (isSelf)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text('Bạn',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ),
                  ]),
                  subtitle: Text(u.email),
                  trailing: isSelf
                      ? const Icon(Icons.chevron_right, color: Colors.grey)
                      : Row(mainAxisSize: MainAxisSize.min, children: [
                          PopupMenuButton<String>(
                            onSelected: (action) =>
                                _handleAction(context, ref, u, action),
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: u.isAdmin ? 'demote' : 'promote',
                                child: Row(children: [
                                  Icon(
                                    u.isAdmin
                                        ? Icons.person
                                        : Icons.admin_panel_settings,
                                    size: 18,
                                    color: u.isAdmin ? Colors.orange : Colors.blue,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(u.isAdmin ? 'Hạ xuống User' : 'Nâng lên Admin'),
                                ]),
                              ),
                              PopupMenuItem(
                                value: u.isLocked ? 'unlock' : 'lock',
                                child: Row(children: [
                                  Icon(
                                    u.isLocked ? Icons.lock_open : Icons.lock,
                                    size: 18,
                                    color: u.isLocked ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(u.isLocked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                                      style: TextStyle(
                                          color: u.isLocked ? Colors.green : Colors.red)),
                                ]),
                              ),
                            ],
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ]),
                ),
              );
            },
          ),
        ),
      ),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 1), 
            content: Text(locking ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản')));
      }
    } else {
      final newRole = action == 'promote' ? 'admin' : 'user';
      await ref.read(dbProvider).setUserRole(u.id, newRole);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(duration: const Duration(seconds: 1), content: Text('Đã cập nhật quyền')));
      }
    }
    ref.invalidate(adminUsersProvider);
  }
}


