import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/auth_service.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/product/product_list_screen.dart';
import '../../presentation/screens/product/product_detail_screen.dart';
import '../../presentation/screens/cart/cart_screen.dart';
import '../../presentation/screens/checkout/checkout_screen.dart';
import '../../presentation/screens/order/order_history_screen.dart';
import '../../presentation/screens/order/order_detail_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/wishlist/wishlist_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_product_form_screen.dart';
import '../../presentation/screens/admin/admin_orders_screen.dart';
import '../../presentation/screens/admin/admin_categories_screen.dart';
import '../../presentation/screens/admin/admin_users_screen.dart';
import '../../presentation/screens/admin/admin_user_detail_screen.dart';
import '../../presentation/screens/profile/edit_profile_screen.dart';
import '../../presentation/screens/admin/admin_revenue_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final isLoggedIn = user != null;
      final loc = state.matchedLocation;
      final isAuth = loc == '/login' || loc == '/register';
      if (!isLoggedIn && !isAuth) return '/login';
      if (isLoggedIn && isAuth) return user.isAdmin ? '/admin' : '/home';
      if (isLoggedIn && user.isAdmin && (loc == '/home' || loc == '/cart' || loc == '/products')) {
        return '/admin';
      }
      return null;
    },
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: RegisterScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/products', builder: (_, __) => const ProductListScreen()),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
          GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
        ],
      ),
      GoRoute(
        path: '/product/:id',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ProductDetailScreen(productId: state.pathParameters['id']!),
          transitionsBuilder: _slideUpTransition,
        ),
      ),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
      GoRoute(path: '/edit-profile', builder: (_, __) => const EditProfileScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
      GoRoute(
        path: '/order/:id',
        builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/admin',
        builder: (_, __) => const AdminDashboardScreen(),
        routes: [
          GoRoute(
            path: 'product',
            builder: (_, state) => AdminProductFormScreen(productId: state.uri.queryParameters['id']),
          ),
          GoRoute(path: 'orders', builder: (_, __) => const AdminOrdersScreen()),
          GoRoute(path: 'categories', builder: (_, __) => const AdminCategoriesScreen()),
          GoRoute(path: 'users', builder: (_, __) => const AdminUsersScreen()),
          GoRoute(path: 'revenue', builder: (_, __) => const AdminRevenueScreen()),
          GoRoute(
            path: 'users/:id',
            builder: (_, state) => AdminUserDetailScreen(userId: state.pathParameters['id']!),
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('404: ${state.error}')),
    ),
  );
});

Widget _fadeTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideUpTransition(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  const begin = Offset(0.0, 0.1);
  const end = Offset.zero;
  const curve = Curves.easeOutCubic;
  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
  return SlideTransition(position: animation.drive(tween), child: FadeTransition(opacity: animation, child: child));
}

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen(currentUserProvider, (_, __) => notifyListeners());
  }
}
