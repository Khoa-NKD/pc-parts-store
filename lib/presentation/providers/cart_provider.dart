import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/cart_item_model.dart';
import '../../data/models/product_model.dart';

class CartNotifier extends StateNotifier<List<CartItemModel>> {
  final DatabaseHelper _db;

  CartNotifier(this._db) : super([]) {
    _load();
  }

  Future<void> _load() async {
    state = await _db.getCartItems();
  }

  Future<void> addItem(ProductModel product, {int quantity = 1}) async {
    if (product.stock <= 0) throw Exception('Sản phẩm đã hết hàng');
    final existing = state.where((i) => i.product.id == product.id).firstOrNull;
    final newQty = (existing?.quantity ?? 0) + quantity;
    if (newQty > product.stock) throw Exception('Chỉ còn ${product.stock} sản phẩm trong kho');
    final item = CartItemModel(product: product, quantity: newQty);
    await _db.upsertCartItem(item);
    await _load();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) { await removeItem(productId); return; }
    final existing = state.where((i) => i.product.id == productId).firstOrNull;
    if (existing == null) return;
    await _db.upsertCartItem(existing.copyWith(quantity: quantity));
    await _load();
  }

  Future<void> removeItem(String productId) async {
    await _db.removeCartItem(productId);
    state = state.where((i) => i.product.id != productId).toList();
  }

  Future<void> clear() async {
    await _db.clearCart();
    state = [];
  }
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItemModel>>((ref) {
  return CartNotifier(ref.watch(dbProvider));
});

final cartTotalProvider = Provider<double>((ref) =>
    ref.watch(cartProvider).fold(0, (s, i) => s + i.subtotal));

final cartItemCountProvider = Provider<int>((ref) =>
    ref.watch(cartProvider).fold(0, (s, i) => s + i.quantity));
