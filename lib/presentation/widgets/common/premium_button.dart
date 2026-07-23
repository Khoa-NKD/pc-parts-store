import 'package:flutter/material.dart';
import '../../../core/theme/design_tokens.dart';

class PremiumButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final Widget? icon;
  final double? width;

  const PremiumButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final foregroundColor = isSecondary ? DesignTokens.textPrimary : Colors.white;

    return SizedBox(
      width: width,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
          gradient: isSecondary
              ? null
              : LinearGradient(
                  colors: [
                    DesignTokens.primary,
                    DesignTokens.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: isSecondary ? null : DesignTokens.shadowSm,
          border: isSecondary ? Border.all(color: DesignTokens.border) : null,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: foregroundColor,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
            ),
          ),
          child: isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(text, style: DesignTokens.buttonText.copyWith(color: foregroundColor)),
                  ],
                ),
        ),
      ),
    );
  }
}
