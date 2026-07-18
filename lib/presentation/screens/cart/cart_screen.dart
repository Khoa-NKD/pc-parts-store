import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cart_item_model.dart';
import '../../providers/cart_provider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final total = ref.watch(cartTotalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Giỏ hàng (${cart.length})'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Xóa giỏ hàng'),
                  content: const Text('Xóa tất cả sản phẩm?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                    TextButton(
                      onPressed: () { ref.read(cartProvider.notifier).clear(); Navigator.pop(context); },
                      child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ),
              child: const Text('Xóa tất cả', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Giỏ hàng trống', style: TextStyle(fontSize: 18, color: Colors.grey)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: () => context.go('/home'), child: const Text('Tiếp tục mua sắm')),
            ]))
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: cart.length,
                  itemBuilder: (_, i) => _CartTile(item: cart[i]),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))]),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Tổng cộng:', style: TextStyle(fontSize: 16)),
                    Text(CurrencyFormatter.formatVND(total),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push('/checkout'),
                      child: const Text('Tiến hành thanh toán', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ]),
              ),
            ]),
    );
  }
}

class _CartTile extends ConsumerWidget {
  final CartItemModel item;
  const _CartTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.product.mainImage.isNotEmpty
                  ? item.product.mainImage
                  : 'https://picsum.photos/seed/${item.product.id}/400/400',
              width: 72, height: 72, fit: BoxFit.cover,
              placeholder: (_, __) => Container(width: 72, height: 72, color: Colors.grey.shade100),
              errorWidget: (_, __, ___) => Container(width: 72, height: 72, color: Colors.grey.shade100,
                  child: const Icon(Icons.computer, color: Colors.grey)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.product.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(CurrencyFormatter.formatVND(item.product.effectivePrice),
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ])),
          Column(children: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => ref.read(cartProvider.notifier).removeItem(item.product.id),
            ),
            Row(children: [
              _QtyBtn(icon: Icons.remove, onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity - 1)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold))),
              _QtyBtn(icon: Icons.add, filled: true, onTap: () => ref.read(cartProvider.notifier).updateQuantity(item.product.id, item.quantity + 1)),
            ]),
          ]),
        ]),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap, this.filled = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: filled ? AppTheme.primary : null,
          border: filled ? null : Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 16, color: filled ? Colors.white : Colors.black87),
      ),
    );
  }
}
