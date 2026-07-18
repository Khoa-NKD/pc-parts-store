import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(children: [
        Container(
          padding: const EdgeInsets.all(24),
          color: AppTheme.primary,
          child: Row(children: [
            CircleAvatar(
              radius: 36, backgroundColor: Colors.white,
              child: Text(user.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 28, color: AppTheme.primary, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              Text(user.email, style: const TextStyle(color: Colors.white70)),
              if (user.phone != null && user.phone!.isNotEmpty)
                Text(user.phone!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              if (user.isAdmin)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                  child: const Text('ADMIN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
            ])),
          ]),
        ),
        const SizedBox(height: 8),
        _Item(icon: Icons.edit_outlined, label: 'Chỉnh sửa hồ sơ', onTap: () => context.push('/edit-profile')),
        _Item(icon: Icons.shopping_bag_outlined, label: 'Đơn hàng của tôi', onTap: () => context.push('/orders')),
        _Item(icon: Icons.favorite_outline, label: 'Danh sách yêu thích', onTap: () => context.push('/wishlist')),
        if (user.isAdmin) ...[
          const Divider(),
          const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text('Quản trị', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600))),
          _Item(icon: Icons.dashboard_outlined, label: 'Admin Dashboard', onTap: () => context.push('/admin')),
        ],
        const Divider(),
        _Item(
          icon: Icons.logout, label: 'Đăng xuất', color: Colors.red,
          onTap: () async {
            await ref.read(currentUserProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _Item({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
