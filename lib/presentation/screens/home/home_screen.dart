import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/category_provider.dart' as cat_prov;
import '../../providers/product_provider.dart';
import '../product/product_list_screen.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_shimmer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  int _currentPage = 0;
  Timer? _timer;

  static const _banners = [
    _BannerData(color: Color(0xFF1A73E8), title: 'CPU Intel Gen 14', subtitle: 'Giảm đến 20%', icon: Icons.memory),
    _BannerData(color: Color(0xFF34A853), title: 'GPU RTX 4000 Series', subtitle: 'Hàng mới về', icon: Icons.videogame_asset),
    _BannerData(color: Color(0xFFFF6B35), title: 'RAM DDR5 6000MHz', subtitle: 'Giá tốt nhất', icon: Icons.storage),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      final next = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(next,
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          floating: true,
          backgroundColor: AppTheme.primary,
          title: GestureDetector(
            onTap: () => context.go('/products'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                const Icon(Icons.search, color: Colors.grey, size: 20),
                const SizedBox(width: 8),
                Text('Tìm kiếm linh kiện...', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ]),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_border, color: Colors.white),
              onPressed: () => context.go('/wishlist'),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 8),
            // Banner carousel using PageView
            SizedBox(
              height: 160,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _banners.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _BannerItem(data: _banners[i]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentPage == i ? 16 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == i ? AppTheme.primary : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              )),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Danh mục', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => context.go('/products'), child: const Text('Xem tất cả')),
              ]),
            ),
            SizedBox(
              height: 100,
              child: categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => const SizedBox.shrink(),
                data: (cats) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: cats.length,
                  itemBuilder: (_, i) => _CategoryChip(
                    icon: cats[i].icon, label: cats[i].name,
                    onTap: () {
                      ref.read(selectedCategoryProvider.notifier).state = cats[i].id;
                      context.go('/products');
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Sản phẩm nổi bật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () => context.go('/products'), child: const Text('Xem tất cả')),
              ]),
            ),
          ]),
        ),
        featuredAsync.when(
          loading: () => const SliverToBoxAdapter(child: LoadingShimmer()),
          error: (e, _) => SliverToBoxAdapter(child: Center(child: Text('Lỗi: $e'))),
          data: (products) => SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (_, i) => ProductCard(product: products[i]),
                childCount: products.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 0.62,
                crossAxisSpacing: 8, mainAxisSpacing: 8,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ]),
    );
  }
}

class _BannerData {
  final Color color;
  final String title, subtitle;
  final IconData icon;
  const _BannerData({required this.color, required this.title, required this.subtitle, required this.icon});
}

class _BannerItem extends StatelessWidget {
  final _BannerData data;
  const _BannerItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [data.color, data.color.withValues(alpha: 0.7)]),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(data.title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(data.subtitle, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Text('Mua ngay', style: TextStyle(color: data.color, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ])),
        Icon(data.icon, size: 72, color: Colors.white.withValues(alpha: 0.3)),
      ]),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String icon, label;
  final VoidCallback onTap;
  const _CategoryChip({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}
