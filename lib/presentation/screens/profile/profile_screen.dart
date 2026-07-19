import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../data/services/auth_service.dart';
import '../../widgets/common/premium_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        title: Text('Tài khoản', style: DesignTokens.h3.copyWith(fontSize: 20)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PremiumCard(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: DesignTokens.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      user.name[0].toUpperCase(),
                      style: DesignTokens.h2.copyWith(color: DesignTokens.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.name, style: DesignTokens.h3.copyWith(fontSize: 20)),
                      Text(user.email, style: DesignTokens.bodySmall),
                      if (user.isAdmin)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: DesignTokens.warning.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusS),
                          ),
                          child: Text(
                            'ADMINISTRATOR',
                            style: DesignTokens.bodySmall.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: DesignTokens.warning,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Cá nhân', style: DesignTokens.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _ProfileItem(
            icon: LucideIcons.user,
            label: 'Chỉnh sửa hồ sơ',
            onTap: () => context.push('/edit-profile'),
          ),
          _ProfileItem(
            icon: LucideIcons.shoppingBag,
            label: 'Đơn hàng của tôi',
            onTap: () => context.push('/orders'),
          ),
          _ProfileItem(
            icon: LucideIcons.heart,
            label: 'Danh sách yêu thích',
            onTap: () => context.push('/wishlist'),
          ),
          if (user.isAdmin) ...[
            const SizedBox(height: 24),
            Text('Quản trị', style: DesignTokens.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _ProfileItem(
              icon: LucideIcons.layoutDashboard,
              label: 'Admin Dashboard',
              onTap: () => context.push('/admin'),
            ),
          ],
          const SizedBox(height: 24),
          _ProfileItem(
            icon: LucideIcons.logOut,
            label: 'Đăng xuất',
            color: DesignTokens.danger,
            onTap: () async {
              await ref.read(currentUserProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          leading: Icon(icon, color: color ?? DesignTokens.textPrimary, size: 20),
          title: Text(
            label,
            style: DesignTokens.bodyMedium.copyWith(
              color: color ?? DesignTokens.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(LucideIcons.chevronRight, size: 18, color: DesignTokens.textSecondary),
        ),
      ),
    );
  }
}
