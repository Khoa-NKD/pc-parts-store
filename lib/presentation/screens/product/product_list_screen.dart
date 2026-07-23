import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/design_tokens.dart';
import '../../../data/services/product_service.dart';
import '../../providers/product_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/loading_shimmer.dart';

// Provider lưu category đang chọn trong tab sản phẩm
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final _searchCtrl = TextEditingController();
  String _sortBy = 'newest';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCat = ref.watch(selectedCategoryProvider);
    final productsAsync = ref.watch(productsProvider(ProductFilter(
      category: selectedCat,
      searchQuery: _searchCtrl.text,
      sortBy: _sortBy,
    )));

    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        title: const Text('Tất cả sản phẩm'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm...',
                prefixIcon: const Icon(LucideIcons.search, size: 20),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
                  borderSide: const BorderSide(color: DesignTokens.border),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(icon: const Icon(LucideIcons.x, size: 18), onPressed: () => setState(() => _searchCtrl.clear()))
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _FilterChip(
                  label: 'Tất cả',
                  selected: selectedCat == null,
                  onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                ),
                ...AppConstants.categories.map((c) => _FilterChip(
                      label: c['name']!,
                      selected: selectedCat == c['id'],
                      onTap: () => ref.read(selectedCategoryProvider.notifier).state = c['id'],
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _SortItem(label: 'Mới nhất', value: 'newest', selected: _sortBy, onTap: (v) => setState(() => _sortBy = v)),
                _SortItem(label: 'Giá tăng', value: 'price_asc', selected: _sortBy, onTap: (v) => setState(() => _sortBy = v)),
                _SortItem(label: 'Giá giảm', value: 'price_desc', selected: _sortBy, onTap: (v) => setState(() => _sortBy = v)),
                _SortItem(label: 'Đánh giá', value: 'rating', selected: _sortBy, onTap: (v) => setState(() => _sortBy = v)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: productsAsync.when(
              loading: () => const LoadingShimmer(),
              error: (e, _) => Center(child: Text('Lỗi: $e')),
              data: (products) => products.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.box, size: 64, color: DesignTokens.border),
                          const SizedBox(height: 16),
                          Text('Không tìm thấy sản phẩm', style: DesignTokens.bodyLarge),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () async => ref.invalidate(productsProvider(ProductFilter(
                        category: selectedCat,
                        searchQuery: _searchCtrl.text,
                        sortBy: _sortBy,
                      ))),
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.65,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: products.length,
                        itemBuilder: (_, i) => ProductCard(product: products[i]),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? DesignTokens.primary : Colors.white,
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
          border: Border.all(color: selected ? DesignTokens.primary : DesignTokens.border),
          boxShadow: selected ? DesignTokens.shadowSm : null,
        ),
        child: Text(
          label,
          style: DesignTokens.bodySmall.copyWith(
            color: selected ? Colors.white : DesignTokens.textPrimary,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SortItem extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _SortItem({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Text(
              label,
              style: DesignTokens.bodySmall.copyWith(
                color: sel ? DesignTokens.primary : DesignTokens.textSecondary,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: sel ? 20 : 0,
              decoration: BoxDecoration(
                color: DesignTokens.primary,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
