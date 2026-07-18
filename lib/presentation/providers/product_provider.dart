import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_model.dart';
import '../../data/services/product_service.dart';

final productFilterProvider =
    StateProvider<ProductFilter>((ref) => const ProductFilter());

final productsProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, ProductFilter>((ref, filter) {
  return ref.watch(productServiceProvider).getProducts(filter: filter);
});

final featuredProductsProvider = FutureProvider.autoDispose<List<ProductModel>>((ref) {
  return ref.watch(productServiceProvider).getFeaturedProducts();
});

final productDetailProvider =
    FutureProvider.autoDispose.family<ProductModel?, String>((ref, id) {
  return ref.watch(productServiceProvider).getProductById(id);
});

final recommendedProductsProvider =
    FutureProvider.family<List<ProductModel>, ProductModel>((ref, product) async {
  final all = await ref
      .watch(productServiceProvider)
      .getProducts(filter: ProductFilter(category: product.category));
  return all.where((p) => p.id != product.id).take(6).toList();
});
