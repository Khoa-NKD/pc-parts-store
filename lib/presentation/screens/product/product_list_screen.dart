import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
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
      appBar: AppBar(
        title: const Text('Sản phẩm'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [
                _CatChip(
                  label: 'Tất cả',
                  selected: selectedCat == null,
                  onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                ),
                ...AppConstants.categories.map((c) => _CatChip(
                      label: c['name']!,
                      selected: selectedCat == c['id'],
                      onTap: () =>
                          ref.read(selectedCategoryProvider.notifier).state = c['id'],
                    )),
              ],
            ),
          ),
        ),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchCtrl.clear()))
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              _SortChip(label: 'Mới nhất', value: 'newest', selected: _sortBy, onTap: (v) => setState(() => _sortBy = v)),
              _SortChip(label: 'Giá tăng', value: 'price_asc', selected: _sortBy, onTap: (v) => setState(() => _sortBy = v)),
              _SortChip(label: 'Giá giảm', value: 'price_desc', selected: _sortBy, onTap: (v) => setState(() => _sortBy = v)),
              _SortChip(label: 'Đánh giá', value: 'rating', selected: _sortBy, onTap: (v) => setState(() => _sortBy = v)),
            ],
          ),
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const LoadingShimmer(),
            error: (e, _) => Center(child: Text('Lỗi: $e')),
            data: (products) => products.isEmpty
                ? const Center(child: Text('Không tìm thấy sản phẩm'))
                : RefreshIndicator(
                    onRefresh: () async => ref.invalidate(productsProvider(ProductFilter(
                      category: selectedCat,
                      searchQuery: _searchCtrl.text,
                      sortBy: _sortBy,
                    ))),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: products.length,
                      itemBuilder: (_, i) => ProductCard(product: products[i]),
                    ),
                  ),
          ),
        ),
      ]),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _CatChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label, value, selected;
  final ValueChanged<String> onTap;
  const _SortChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sel = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: sel ? Theme.of(context).colorScheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: sel
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : Colors.black87, fontSize: 13)),
      ),
    );
  }
}
