import 'package:flutter/material.dart';

/// Application configuration for Admin App
class AppConfig {
  /// Development mode - always show login screen for testing
  /// Set to false for production to enable normal authentication flow
  static const bool developmentMode = false;  // Set to true to always show login first
  
  /// Force logout on app start (for testing)
  static const bool forceLogoutOnStart = false;  // Set to true to clear cached auth
  
  /// Show debug information in console
  static const bool showDebugLogs = false;
  
  // API Configuration
  static const String appName = 'OnMint Admin';
  static const String apiBaseUrl = 'https://api.onmint.in/api/v1';
  
  // Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  // Colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color secondaryColor = Color(0xFF03A9F4);
  static const Color successColor = Color(0xFF4CAF50);
  static const Color errorColor = Color(0xFFF44336);
  static const Color warningColor = Color(0xFFFF9800);
  static const Color infoColor = Color(0xFF2196F3);
}