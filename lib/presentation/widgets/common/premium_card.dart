import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool isGlass;
  final VoidCallback? onTap;
  final double? borderRadius;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.isGlass = false,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget current = Container(
      padding: padding ?? const EdgeInsets.all(DesignTokens.s2),
      child: child,
    );

    if (isGlass) {
      current = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.borderRadiusL),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: current,
          ),
        ),
      );
    } else {
      current = Container(
        decoration: BoxDecoration(
          color: DesignTokens.surface,
          borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.borderRadiusL),
          border: Border.all(color: DesignTokens.border),
          boxShadow: DesignTokens.shadowSm,
        ),
        child: current,
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? DesignTokens.borderRadiusL),
        child: current,
      );
    }

    return current;
  }
}
