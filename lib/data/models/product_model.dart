import 'dart:convert';

class ProductModel {
  final String id;
  final String name;
  final String description;
  final String category;
  final String brand;
  final double price;
  final double? salePrice;
  final int stock;
  final List<String> images;
  final Map<String, dynamic> specs;
  final double rating;
  final int reviewCount;
  final bool isFeatured;
  final DateTime createdAt;

  const ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.brand,
    required this.price,
    this.salePrice,
    required this.stock,
    this.images = const [],
    this.specs = const {},
    this.rating = 0,
    this.reviewCount = 0,
    this.isFeatured = false,
    required this.createdAt,
  });

  bool get isOnSale => salePrice != null && salePrice! < price;
  double get effectivePrice => isOnSale ? salePrice! : price;
  bool get inStock => stock > 0;
  String get mainImage => images.isNotEmpty ? images.first : '';

  ProductModel copyWith({
    String? name, String? description, double? price, double? salePrice,
    int? stock, List<String>? images, Map<String, dynamic>? specs,
    bool? isFeatured,
  }) => ProductModel(
    id: id, name: name ?? this.name, description: description ?? this.description,
    category: category, brand: brand, price: price ?? this.price,
    salePrice: salePrice ?? this.salePrice, stock: stock ?? this.stock,
    images: images ?? this.images, specs: specs ?? this.specs,
    rating: rating, reviewCount: reviewCount,
    isFeatured: isFeatured ?? this.isFeatured, createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'description': description, 'category': category,
    'brand': brand, 'price': price, 'salePrice': salePrice, 'stock': stock,
    'images': jsonEncode(images),
    'specs': jsonEncode(specs),
    'rating': rating, 'reviewCount': reviewCount, 'isFeatured': isFeatured ? 1 : 0,
    'createdAt': createdAt.toIso8601String(),
  };

  factory ProductModel.fromMap(Map<String, dynamic> m) {
    List<String> images = [];
    Map<String, dynamic> specs = {};
    try {
      final imagesRaw = m['images'];
      if (imagesRaw is String && imagesRaw.isNotEmpty) {
        if (imagesRaw.startsWith('[')) {
          images = List<String>.from(jsonDecode(imagesRaw));
        } else {
          // legacy pipe-separated
          images = imagesRaw.split('|').where((s) => s.isNotEmpty).toList();
        }
      }
    } catch (_) {}
    try {
      final specsRaw = m['specs'];
      if (specsRaw is String && specsRaw.isNotEmpty) {
        if (specsRaw.startsWith('{')) {
          specs = Map<String, dynamic>.from(jsonDecode(specsRaw));
        } else {
          // legacy colon-separated
          for (final entry in specsRaw.split('||')) {
            final idx = entry.indexOf(':');
            if (idx > 0) specs[entry.substring(0, idx)] = entry.substring(idx + 1);
          }
        }
      }
    } catch (_) {}
    return ProductModel(
      id: m['id'] as String,
      name: m['name'] as String,
      description: m['description'] as String,
      category: m['category'] as String,
      brand: m['brand'] as String,
      price: (m['price'] as num).toDouble(),
      salePrice: m['salePrice'] != null ? (m['salePrice'] as num).toDouble() : null,
      stock: m['stock'] as int,
      images: images,
      specs: specs,
      rating: (m['rating'] as num).toDouble(),
      reviewCount: m['reviewCount'] as int,
      isFeatured: (m['isFeatured'] as int) == 1,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }
}
