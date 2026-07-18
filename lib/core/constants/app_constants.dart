class AppConstants {
  static const List<Map<String, String>> categories = [
    {'id': 'cpu', 'name': 'CPU', 'icon': '🖥️'},
    {'id': 'gpu', 'name': 'GPU', 'icon': '🎮'},
    {'id': 'ram', 'name': 'RAM', 'icon': '💾'},
    {'id': 'ssd', 'name': 'SSD', 'icon': '💿'},
    {'id': 'motherboard', 'name': 'Mainboard', 'icon': '🔧'},
    {'id': 'psu', 'name': 'PSU', 'icon': '⚡'},
    {'id': 'case', 'name': 'Case', 'icon': '📦'},
    {'id': 'cooling', 'name': 'Cooling', 'icon': '❄️'},
  ];

  static const String orderPending = 'pending';
  static const String orderConfirmed = 'confirmed';
  static const String orderShipping = 'shipping';
  static const String orderDelivered = 'delivered';
  static const String orderCancelled = 'cancelled';
}
