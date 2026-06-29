import 'package:flutter/material.dart';

class AppConfig {
  static const String appName = 'OnMint';
  static const String apiBaseUrl = 'https://api.onmint.in/api/v1';

  // Development mode
  static const bool developmentMode = true;
  static const bool forceLogoutOnStart = false;

  // Theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF00BCD4),
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Color(0xFF00BCD4),
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
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFF44336),
        foregroundColor: Colors.white,
      ),
    );
  }

  // Service Types
  static const List<String> serviceTypes = [
    'doctor',
    'nurse',
    'ambulance',
    'pharmacist',
    'bloodbank',
    'pathology',
  ];

  // Blood Groups
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];
}
