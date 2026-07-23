import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/product_service.dart';
import '../../providers/product_provider.dart';
import '../../widgets/common/premium_card.dart';
import '../admin/admin_orders_screen.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(productsProvider);
      ref.invalidate(adminAllOrdersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(const ProductFilter()));
    final ordersAsync = ref.watch(adminAllOrdersProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: DesignTokens.primary,
            title: Text('Dashboard', style: DesignTokens.h3.copyWith(color: Colors.white)),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.logOut, color: Colors.white),
                tooltip: 'Đăng xuất',
                onPressed: () async {
                  await ref.read(currentUserProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DesignTokens.primary, DesignTokens.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                  child: Text(
                    'Chào, ${user?.name ?? "Admin"}',
                    style: DesignTokens.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: productsAsync.when(
                          loading: () => const _StatCard(title: 'Sản phẩm', value: '...', icon: LucideIcons.package, color: DesignTokens.primary),
                          error: (_, __) => const _StatCard(title: 'Sản phẩm', value: '0', icon: LucideIcons.package, color: DesignTokens.primary),
                          data: (p) => _StatCard(title: 'Sản phẩm', value: '${p.length}', icon: LucideIcons.package, color: DesignTokens.primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ordersAsync.when(
                          loading: () => const _StatCard(title: 'Đơn hàng', value: '...', icon: LucideIcons.shoppingBag, color: DesignTokens.accent),
                          error: (_, __) => const _StatCard(title: 'Đơn hàng', value: '0', icon: LucideIcons.shoppingBag, color: DesignTokens.accent),
                          data: (o) => _StatCard(title: 'Đơn hàng', value: '${o.length}', icon: LucideIcons.shoppingBag, color: DesignTokens.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text('Quản lý hệ thống', style: DesignTokens.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _AdminAction(
                    icon: LucideIcons.plusCircle,
                    title: 'Thêm sản phẩm mới',
                    subtitle: 'Cập nhật kho hàng với linh kiện mới',
                    onTap: () => context.push('/admin/product'),
                  ),
                  _AdminAction(
                    icon: LucideIcons.layoutList,
                    title: 'Danh sách sản phẩm',
                    subtitle: 'Chỉnh sửa, cập nhật hoặc xóa sản phẩm',
                    onTap: () => _showProducts(context),
                  ),
                  _AdminAction(
                    icon: LucideIcons.fileText,
                    title: 'Quản lý đơn hàng',
                    subtitle: 'Theo dõi và xử lý đơn hàng của khách',
                    onTap: () => context.push('/admin/orders'),
                  ),
                  _AdminAction(
                    icon: LucideIcons.tags,
                    title: 'Quản lý danh mục',
                    subtitle: 'Phân loại linh kiện máy tính',
                    onTap: () => context.push('/admin/categories'),
                  ),
                  _AdminAction(
                    icon: LucideIcons.users,
                    title: 'Quản lý khách hàng',
                    subtitle: 'Xem thông tin người dùng hệ thống',
                    onTap: () => context.push('/admin/users'),
                  ),
                  _AdminAction(
                    icon: LucideIcons.barChart3,
                    title: 'Báo cáo doanh thu',
                    subtitle: 'Thống kê chi tiết kết quả kinh doanh',
                    onTap: () => context.push('/admin/revenue'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProducts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: DesignTokens.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.borderRadiusXL)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: DesignTokens.border, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Danh sách sản phẩm', style: DesignTokens.h3.copyWith(fontSize: 20)),
                  IconButton(icon: const Icon(LucideIcons.x), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            const Expanded(child: _ProductManagementList()),
          ],
        ),
      ),
    );
  }
}

class _ProductManagementList extends ConsumerWidget {
  const _ProductManagementList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productsProvider(const ProductFilter()));
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (products) => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        itemBuilder: (_, i) {
          final p = products[i];
          return PremiumCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: DesignTokens.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              subtitle: Text('${p.category.toUpperCase()} • Kho: ${p.stock}', style: DesignTokens.bodySmall),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.edit3, color: DesignTokens.primary, size: 20),
                    onPressed: () { Navigator.pop(context); context.push('/admin/product?id=${p.id}'); },
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: DesignTokens.danger, size: 20),
                    onPressed: () => _confirmDelete(context, ref, p),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, dynamic p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc muốn xóa sản phẩm ${p.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await ref.read(productServiceProvider).deleteProduct(p.id);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(duration: const Duration(seconds: 1), content: Text('Đã xóa thành công')));
                ref.invalidate(productsProvider);
              }
            },
            child: const Text('Xóa', style: TextStyle(color: DesignTokens.danger)),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusL),
        boxShadow: DesignTokens.shadowSm,
        border: Border.all(color: DesignTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(DesignTokens.borderRadiusS)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(value, style: DesignTokens.h2.copyWith(fontSize: 28, color: DesignTokens.textPrimary)),
          Text(title, style: DesignTokens.bodySmall.copyWith(color: DesignTokens.textSecondary)),
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _AdminAction({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: DesignTokens.primary.withValues(alpha: 0.05), shape: BoxShape.circle),
            child: Icon(icon, color: DesignTokens.primary, size: 20),
          ),
          title: Text(title, style: DesignTokens.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: DesignTokens.bodySmall),
          trailing: const Icon(LucideIcons.chevronRight, size: 18, color: DesignTokens.textSecondary),
        ),
      ),
    );
  }
}
