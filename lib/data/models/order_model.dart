class OrderItemModel {
  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    required this.quantity,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toMap() => {
    'productId': productId, 'productName': productName,
    'productImage': productImage, 'price': price, 'quantity': quantity,
  };

  factory OrderItemModel.fromMap(Map<String, dynamic> m) => OrderItemModel(
    productId: m['productId'] as String,
    productName: m['productName'] as String,
    productImage: m['productImage'] as String? ?? '',
    price: (m['price'] as num).toDouble(),
    quantity: m['quantity'] as int,
  );
}

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String shippingAddress;
  final String phone;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.shippingAddress,
    required this.phone,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
  });

  OrderModel copyWith({String? status}) => OrderModel(
    id: id, userId: userId, userName: userName,
    shippingAddress: shippingAddress, phone: phone, items: items,
    totalAmount: totalAmount, status: status ?? this.status,
    paymentMethod: paymentMethod, createdAt: createdAt,
  );
}
