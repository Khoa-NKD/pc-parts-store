import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';

final wishlistProvider =
    StateNotifierProvider<WishlistNotifier, List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  return WishlistNotifier(ref, user?.wishlist ?? []);
});

class WishlistNotifier extends StateNotifier<List<String>> {
  final Ref _ref;
  WishlistNotifier(this._ref, List<String> initial) : super(initial);

  Future<void> toggle(String productId) async {
    final user = _ref.read(currentUserProvider);
    if (user == null) return;
    final updated = state.contains(productId)
        ? state.where((id) => id != productId).toList()
        : [...state, productId];
    state = updated;
    await _ref
        .read(currentUserProvider.notifier)
        .updateUser(user.copyWith(wishlist: updated));
  }

  bool isWishlisted(String id) => state.contains(id);
}
