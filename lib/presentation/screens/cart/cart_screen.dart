import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/common/premium_card.dart';
import '../../widgets/common/premium_button.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        title: Text('Giỏ hàng', style: DesignTokens.h3.copyWith(fontSize: 20)),
        centerTitle: true,
        actions: [
          if (cart.isNotEmpty)
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: DesignTokens.danger, size: 20),
              onPressed: () => _showClearDialog(context, ref),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: cart.isEmpty
          ? _EmptyCart(onExplore: () => context.go('/home'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.length,
                    itemBuilder: (_, i) => _CartItemCard(item: cart[i]),
                  ),
                ),
                _CartSummary(total: total, onCheckout: () => context.push('/checkout')),
              ],
            ),
    );
  }

  void _showClearDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa giỏ hàng'),
        content: const Text('Bạn có chắc chắn muốn xóa tất cả sản phẩm khỏi giỏ hàng?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clear();
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: DesignTokens.danger)),
          ),
        ],
      ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  final VoidCallback onExplore;
  const _EmptyCart({required this.onExplore});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: DesignTokens.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.shoppingCart, size: 80, color: DesignTokens.border),
            ),
            const SizedBox(height: 24),
            Text('Giỏ hàng trống', style: DesignTokens.h3),
            const SizedBox(height: 8),
            Text(
              'Có vẻ như bạn chưa chọn sản phẩm nào. Hãy khám phá ngay!',
              textAlign: TextAlign.center,
              style: DesignTokens.bodySmall,
            ),
            const SizedBox(height: 32),
            PremiumButton(text: 'Tiếp tục mua sắm', onPressed: onExplore, width: 200),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends ConsumerWidget {
  final CartItemModel item;
  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PremiumCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
              child: CachedNetworkImage(
                imageUrl: item.product.mainImage.isNotEmpty
                    ? item.product.mainImage
                    : 'https://picsum.photos/seed/${item.product.id}/400/400',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(width: 80, height: 80, color: DesignTokens.background),
                errorWidget: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: DesignTokens.background,
                  child: const Icon(LucideIcons.image, color: DesignTokens.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: DesignTokens.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatVND(item.product.effectivePrice),
                    style: DesignTokens.bodyMedium.copyWith(color: DesignTokens.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _QuantityControl(
                        icon: LucideIcons.minus,
                        onTap: item.quantity > 1
                            ? () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1)
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('${item.quantity}', style: DesignTokens.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      ),
                      _QuantityControl(
                        icon: LucideIcons.plus,
                        isFilled: true,
                        onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.x, color: DesignTokens.textSecondary, size: 20),
              onPressed: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isFilled;

  const _QuantityControl({required this.icon, this.onTap, this.isFilled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isFilled ? DesignTokens.primary : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusS),
          border: isFilled ? null : Border.all(color: DesignTokens.border),
        ),
        child: Icon(icon, size: 14, color: isFilled ? Colors.white : DesignTokens.textPrimary),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final double total;
  final VoidCallback onCheckout;

  const _CartSummary({required this.total, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng thanh toán', style: DesignTokens.bodyLarge),
              Text(
                CurrencyFormatter.formatVND(total),
                style: DesignTokens.h3.copyWith(color: DesignTokens.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          PremiumButton(
            text: 'Tiến hành thanh toán',
            onPressed: onCheckout,
          ),
        ],
      ),
    );
  }
}
