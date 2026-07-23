import 'package:flutter/material.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: DesignTokens.primary,
          primary: DesignTokens.primary,
          secondary: DesignTokens.secondary,
          surface: DesignTokens.surface,
          error: DesignTokens.danger,
          onSurface: DesignTokens.textPrimary,
          onPrimary: Colors.white,
        ),
        scaffoldBackgroundColor: DesignTokens.background,
        textTheme: TextTheme(
          displayLarge: DesignTokens.h1,
          displayMedium: DesignTokens.h2,
          displaySmall: DesignTokens.h3,
          bodyLarge: DesignTokens.bodyLarge,
          bodyMedium: DesignTokens.bodyMedium,
          bodySmall: DesignTokens.bodySmall,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: DesignTokens.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: DesignTokens.textPrimary),
        ),
        cardTheme: CardThemeData(
          color: DesignTokens.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusL),
            side: const BorderSide(color: DesignTokens.border, width: 1),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: DesignTokens.primary,
            foregroundColor: Colors.white,
            textStyle: DesignTokens.buttonText,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: DesignTokens.surface,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
            borderSide: const BorderSide(color: DesignTokens.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
            borderSide: const BorderSide(color: DesignTokens.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
            borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusM),
            borderSide: const BorderSide(color: DesignTokens.danger),
          ),
          hintStyle: DesignTokens.bodySmall,
        ),
      );
}
