import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/local/database_helper.dart';
import '../../data/models/category_model.dart';

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.watch(dbProvider).getCategories();
});
