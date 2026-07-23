import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../local/database_helper.dart';
import '../models/cart_item_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import 'payos_client_service.dart';

final orderServiceProvider =
    Provider<OrderService>((ref) => OrderService(ref.watch(dbProvider)));

class OrderService {
  final DatabaseHelper _db;
  final _payOSService = PayOSClientService();

  OrderService(this._db);

  Future<String> placeOrder({
    required UserModel user,
    required List<CartItemModel> items,
    required String shippingAddress,
    required String phone,
    required String paymentMethod,
  }) async {
    // Kiểm tra và giảm stock
    for (final item in items) {
      final ok = await _db.decreaseStock(item.product.id, item.quantity);
      if (!ok) throw Exception('Sản phẩm "${item.product.name}" đã hết hàng hoặc không đủ số lượng');
    }

    final id = const Uuid().v4();
    final order = OrderModel(
      id: id,
      userId: user.id,
      userName: user.name,
      shippingAddress: shippingAddress,
      phone: phone,
      items: items
          .map((ci) => OrderItemModel(
                productId: ci.product.id,
                productName: ci.product.name,
                productImage: ci.product.mainImage,
                price: ci.product.effectivePrice,
                quantity: ci.quantity,
              ))
          .toList(),
      totalAmount: items.fold(0, (total, i) => total + i.subtotal),
      status: 'pending',
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
    );
    await _db.insertOrder(order);
    return id;
  }

  Future<List<OrderModel>> getUserOrders(String userId) =>
      _db.getUserOrders(userId);

  Future<List<OrderModel>> getAllOrders() => _db.getAllOrders();

  Future<void> updateOrderStatus(String id, String status) =>
      _db.updateOrderStatus(id, status);

  /// Gọi trực tiếp API PayOS (Chỉ dùng cho Demo/Học tập)
  Future<String> createPayOSPaymentLink({
    required String orderId,
    required double amount,
    required String description,
  }) async {
    // PayOS yêu cầu orderCode phải là số nguyên (int)
    // Chúng ta sẽ convert UUID sang một số nguyên duy nhất
    final int orderCode = _generateNumericOrderCode(orderId);
    
    return _payOSService.createPaymentLink(
      orderCode: orderCode,
      amount: amount,
      description: description,
    );
  }

  /// Helper để chuyển UUID String sang số nguyên cho PayOS
  int _generateNumericOrderCode(String uuid) {
    // Lấy 8 ký tự cuối của UUID và chuyển sang int từ hex
    final String hex = uuid.replaceAll('-', '').substring(0, 8);
    return int.parse(hex, radix: 16);
  }
}
