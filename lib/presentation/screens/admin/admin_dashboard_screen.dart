import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/product_service.dart';
import '../../providers/product_provider.dart';
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
    // Invalidate để luôn load data mới khi vào dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(productsProvider);
      ref.invalidate(adminAllOrdersProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider(const ProductFilter()));
    final ordersAsync = ref.watch(adminAllOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await ref.read(currentUserProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Row(children: [
          Expanded(child: productsAsync.when(
            loading: () => _Stat(title: 'Sản phẩm', value: '...', icon: Icons.inventory_2, color: AppTheme.primary),
            error: (_, __) => _Stat(title: 'Sản phẩm', value: '0', icon: Icons.inventory_2, color: AppTheme.primary),
            data: (p) => _Stat(title: 'Sản phẩm', value: '${p.length}', icon: Icons.inventory_2, color: AppTheme.primary),
          )),
          const SizedBox(width: 12),
          Expanded(child: ordersAsync.when(
            loading: () => _Stat(title: 'Đơn hàng', value: '...', icon: Icons.receipt_long, color: Colors.green),
            error: (_, __) => _Stat(title: 'Đơn hàng', value: '0', icon: Icons.receipt_long, color: Colors.green),
            data: (o) => _Stat(title: 'Đơn hàng', value: '${o.length}', icon: Icons.receipt_long, color: Colors.green),
          )),
        ]),
        const SizedBox(height: 20),
        const Text('Quản lý', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _Action(icon: Icons.add_box_outlined, title: 'Thêm sản phẩm mới', subtitle: 'Thêm linh kiện vào cửa hàng', onTap: () => context.push('/admin/product')),
        _Action(icon: Icons.inventory_2_outlined, title: 'Danh sách sản phẩm', subtitle: 'Chỉnh sửa, xóa sản phẩm', onTap: () => _showProducts(context, ref)),
        _Action(icon: Icons.receipt_long_outlined, title: 'Quản lý đơn hàng', subtitle: 'Xem và cập nhật trạng thái', onTap: () => context.push('/admin/orders')),
        _Action(icon: Icons.category_outlined, title: 'Quản lý danh mục', subtitle: 'Thêm, sửa, xóa danh mục', onTap: () => context.push('/admin/categories')),
        _Action(icon: Icons.people_outline, title: 'Quản lý tài khoản', subtitle: 'Xem, phân quyền người dùng', onTap: () => context.push('/admin/users')),
        _Action(icon: Icons.bar_chart_outlined, title: 'Thống kê doanh thu', subtitle: 'Doanh thu, đơn hàng theo danh mục', onTap: () => context.push('/admin/revenue')),
      ]),
    );
  }

  void _showProducts(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8, expand: false,
        builder: (_, ctrl) => _ProductList(scrollController: ctrl),
      ),
    );
  }
}

class _ProductList extends ConsumerWidget {
  final ScrollController scrollController;
  const _ProductList({required this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(productsProvider(const ProductFilter()));
    return Column(children: [
      const Padding(padding: EdgeInsets.all(16),
          child: Text('Danh sách sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
      Expanded(child: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (products) => ListView.builder(
          controller: scrollController,
          itemCount: products.length,
          itemBuilder: (_, i) {
            final p = products[i];
            return ListTile(
              title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${p.category.toUpperCase()} • Kho: ${p.stock}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primary),
                  onPressed: () { Navigator.pop(context); context.push('/admin/product?id=${p.id}'); },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await ref.read(productServiceProvider).deleteProduct(p.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa')));
                      ref.invalidate(productsProvider);
                    }
                  },
                ),
              ]),
            );
          },
        ),
      )),
    ]);
  }
}

class _Stat extends StatelessWidget {
  final String title, value;
  final IconData icon;
  final Color color;
  const _Stat({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: const TextStyle(color: Colors.grey)),
      ]),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _Action({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
