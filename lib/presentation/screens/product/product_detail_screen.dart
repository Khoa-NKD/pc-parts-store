import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/local/database_helper.dart';
import '../../../data/models/review_model.dart';
import '../../../data/services/auth_service.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/common/premium_card.dart';
import '../../widgets/common/premium_button.dart';

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
          backgroundColor: DesignTokens.background,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                stretch: true,
                backgroundColor: DesignTokens.background,
                leading: IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: DesignTokens.textPrimary),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(wishlisted ? LucideIcons.heart : LucideIcons.heart,
                        color: wishlisted ? DesignTokens.danger : DesignTokens.textPrimary),
                    onPressed: () => ref.read(wishlistProvider.notifier).toggle(product.id),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Hero(
                    tag: 'product_${product.id}',
                    child: CachedNetworkImage(
                      imageUrl: product.mainImage.isNotEmpty
                          ? product.mainImage
                          : 'https://picsum.photos/seed/${product.id}/800/800',
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: DesignTokens.border),
                      errorWidget: (_, __, ___) => Container(
                        color: DesignTokens.border,
                        child: const Icon(LucideIcons.image, size: 80, color: DesignTokens.textSecondary),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: DesignTokens.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusS),
                            ),
                            child: Text(
                              product.category.toUpperCase(),
                              style: DesignTokens.bodySmall.copyWith(
                                color: DesignTokens.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Icon(LucideIcons.circle, size: 8, color: product.inStock ? DesignTokens.accent : DesignTokens.danger),
                              const SizedBox(width: 6),
                              Text(
                                product.inStock ? 'Còn ${product.stock} sản phẩm' : 'Hết hàng',
                                style: DesignTokens.bodySmall.copyWith(
                                  color: product.inStock ? DesignTokens.accent : DesignTokens.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(product.name, style: DesignTokens.h3),
                      const SizedBox(height: 4),
                      Text(product.brand, style: DesignTokens.bodyMedium.copyWith(color: DesignTokens.textSecondary)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: product.rating,
                            itemSize: 18,
                            itemBuilder: (_, __) => const Icon(Icons.star, color: DesignTokens.warning),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${product.rating.toStringAsFixed(1)} (${product.reviewCount} đánh giá)',
                            style: DesignTokens.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (product.isOnSale) ...[
                            Text(
                              CurrencyFormatter.formatVND(product.salePrice!),
                              style: DesignTokens.h2.copyWith(color: DesignTokens.danger, fontSize: 32),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                CurrencyFormatter.formatVND(product.price),
                                style: DesignTokens.bodyMedium.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: DesignTokens.textSecondary,
                                ),
                              ),
                            ),
                          ] else
                            Text(
                              CurrencyFormatter.formatVND(product.price),
                              style: DesignTokens.h2.copyWith(color: DesignTokens.primary, fontSize: 32),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      const Text('Thông số kỹ thuật', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      PremiumCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: product.specs.entries.map((e) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(e.key, style: DesignTokens.bodySmall)),
                                Expanded(flex: 3, child: Text('${e.value}', style: DesignTokens.bodySmall.copyWith(fontWeight: FontWeight.bold, color: DesignTokens.textPrimary))),
                              ],
                            ),
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text('Mô tả sản phẩm', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        product.description,
                        style: DesignTokens.bodyMedium.copyWith(height: 1.6, color: DesignTokens.textSecondary),
                      ),
                      const SizedBox(height: 32),
                      _ReviewSection(productId: product.id),
                      const SizedBox(height: 32),
                      Consumer(builder: (_, ref, __) {
                        final rec = ref.watch(recommendedProductsProvider(product));
                        return rec.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (list) => list.isEmpty ? const SizedBox.shrink() : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Sản phẩm liên quan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 280,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: list.length,
                                  itemBuilder: (_, i) => SizedBox(
                                    width: 180,
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 16),
                                      child: ProductCard(product: list[i]),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomSheet: product.inStock ? Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: DesignTokens.background,
                    borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
                    border: Border.all(color: DesignTokens.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.minus, size: 18),
                        onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                      ),
                      Text('$_qty', style: DesignTokens.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                      IconButton(
                        icon: const Icon(LucideIcons.plus, size: 18),
                        onPressed: _qty < product.stock ? () => setState(() => _qty++) : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: PremiumButton(
                    text: 'Thêm vào giỏ',
                    onPressed: () async {
                      try {
                        await ref.read(cartProvider.notifier).addItem(product, quantity: _qty);
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(duration: const Duration(seconds: 1), 
                            content: Text('Đã thêm $_qty ${product.name} vào giỏ'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: DesignTokens.primary,
                          ),
                        );
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(duration: const Duration(seconds: 1), content: Text('$e'), backgroundColor: DesignTokens.danger));
                      }
                    },
                  ),
                ),
              ],
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Đánh giá', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextButton.icon(
              onPressed: () => setState(() => _showForm = !_showForm),
              icon: Icon(_showForm ? LucideIcons.x : LucideIcons.plus, size: 16),
              label: Text(_showForm ? 'Hủy' : 'Viết đánh giá'),
            ),
          ],
        ),
        if (_showForm) ...[
          PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RatingBar.builder(
                  initialRating: _rating,
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: true,
                  itemCount: 5,
                  itemSize: 32,
                  itemBuilder: (_, __) => const Icon(Icons.star, color: DesignTokens.warning),
                  onRatingUpdate: (r) => setState(() => _rating = r),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Nhận xét của bạn về sản phẩm...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM)),
                  ),
                ),
                const SizedBox(height: 16),
                PremiumButton(text: 'Gửi đánh giá', onPressed: _submit),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (_reviews.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Chưa có đánh giá nào cho sản phẩm này', style: DesignTokens.bodySmall),
            ),
          )
        else
          ..._reviews.take(5).map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PremiumCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: DesignTokens.primary.withValues(alpha: 0.1),
                        child: Text(r.userName[0].toUpperCase(), style: const TextStyle(color: DesignTokens.primary, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.userName, style: DesignTokens.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                            RatingBarIndicator(
                              rating: r.rating,
                              itemSize: 12,
                              itemBuilder: (_, __) => const Icon(Icons.star, color: DesignTokens.warning),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${r.createdAt.day}/${r.createdAt.month}/${r.createdAt.year}',
                        style: DesignTokens.bodySmall.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(r.comment, style: DesignTokens.bodySmall.copyWith(color: DesignTokens.textPrimary)),
                ],
              ),
            ),
          )),
      ],
    );
  }
}
