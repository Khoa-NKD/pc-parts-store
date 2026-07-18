class CategoryModel {
  final String id;
  final String name;
  final String icon;
  final int sortOrder;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    this.sortOrder = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name, 'icon': icon, 'sortOrder': sortOrder,
  };

  factory CategoryModel.fromMap(Map<String, dynamic> m) => CategoryModel(
    id: m['id'] as String,
    name: m['name'] as String,
    icon: m['icon'] as String,
    sortOrder: m['sortOrder'] as int? ?? 0,
  );
}
