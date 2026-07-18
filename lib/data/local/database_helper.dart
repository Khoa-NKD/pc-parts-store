import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../models/review_model.dart';
import '../models/cart_item_model.dart';
import '../models/category_model.dart';

final dbProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper());

class DatabaseHelper {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'pc_parts.db');
    return openDatabase(path, version: 5, onCreate: _onCreate, onUpgrade: (db, oldV, newV) async {
      await db.execute('DROP TABLE IF EXISTS products');
      await db.execute('DROP TABLE IF EXISTS users');
      await db.execute('DROP TABLE IF EXISTS cart');
      await db.execute('DROP TABLE IF EXISTS orders');
      await db.execute('DROP TABLE IF EXISTS reviews');
      await db.execute('DROP TABLE IF EXISTS categories');
      await _onCreate(db, newV);
    });
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY, email TEXT, name TEXT, role TEXT,
        phone TEXT, address TEXT, wishlist TEXT, password TEXT,
        isLocked INTEGER DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY, name TEXT, description TEXT, category TEXT,
        brand TEXT, price REAL, salePrice REAL, stock INTEGER,
        images TEXT, specs TEXT, rating REAL, reviewCount INTEGER,
        isFeatured INTEGER, createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        productId TEXT UNIQUE, productJson TEXT, quantity INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY, userId TEXT, userName TEXT,
        shippingAddress TEXT, phone TEXT, itemsJson TEXT,
        totalAmount REAL, status TEXT, paymentMethod TEXT, createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY, productId TEXT, userId TEXT,
        userName TEXT, rating REAL, comment TEXT, createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY, name TEXT, icon TEXT, sortOrder INTEGER
      )
    ''');
    // Seed default categories
    final cats = [
      {'id': 'cpu',         'name': 'CPU',      'icon': '🖥️', 'sortOrder': 0},
      {'id': 'gpu',         'name': 'GPU',      'icon': '🎮', 'sortOrder': 1},
      {'id': 'ram',         'name': 'RAM',      'icon': '💾', 'sortOrder': 2},
      {'id': 'ssd',         'name': 'SSD',      'icon': '💿', 'sortOrder': 3},
      {'id': 'motherboard', 'name': 'Mainboard','icon': '🔧', 'sortOrder': 4},
      {'id': 'psu',         'name': 'PSU',      'icon': '⚡', 'sortOrder': 5},
      {'id': 'case',        'name': 'Case',     'icon': '📦', 'sortOrder': 6},
      {'id': 'cooling',     'name': 'Cooling',  'icon': '❄️', 'sortOrder': 7},
    ];
    for (final c in cats) {
      await db.insert('categories', c, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed demo products
    final products = [
      {'id': 'cpu-001', 'name': 'Intel Core i9-14900K', 'description': 'Bộ vi xử lý Intel thế hệ 14, 24 nhân 32 luồng, xung nhịp tối đa 6.0GHz.', 'category': 'cpu', 'brand': 'Intel', 'price': 12990000.0, 'salePrice': 11490000.0, 'stock': 15, 'images': '["https://picsum.photos/seed/cpu1/400/400"]', 'specs': '{"Cores":"24","Threads":"32","Boost":"6.0 GHz","Socket":"LGA1700"}', 'rating': 4.8, 'reviewCount': 124, 'isFeatured': 1, 'createdAt': '2024-01-01T00:00:00.000'},
      {'id': 'cpu-002', 'name': 'AMD Ryzen 9 7950X', 'description': 'AMD Ryzen 9 7950X kiến trúc Zen 4, 16 nhân 32 luồng.', 'category': 'cpu', 'brand': 'AMD', 'price': 14500000.0, 'salePrice': null, 'stock': 8, 'images': '["https://picsum.photos/seed/cpu2/400/400"]', 'specs': '{"Cores":"16","Threads":"32","Boost":"5.7 GHz","Socket":"AM5"}', 'rating': 4.9, 'reviewCount': 89, 'isFeatured': 1, 'createdAt': '2024-01-02T00:00:00.000'},
      {'id': 'gpu-001', 'name': 'NVIDIA RTX 4090 24GB', 'description': 'Card đồ họa mạnh nhất NVIDIA, 24GB GDDR6X, DLSS 3.', 'category': 'gpu', 'brand': 'NVIDIA', 'price': 45000000.0, 'salePrice': 42000000.0, 'stock': 5, 'images': '["https://picsum.photos/seed/gpu1/400/400"]', 'specs': '{"VRAM":"24GB GDDR6X","CUDA":"16384","TDP":"450W"}', 'rating': 4.9, 'reviewCount': 56, 'isFeatured': 1, 'createdAt': '2024-01-03T00:00:00.000'},
      {'id': 'gpu-002', 'name': 'AMD RX 7900 XTX 24GB', 'description': 'Flagship GPU AMD với 24GB GDDR6, gaming 4K xuất sắc.', 'category': 'gpu', 'brand': 'AMD', 'price': 28000000.0, 'salePrice': null, 'stock': 10, 'images': '["https://picsum.photos/seed/gpu2/400/400"]', 'specs': '{"VRAM":"24GB GDDR6","SP":"12288","TDP":"355W"}', 'rating': 4.7, 'reviewCount': 43, 'isFeatured': 0, 'createdAt': '2024-01-04T00:00:00.000'},
      {'id': 'ram-001', 'name': 'Corsair Vengeance DDR5 32GB', 'description': 'RAM DDR5 6000MHz, kit 2x16GB, tản nhiệt nhôm cao cấp.', 'category': 'ram', 'brand': 'Corsair', 'price': 3200000.0, 'salePrice': 2800000.0, 'stock': 30, 'images': '["https://picsum.photos/seed/ram1/400/400"]', 'specs': '{"Capacity":"32GB (2x16)","Speed":"DDR5-6000","CL":"36"}', 'rating': 4.6, 'reviewCount': 201, 'isFeatured': 1, 'createdAt': '2024-01-05T00:00:00.000'},
      {'id': 'ram-002', 'name': 'Kingston Fury Beast DDR4 16GB', 'description': 'RAM DDR4 3200MHz, 16GB, hiệu năng tốt cho tầm trung.', 'category': 'ram', 'brand': 'Kingston', 'price': 1200000.0, 'salePrice': null, 'stock': 50, 'images': '["https://picsum.photos/seed/ram2/400/400"]', 'specs': '{"Capacity":"16GB","Speed":"DDR4-3200","CL":"16"}', 'rating': 4.5, 'reviewCount': 310, 'isFeatured': 0, 'createdAt': '2024-01-06T00:00:00.000'},
      {'id': 'ssd-001', 'name': 'Samsung 990 Pro 2TB NVMe', 'description': 'SSD NVMe PCIe 4.0, đọc 7450MB/s, lý tưởng cho gaming.', 'category': 'ssd', 'brand': 'Samsung', 'price': 4500000.0, 'salePrice': null, 'stock': 25, 'images': '["https://picsum.photos/seed/ssd1/400/400"]', 'specs': '{"Capacity":"2TB","Interface":"PCIe 4.0","Read":"7450 MB/s"}', 'rating': 4.8, 'reviewCount': 312, 'isFeatured': 1, 'createdAt': '2024-01-07T00:00:00.000'},
      {'id': 'ssd-002', 'name': 'WD Black SN850X 1TB', 'description': 'SSD NVMe PCIe 4.0 của WD, đọc 7300MB/s.', 'category': 'ssd', 'brand': 'WD', 'price': 2800000.0, 'salePrice': 2500000.0, 'stock': 18, 'images': '["https://picsum.photos/seed/ssd2/400/400"]', 'specs': '{"Capacity":"1TB","Interface":"PCIe 4.0","Read":"7300 MB/s"}', 'rating': 4.7, 'reviewCount': 178, 'isFeatured': 0, 'createdAt': '2024-01-08T00:00:00.000'},
      {'id': 'mb-001', 'name': 'ASUS ROG Maximus Z790 Hero', 'description': 'Mainboard cao cấp Intel Gen 13/14, DDR5, PCIe 5.0.', 'category': 'motherboard', 'brand': 'ASUS', 'price': 18500000.0, 'salePrice': null, 'stock': 7, 'images': '["https://picsum.photos/seed/mb1/400/400"]', 'specs': '{"Socket":"LGA1700","Chipset":"Z790","Memory":"DDR5"}', 'rating': 4.7, 'reviewCount': 67, 'isFeatured': 0, 'createdAt': '2024-01-09T00:00:00.000'},
      {'id': 'psu-001', 'name': 'Seasonic Prime TX-1000W', 'description': 'Nguồn 1000W 80+ Titanium, full modular, bảo hành 12 năm.', 'category': 'psu', 'brand': 'Seasonic', 'price': 6800000.0, 'salePrice': null, 'stock': 12, 'images': '["https://picsum.photos/seed/psu1/400/400"]', 'specs': '{"Wattage":"1000W","Efficiency":"80+ Titanium","Modular":"Full"}', 'rating': 4.9, 'reviewCount': 88, 'isFeatured': 0, 'createdAt': '2024-01-10T00:00:00.000'},
    ];
    for (final p in products) {
      await db.insert('products', p, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // Seed demo users
    await db.insert('users', {
      'id': 'demo-user-001', 'email': 'demo@test.com', 'name': 'Demo User',
      'role': 'user', 'phone': '', 'address': '', 'wishlist': '', 'password': '123456',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    await db.insert('users', {
      'id': 'admin-user-001', 'email': 'admin@test.com', 'name': 'Admin',
      'role': 'admin', 'phone': '', 'address': '', 'wishlist': '', 'password': '123456',
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  // ── Users ──────────────────────────────────────────────────────────────────

  Future<UserModel?> getUserByEmail(String email) async {
    final d = await db;
    final rows = await d.query('users', where: 'email = ?', whereArgs: [email]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getUserById(String id) async {
    final d = await db;
    final rows = await d.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<bool> checkPassword(String email, String password) async {
    final d = await db;
    final rows = await d.query('users',
        where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return rows.isNotEmpty;
  }

  Future<void> insertUser(UserModel user, String password) async {
    final d = await db;
    await d.insert('users', {...user.toMap(), 'password': password},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUser(UserModel user) async {
    final d = await db;
    await d.update('users', user.toMap(),
        where: 'id = ?', whereArgs: [user.id]);
  }

  Future<void> updatePassword(String email, String newPassword) async {
    final d = await db;
    await d.update('users', {'password': newPassword},
        where: 'email = ?', whereArgs: [email]);
  }

  // ── Products ───────────────────────────────────────────────────────────────

  Future<List<ProductModel>> getProducts({String? category, String? search}) async {
    final d = await db;
    String? where;
    List<Object?>? args;
    if (category != null) {
      where = 'category = ?';
      args = [category];
    }
    final rows = await d.query('products',
        where: where, whereArgs: args, orderBy: 'createdAt DESC');
    var products = rows.map(ProductModel.fromMap).toList();
    if (search != null && search.isNotEmpty) {
      final q = search.toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.brand.toLowerCase().contains(q))
          .toList();
    }
    return products;
  }

  Future<List<ProductModel>> getFeaturedProducts() async {
    final d = await db;
    final rows = await d.query('products',
        where: 'isFeatured = 1', orderBy: 'rating DESC', limit: 10);
    return rows.map(ProductModel.fromMap).toList();
  }

  Future<ProductModel?> getProductById(String id) async {
    final d = await db;
    final rows =
        await d.query('products', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first);
  }

  Future<void> upsertProduct(ProductModel p) async {
    final d = await db;
    await d.insert('products', p.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteProduct(String id) async {
    final d = await db;
    await d.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ── Cart ───────────────────────────────────────────────────────────────────

  Future<List<CartItemModel>> getCartItems() async {
    final d = await db;
    final rows = await d.query('cart');
    return rows.map((r) {
      final product = ProductModel.fromMap(
          jsonDecode(r['productJson'] as String) as Map<String, dynamic>);
      return CartItemModel(product: product, quantity: r['quantity'] as int);
    }).toList();
  }

  Future<void> upsertCartItem(CartItemModel item) async {
    final d = await db;
    final existing = await d.query('cart',
        where: 'productId = ?', whereArgs: [item.product.id]);
    if (existing.isNotEmpty) {
      await d.update(
          'cart', {'quantity': item.quantity},
          where: 'productId = ?', whereArgs: [item.product.id]);
    } else {
      await d.insert('cart', {
        'productId': item.product.id,
        'productJson': jsonEncode(item.product.toMap()),
        'quantity': item.quantity,
      });
    }
  }

  Future<void> removeCartItem(String productId) async {
    final d = await db;
    await d.delete('cart', where: 'productId = ?', whereArgs: [productId]);
  }

  Future<void> clearCart() async {
    final d = await db;
    await d.delete('cart');
  }

  // ── Orders ─────────────────────────────────────────────────────────────────

  Future<void> insertOrder(OrderModel order) async {
    final d = await db;
    await d.insert('orders', {
      'id': order.id,
      'userId': order.userId,
      'userName': order.userName,
      'shippingAddress': order.shippingAddress,
      'phone': order.phone,
      'itemsJson': jsonEncode(order.items.map((i) => i.toMap()).toList()),
      'totalAmount': order.totalAmount,
      'status': order.status,
      'paymentMethod': order.paymentMethod,
      'createdAt': order.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<OrderModel>> getUserOrders(String userId) async {
    final d = await db;
    final rows = await d.query('orders',
        where: 'userId = ?', whereArgs: [userId], orderBy: 'createdAt DESC');
    return rows.map(_orderFromMap).toList();
  }

  Future<List<OrderModel>> getAllOrders() async {
    final d = await db;
    final rows = await d.query('orders', orderBy: 'createdAt DESC');
    return rows.map(_orderFromMap).toList();
  }

  Future<void> updateOrderStatus(String id, String status) async {
    final d = await db;
    await d.update('orders', {'status': status},
        where: 'id = ?', whereArgs: [id]);
  }

  OrderModel _orderFromMap(Map<String, dynamic> m) {
    final items = (jsonDecode(m['itemsJson'] as String) as List)
        .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
        .toList();
    return OrderModel(
      id: m['id'] as String,
      userId: m['userId'] as String,
      userName: m['userName'] as String,
      shippingAddress: m['shippingAddress'] as String,
      phone: m['phone'] as String,
      items: items,
      totalAmount: (m['totalAmount'] as num).toDouble(),
      status: m['status'] as String,
      paymentMethod: m['paymentMethod'] as String,
      createdAt: DateTime.parse(m['createdAt'] as String),
    );
  }

  // ── Reviews ────────────────────────────────────────────────────────────────

  Future<List<ReviewModel>> getProductReviews(String productId) async {
    final d = await db;
    final rows = await d.query('reviews',
        where: 'productId = ?', whereArgs: [productId],
        orderBy: 'createdAt DESC');
    return rows.map((r) => ReviewModel(
      id: r['id'] as String,
      productId: r['productId'] as String,
      userId: r['userId'] as String,
      userName: r['userName'] as String,
      rating: (r['rating'] as num).toDouble(),
      comment: r['comment'] as String,
      createdAt: DateTime.parse(r['createdAt'] as String),
    )).toList();
  }

  Future<void> insertReview(ReviewModel review) async {
    final d = await db;
    await d.insert('reviews', {
      'id': review.id,
      'productId': review.productId,
      'userId': review.userId,
      'userName': review.userName,
      'rating': review.rating,
      'comment': review.comment,
      'createdAt': review.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // Update product rating
    final rows = await d.query('reviews',
        where: 'productId = ?', whereArgs: [review.productId]);
    final avg = rows.fold<double>(0, (s, r) => s + (r['rating'] as num)) /
        rows.length;
    await d.update('products',
        {'rating': avg, 'reviewCount': rows.length},
        where: 'id = ?', whereArgs: [review.productId]);
  }

  // ── Users (Admin) ──────────────────────────────────────────────────────────

  Future<List<UserModel>> getAllUsers() async {
    final d = await db;
    final rows = await d.query('users', orderBy: 'name ASC');
    return rows.map(UserModel.fromMap).toList();
  }

  Future<void> setUserRole(String id, String role) async {
    final d = await db;
    await d.update('users', {'role': role}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> setUserLocked(String id, bool locked) async {
    final d = await db;
    await d.update('users', {'isLocked': locked ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteUser(String id) async {
    final d = await db;
    await d.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ── Stock ──────────────────────────────────────────────────────────────────

  Future<bool> decreaseStock(String productId, int quantity) async {
    final d = await db;
    final rows = await d.query('products', where: 'id = ?', whereArgs: [productId]);
    if (rows.isEmpty) return false;
    final current = rows.first['stock'] as int;
    if (current < quantity) return false;
    await d.update('products', {'stock': current - quantity},
        where: 'id = ?', whereArgs: [productId]);
    return true;
  }

  // ── Revenue Stats ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getRevenueStats() async {
    final d = await db;
    final all = await d.query('orders', orderBy: 'createdAt DESC');
    final orders = all.map(_orderFromMap).toList();

    double totalRevenue = 0;
    double monthRevenue = 0;
    final now = DateTime.now();
    final Map<String, double> revenueByDay = {};
    final Map<String, double> revenueByCategory = {};

    for (final o in orders) {
      if (o.status == 'cancelled') continue;
      totalRevenue += o.totalAmount;
      if (o.createdAt.year == now.year && o.createdAt.month == now.month) {
        monthRevenue += o.totalAmount;
        final day = '${o.createdAt.day}/${o.createdAt.month}';
        revenueByDay[day] = (revenueByDay[day] ?? 0) + o.totalAmount;
      }
      for (final item in o.items) {
        // get category from products table
        final pRows = await d.query('products', columns: ['category'], where: 'id = ?', whereArgs: [item.productId]);
        final cat = pRows.isNotEmpty ? pRows.first['category'] as String : 'other';
        revenueByCategory[cat] = (revenueByCategory[cat] ?? 0) + item.subtotal;
      }
    }

    return {
      'totalRevenue': totalRevenue,
      'monthRevenue': monthRevenue,
      'totalOrders': orders.length,
      'pendingOrders': orders.where((o) => o.status == 'pending').length,
      'revenueByDay': revenueByDay,
      'revenueByCategory': revenueByCategory,
    };
  }

  // ── Categories ─────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories() async {
    final d = await db;
    final rows = await d.query('categories', orderBy: 'sortOrder ASC');
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<void> upsertCategory(CategoryModel cat) async {
    final d = await db;
    await d.insert('categories', cat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteCategory(String id) async {
    final d = await db;
    await d.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
