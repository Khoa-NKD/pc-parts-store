import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../local/database_helper.dart';
import '../models/product_model.dart';
import 'mock_data.dart';

final productServiceProvider =
    Provider<ProductService>((ref) => ProductService(ref.watch(dbProvider)));

class ProductFilter {
  final String? category;
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final String sortBy;

  const ProductFilter({
    this.category,
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.sortBy = 'newest',
  });

  @override
  bool operator ==(Object other) =>
      other is ProductFilter &&
      category == other.category &&
      searchQuery == other.searchQuery &&
      minPrice == other.minPrice &&
      maxPrice == other.maxPrice &&
      sortBy == other.sortBy;

  @override
  int get hashCode =>
      Object.hash(category, searchQuery, minPrice, maxPrice, sortBy);
}

class ProductService {
  final DatabaseHelper _db;
  ProductService(this._db);

  Future<void> seedIfEmpty() async {
    final all = await _db.getProducts();
    if (all.isEmpty) {
      for (final p in MockData.products) {
        await _db.upsertProduct(p);
      }
    }
  }

  Future<List<ProductModel>> getProducts({ProductFilter? filter}) async {
    await seedIfEmpty();
    var products = await _db.getProducts(
      category: filter?.category,
      search: filter?.searchQuery,
    );
    if (filter?.minPrice != null) {
      products =
          products.where((p) => p.effectivePrice >= filter!.minPrice!).toList();
    }
    if (filter?.maxPrice != null) {
      products =
          products.where((p) => p.effectivePrice <= filter!.maxPrice!).toList();
    }
    switch (filter?.sortBy) {
      case 'price_asc':
        products.sort((a, b) => a.effectivePrice.compareTo(b.effectivePrice));
        break;
      case 'price_desc':
        products.sort((a, b) => b.effectivePrice.compareTo(a.effectivePrice));
        break;
      case 'rating':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return products;
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    await seedIfEmpty();
    return _db.getFeaturedProducts();
  }

  Future<ProductModel?> getProductById(String id) async {
    await seedIfEmpty();
    return _db.getProductById(id);
  }

  Future<void> upsertProduct(ProductModel p) => _db.upsertProduct(p);

  Future<void> deleteProduct(String id) => _db.deleteProduct(id);
}
