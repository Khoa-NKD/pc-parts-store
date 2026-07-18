import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import '../../providers/cart_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  int _idx(String loc) {
    if (loc.startsWith('/products')) return 1;
    if (loc.startsWith('/cart')) return 2;
    if (loc.startsWith('/profile')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = GoRouterState.of(context).matchedLocation;
    final count = ref.watch(cartItemCountProvider);
    final isChat = loc.startsWith('/chat');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) SystemNavigator.pop();
      },
      child: Scaffold(
        body: child,
        floatingActionButton: isChat
            ? null
            : FloatingActionButton(
                onPressed: () => context.push('/chat'),
                backgroundColor: const Color(0xFF1A73E8),
                shape: const CircleBorder(),
                child: const Icon(Icons.chat_bubble_rounded, color: Colors.white),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _idx(loc),
          onDestinationSelected: (i) {
            switch (i) {
              case 0: context.go('/home');
              case 1: context.go('/products');
              case 2: context.go('/cart');
              case 3: context.go('/profile');
            }
          },
          destinations: [
            const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Trang chủ'),
            const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view),
                label: 'Sản phẩm'),
            NavigationDestination(
              icon: badges.Badge(
                showBadge: count > 0,
                badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
                badgeContent: Text('$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
              selectedIcon: badges.Badge(
                showBadge: count > 0,
                badgeStyle: const badges.BadgeStyle(badgeColor: Colors.red),
                badgeContent: Text('$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10)),
                child: const Icon(Icons.shopping_cart),
              ),
              label: 'Giỏ hàng',
            ),
            const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Tài khoản'),
          ],
        ),
      ),
    );
  }
}
