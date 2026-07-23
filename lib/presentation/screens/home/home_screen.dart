import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/design_tokens.dart';
import '../../providers/category_provider.dart' as cat_prov;
import '../../providers/product_provider.dart';
import '../product/product_list_screen.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_shimmer.dart';
import '../../widgets/common/premium_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  int _currentPage = 0;
  Timer? _timer;

  static const _banners = [
    _BannerData(
      color: DesignTokens.primary,
      title: 'CPU Intel Gen 14',
      subtitle: 'Hiệu năng đỉnh cao cho gaming',
      icon: LucideIcons.cpu,
      discount: 'Giảm 20%',
    ),
    _BannerData(
      color: DesignTokens.secondary,
      title: 'RTX 4000 Series',
      subtitle: 'Đồ họa chân thực với Ray Tracing',
      icon: LucideIcons.monitor,
      discount: 'Hàng mới',
    ),
    _BannerData(
      color: DesignTokens.accent,
      title: 'RAM DDR5 PRO',
      subtitle: 'Tốc độ bus cực cao 6000MHz',
      icon: LucideIcons.zap,
      discount: 'Giá sốc',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageController.hasClients) {
        final next = (_currentPage + 1) % _banners.length;
        _pageController.animateToPage(next, duration: const Duration(milliseconds: 600), curve: Curves.easeInOutCubic);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredProductsProvider);
    final categoriesAsync = ref.watch(cat_prov.categoriesProvider);

    return Scaffold(
      backgroundColor: DesignTokens.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: DesignTokens.background,
            elevation: 0,
            title: Text('PC Store', style: DesignTokens.h3.copyWith(fontSize: 20)),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.heart, size: 22, color: DesignTokens.textPrimary),
                onPressed: () => context.go('/wishlist'),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: GestureDetector(
                  onTap: () => context.go('/products'),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
                      border: Border.all(color: DesignTokens.border),
                      boxShadow: DesignTokens.shadowSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search, color: DesignTokens.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Text('Tìm kiếm linh kiện...', style: DesignTokens.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _banners.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _BannerItem(data: _banners[i]),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _banners.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? DesignTokens.primary : DesignTokens.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Danh mục', style: DesignTokens.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () => context.go('/products'),
                        child: Text('Xem thêm', style: DesignTokens.bodySmall.copyWith(color: DesignTokens.primary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 110,
                  child: categoriesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (cats) => ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: cats.length,
                      itemBuilder: (_, i) => _CategoryItem(
                        icon: cats[i].icon,
                        label: cats[i].name,
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state = cats[i].id;
                          context.go('/products');
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Sản phẩm nổi bật',
                    style: DesignTokens.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          featuredAsync.when(
            loading: () => const SliverToBoxAdapter(child: LoadingShimmer()),
            error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Lỗi: $e'))),
            data: (products) => SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(product: products[i]),
                  childCount: products.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.60,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _BannerData {
  final Color color;
  final String title, subtitle, discount;
  final IconData icon;
  const _BannerData({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.discount,
  });
}

class _BannerItem extends StatelessWidget {
  final _BannerData data;
  const _BannerItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: EdgeInsets.zero,
      borderRadius: DesignTokens.borderRadiusXL,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [data.color, data.color.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusS),
                    ),
                    child: Text(
                      data.discount,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    data.title,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    data.subtitle,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(data.icon, size: 80, color: Colors.white.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _CategoryItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          children: [
            Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
                boxShadow: DesignTokens.shadowSm,
                border: Border.all(color: DesignTokens.border),
              ),
              child: Center(
                child: Text(icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DesignTokens.bodySmall.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
