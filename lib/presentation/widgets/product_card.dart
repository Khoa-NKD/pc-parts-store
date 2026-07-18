import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlisted = ref.watch(wishlistProvider).contains(product.id);

    return GestureDetector(
      onTap: () => context.push('/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Stack(children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: CachedNetworkImage(
                imageUrl: product.mainImage.isNotEmpty
                    ? product.mainImage
                    : 'https://picsum.photos/seed/${product.id}/400/400',
                height: 140, width: double.infinity, fit: BoxFit.cover,
                placeholder: (_, __) => Container(height: 140, color: Colors.grey.shade100,
                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (_, __, ___) => Container(height: 140, color: Colors.grey.shade100,
                    child: const Icon(Icons.computer, size: 48, color: Colors.grey)),
              ),
            ),
            if (product.isOnSale)
              Positioned(top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '-${((1 - product.salePrice! / product.price) * 100).round()}%',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            Positioned(top: 4, right: 4,
              child: GestureDetector(
                onTap: () => ref.read(wishlistProvider.notifier).toggle(product.id),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)]),
                  child: Icon(wishlisted ? Icons.favorite : Icons.favorite_border,
                      size: 18, color: wishlisted ? Colors.red : Colors.grey),
                ),
              ),
            ),
          ]),
          Expanded(
            child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.brand, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              if (product.isOnSale) ...[
                Text(CurrencyFormatter.formatVND(product.price),
                    style: const TextStyle(fontSize: 11, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                Text(CurrencyFormatter.formatVND(product.salePrice!),
                    style: const TextStyle(fontSize: 15, color: Colors.red, fontWeight: FontWeight.bold)),
              ] else
                Text(CurrencyFormatter.formatVND(product.price),
                    style: const TextStyle(fontSize: 15, color: AppTheme.primary, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity, height: 32,
                child: ElevatedButton.icon(
                  onPressed: product.inStock ? () {
                    ref.read(cartProvider.notifier).addItem(product);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Đã thêm ${product.name}'), duration: const Duration(seconds: 1)),
                    );
                  } : null,
                  icon: const Icon(Icons.add_shopping_cart, size: 14),
                  label: Text(product.inStock ? 'Thêm vào giỏ' : 'Hết hàng', style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: product.inStock ? AppTheme.primary : Colors.grey,
                  ),
                ),
              ),
            ]),
          ),
          ),
        ]),
      ),
    );
  }
}
