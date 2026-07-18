import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/models/review_model.dart';
import '../../../data/services/auth_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productDetailProvider(widget.productId));
    final wishlisted = ref.watch(wishlistProvider).contains(widget.productId);

    return productAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Lỗi: $e'))),
      data: (product) {
        if (product == null) return const Scaffold(body: Center(child: Text('Không tìm thấy')));
        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              actions: [
                IconButton(
                  icon: Icon(wishlisted ? Icons.favorite : Icons.favorite_border,
                      color: wishlisted ? Colors.red : null),
                  onPressed: () => ref.read(wishlistProvider.notifier).toggle(product.id),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: CachedNetworkImage(
                  imageUrl: product.mainImage.isNotEmpty
                      ? product.mainImage
                      : 'https://picsum.photos/seed/${product.id}/400/400',
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(color: Colors.grey.shade100),
                  errorWidget: (_, __, ___) => Container(color: Colors.grey.shade100,
                      child: const Icon(Icons.computer, size: 80, color: Colors.grey)),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Info card
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                        child: Text(product.category.toUpperCase(),
                            style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      Icon(Icons.circle, size: 8, color: product.inStock ? Colors.green : Colors.red),
                      const SizedBox(width: 4),
                      Text(product.inStock ? 'Còn ${product.stock}' : 'Hết hàng',
                          style: TextStyle(fontSize: 12, color: product.inStock ? Colors.green : Colors.red)),
                    ]),
                    const SizedBox(height: 8),
                    Text(product.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(product.brand, style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Row(children: [
                      RatingBarIndicator(rating: product.rating, itemSize: 16,
                          itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
                      const SizedBox(width: 6),
                      Text('${product.rating.toStringAsFixed(1)} (${product.reviewCount})',
                          style: const TextStyle(fontSize: 13, color: Colors.grey)),
                    ]),
                    const SizedBox(height: 12),
                    if (product.isOnSale) ...[
                      Text(CurrencyFormatter.formatVND(product.price),
                          style: const TextStyle(fontSize: 14, color: Colors.grey, decoration: TextDecoration.lineThrough)),
                      Text(CurrencyFormatter.formatVND(product.salePrice!),
                          style: const TextStyle(fontSize: 26, color: Colors.red, fontWeight: FontWeight.bold)),
                    ] else
                      Text(CurrencyFormatter.formatVND(product.price),
                          style: const TextStyle(fontSize: 26, color: AppTheme.primary, fontWeight: FontWeight.bold)),
                  ]),
                ),
                // Specs
                if (product.specs.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Thông số kỹ thuật', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      ...product.specs.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(children: [
                          Expanded(flex: 2, child: Text(e.key, style: const TextStyle(color: Colors.grey))),
                          Expanded(flex: 3, child: Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.w500))),
                        ]),
                      )),
                    ]),
                  ),
                // Description
                Container(
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(product.description, style: const TextStyle(height: 1.6)),
                  ]),
                ),
                // Reviews
                _ReviewSection(productId: product.id),
                // Recommended
                Consumer(builder: (_, ref, __) {
                  final rec = ref.watch(recommendedProductsProvider(product));
                  return rec.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (list) => list.isEmpty ? const SizedBox.shrink() : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Text('Sản phẩm liên quan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                        SizedBox(
                          height: 260,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: list.length,
                            itemBuilder: (_, i) => SizedBox(width: 160,
                                child: Padding(padding: const EdgeInsets.only(right: 8), child: ProductCard(product: list[i]))),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 100),
              ]),
            ),
          ]),
          bottomNavigationBar: product.inStock ? Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, -2))]),
            child: Row(children: [
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  IconButton(icon: const Icon(Icons.remove, size: 18), onPressed: _qty > 1 ? () => setState(() => _qty--) : null),
                  Text('$_qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.add, size: 18), onPressed: _qty < product.stock ? () => setState(() => _qty++) : null),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(cartProvider.notifier).addItem(product, quantity: _qty);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm vào giỏ hàng')));
                    } catch (e) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('Thêm vào giỏ', style: TextStyle(fontSize: 15)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await ref.read(cartProvider.notifier).addItem(product, quantity: _qty);
                    if (context.mounted) context.push('/checkout');
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e'), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                child: const Text('Mua ngay'),
              ),
            ]),
          ) : null,
        );
      },
    );
  }
}

class _ReviewSection extends ConsumerStatefulWidget {
  final String productId;
  const _ReviewSection({required this.productId});
  @override
  ConsumerState<_ReviewSection> createState() => _ReviewSectionState();
}

class _ReviewSectionState extends ConsumerState<_ReviewSection> {
  bool _showForm = false;
  double _rating = 5;
  final _commentCtrl = TextEditingController();
  List<ReviewModel> _reviews = [];

  @override
  void initState() { super.initState(); _loadReviews(); }

  Future<void> _loadReviews() async {
    final db = ref.read(dbProvider);
    final reviews = await db.getProductReviews(widget.productId);
    if (mounted) setState(() => _reviews = reviews);
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final db = ref.read(dbProvider);
    await db.insertReview(ReviewModel(
      id: const Uuid().v4(), productId: widget.productId,
      userId: user.id, userName: user.name,
      rating: _rating, comment: _commentCtrl.text,
      createdAt: DateTime.now(),
    ));
    _commentCtrl.clear();
    setState(() => _showForm = false);
    await _loadReviews();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Đánh giá', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(onPressed: () => setState(() => _showForm = !_showForm),
              child: Text(_showForm ? 'Hủy' : 'Viết đánh giá')),
        ]),
        if (_showForm) ...[
          RatingBar.builder(
            initialRating: _rating, itemSize: 32,
            itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (r) => setState(() => _rating = r),
          ),
          const SizedBox(height: 8),
          TextField(controller: _commentCtrl, maxLines: 3,
              decoration: const InputDecoration(hintText: 'Nhận xét...', isDense: true)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: _submit, child: const Text('Gửi')),
          const Divider(height: 24),
        ],
        if (_reviews.isEmpty)
          const Text('Chưa có đánh giá', style: TextStyle(color: Colors.grey))
        else
          ..._reviews.take(5).map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                CircleAvatar(radius: 16, child: Text(r.userName[0].toUpperCase())),
                const SizedBox(width: 8),
                Expanded(child: Text(r.userName, style: const TextStyle(fontWeight: FontWeight.w600))),
                RatingBarIndicator(rating: r.rating, itemSize: 14,
                    itemBuilder: (_, __) => const Icon(Icons.star, color: Colors.amber)),
              ]),
              const SizedBox(height: 4),
              Text(r.comment),
              const Divider(),
            ]),
          )),
      ]),
    );
  }
}
