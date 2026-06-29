import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppConfig {
  static const String appName = 'OnMint Vendor';
  static const String apiBaseUrl = 'https://api.onmint.in/api/v1';
  static const bool isDevelopmentMode = true;
  
  // Vendor roles
  static const List<String> vendorRoles = [
    'doctor',
    'nurse',
    'pharmacist',
    'ambulance',
    'bloodbank',
    'pathology',
    'labtest',
  ];
  
  // Role display names
  static const Map<String, String> roleDisplayNames = {
    'doctor': 'Doctor',
    'nurse': 'Nurse',
    'pharmacist': 'Pharmacist',
    'ambulance': 'Ambulance Driver',
    'bloodbank': 'Blood Bank',
    'pathology': 'Pathology Lab',
    'labtest': 'Lab Test',
  };
  
  // Booking statuses
  static const List<String> bookingStatuses = [
    'requested',
    'accepted',
    'on_the_way',
    'in_progress',
    'completed',
    'cancelled',
  ];
  
  // Days of week
  static const List<String> daysOfWeek = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];
  
  // Theme
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.primaryDark,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey[50],
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
  
  static String getRoleDisplayName(String role) {
    return roleDisplayNames[role.toLowerCase()] ?? role;
  }
  
  static IconData getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'doctor':
        return Icons.medical_services;
      case 'nurse':
        return Icons.local_hospital;
      case 'pharmacist':
        return Icons.medication;
      case 'ambulance':
        return Icons.local_shipping;
      case 'bloodbank':
        return Icons.bloodtype;
      case 'pathology':
        return Icons.science;
      case 'labtest':
        return Icons.biotech;
      default:
        return Icons.person;
    }
  }
}
