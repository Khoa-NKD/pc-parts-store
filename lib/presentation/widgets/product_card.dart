import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_model.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'common/premium_card.dart';

class ProductCard extends ConsumerWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlisted = ref.watch(wishlistProvider).contains(product.id);

    return PremiumCard(
      padding: EdgeInsets.zero,
      onTap: () => context.push('/product/${product.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(DesignTokens.borderRadiusL)),
                  child: Hero(
                    tag: 'product_${product.id}',
                    child: CachedNetworkImage(
                      imageUrl: product.mainImage.isNotEmpty
                          ? product.mainImage
                          : 'https://picsum.photos/seed/${product.id}/400/400',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: DesignTokens.background,
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: DesignTokens.background,
                        child: const Icon(LucideIcons.image,
                            size: 48, color: DesignTokens.textSecondary),
                      ),
                    ),
                  ),
                ),
                if (product.isOnSale)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DesignTokens.danger,
                        borderRadius:
                            BorderRadius.circular(DesignTokens.borderRadiusS),
                      ),
                      child: Text(
                        '-${((1 - product.salePrice! / product.price) * 100).round()}%',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () =>
                        ref.read(wishlistProvider.notifier).toggle(product.id),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                          color: Colors.white, shape: BoxShape.circle),
                      child: Icon(
                        wishlisted ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: wishlisted
                            ? DesignTokens.danger
                            : DesignTokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.brand.toUpperCase(),
                  style: DesignTokens.bodySmall.copyWith(
                    fontSize: 10,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                    color: DesignTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: DesignTokens.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600, height: 1.2),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      if (product.isOnSale) ...[
                        Text(
                          CurrencyFormatter.formatVND(product.salePrice!),
                          style: DesignTokens.bodyMedium.copyWith(
                            color: DesignTokens.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          CurrencyFormatter.formatVND(product.price),
                          style: DesignTokens.bodySmall.copyWith(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ] else
                        Text(
                          CurrencyFormatter.formatVND(product.price),
                          style: DesignTokens.bodyMedium.copyWith(
                            color: DesignTokens.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: product.inStock
                        ? () {
                            ref.read(cartProvider.notifier).addItem(product);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                duration: const Duration(seconds: 1),
                                content:
                                    Text('Đã thêm ${product.name} vào giỏ'),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                backgroundColor: DesignTokens.primary,
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: product.inStock
                          ? DesignTokens.primary
                          : DesignTokens.border,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              DesignTokens.borderRadiusM)),
                    ),
                    child: Text(
                      product.inStock ? 'Thêm vào giỏ' : 'Hết hàng',
                      style: DesignTokens.bodySmall.copyWith(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
