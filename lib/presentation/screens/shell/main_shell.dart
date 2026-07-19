import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:badges/badges.dart' as badges;
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/design_tokens.dart';
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
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: DesignTokens.shadowMd,
                  gradient: const LinearGradient(
                    colors: [DesignTokens.primary, DesignTokens.secondary],
                  ),
                ),
                child: FloatingActionButton(
                  onPressed: () => context.push('/chat'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  focusElevation: 0,
                  highlightElevation: 0,
                  hoverElevation: 0,
                  shape: const CircleBorder(),
                  child: const Icon(LucideIcons.messageSquare, color: Colors.white, size: 24),
                ),
              ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: DesignTokens.primary.withValues(alpha: 0.1),
            selectedIndex: _idx(loc),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
                  icon: Icon(LucideIcons.home, size: 22),
                  selectedIcon: Icon(LucideIcons.home, size: 22, color: DesignTokens.primary),
                  label: 'Trang chủ'),
              const NavigationDestination(
                  icon: Icon(LucideIcons.grid, size: 22),
                  selectedIcon: Icon(LucideIcons.grid, size: 22, color: DesignTokens.primary),
                  label: 'Sản phẩm'),
              NavigationDestination(
                icon: badges.Badge(
                  showBadge: count > 0,
                  badgeStyle: const badges.BadgeStyle(badgeColor: DesignTokens.danger, padding: EdgeInsets.all(4)),
                  badgeContent: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  child: const Icon(LucideIcons.shoppingCart, size: 22),
                ),
                selectedIcon: badges.Badge(
                  showBadge: count > 0,
                  badgeStyle: const badges.BadgeStyle(badgeColor: DesignTokens.danger, padding: EdgeInsets.all(4)),
                  badgeContent: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  child: const Icon(LucideIcons.shoppingCart, size: 22, color: DesignTokens.primary),
                ),
                label: 'Giỏ hàng',
              ),
              const NavigationDestination(
                  icon: Icon(LucideIcons.user, size: 22),
                  selectedIcon: Icon(LucideIcons.user, size: 22, color: DesignTokens.primary),
                  label: 'Tài khoản'),
            ],
          ),
        ),
      ),
    );
  }
}
