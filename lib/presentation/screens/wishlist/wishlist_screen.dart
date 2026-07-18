import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/product_service.dart';
import '../../providers/wishlist_provider.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(wishlistProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Yêu thích (${ids.length})')),
      body: ids.isEmpty
          ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.favorite_border, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('Chưa có sản phẩm yêu thích', style: TextStyle(color: Colors.grey, fontSize: 16)),
            ]))
          : _WishlistGrid(ids: ids),
    );
  }
}

class _WishlistGrid extends ConsumerWidget {
  final List<String> ids;
  const _WishlistGrid({required this.ids});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Load all wishlist products at once using existing provider
    final allAsync = ref.watch(productsProvider(const ProductFilter()));

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Lỗi: $e')),
      data: (allProducts) {
        final wishlistProducts = allProducts.where((p) => ids.contains(p.id)).toList();
        if (wishlistProducts.isEmpty) {
          return const Center(child: Text('Không tìm thấy sản phẩm'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, childAspectRatio: 0.62,
            crossAxisSpacing: 8, mainAxisSpacing: 8,
          ),
          itemCount: wishlistProducts.length,
          itemBuilder: (_, i) => ProductCard(product: wishlistProducts[i]),
        );
      },
    );
  }
}
