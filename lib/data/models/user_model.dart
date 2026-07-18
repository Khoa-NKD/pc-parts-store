class UserModel {
  final String id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? address;
  final List<String> wishlist;
  final bool isLocked;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.role = 'user',
    this.phone,
    this.address,
    this.wishlist = const [],
    this.isLocked = false,
  });

  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? name, String? phone, String? address, List<String>? wishlist, bool? isLocked,
  }) => UserModel(
    id: id, email: email, name: name ?? this.name, role: role,
    phone: phone ?? this.phone, address: address ?? this.address,
    wishlist: wishlist ?? this.wishlist,
    isLocked: isLocked ?? this.isLocked,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'email': email, 'name': name, 'role': role,
    'phone': phone ?? '', 'address': address ?? '',
    'wishlist': wishlist.join('|'),
    'isLocked': isLocked ? 1 : 0,
  };

  factory UserModel.fromMap(Map<String, dynamic> m) => UserModel(
    id: m['id'] as String,
    email: m['email'] as String,
    name: m['name'] as String,
    role: m['role'] as String? ?? 'user',
    phone: m['phone'] as String?,
    address: m['address'] as String?,
    wishlist: (m['wishlist'] as String? ?? '').isEmpty
        ? [] : (m['wishlist'] as String).split('|'),
    isLocked: (m['isLocked'] as int? ?? 0) == 1,
  );
}
