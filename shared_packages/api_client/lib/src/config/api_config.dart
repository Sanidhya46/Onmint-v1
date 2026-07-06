import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ════════════════════════════════════════════════════════════════════════════
  // 🔧 SIMPLE SETUP - CHANGE ONLY LINE 7 WHEN YOU HOST YOUR API
  // ════════════════════════════════════════════════════════════════════════════
  
  // Change this to your hosted API URL
  static String get _baseUrlDev {
    if (kIsWeb) return 'http://localhost:5000/api/v1';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:5000/api/v1';
    } catch (_) {}
    return 'http://localhost:5000/api/v1';
  }
  // Example: 'https://api.yourdomain.com/api/v1'
  
  // Change to true ONLY if you have separate dev & production environments
  static const bool _isProduction = true; // MAKE TRUE WHILE HOSTING ..
  
  // ════════════════════════════════════════════════════════════════════════════
  // ADVANCED: Only change this if you have separate production server
  // ════════════════════════════════════════════════════════════════════════════
  
  static const String _baseUrlProd = 'https://api.onmint.in/api/v1';
  
  // ════════════════════════════════════════════════════════════════════════════
  // NO NEED TO CHANGE ANYTHING BELOW THIS LINE
  // ════════════════════════════════════════════════════════════════════════════
  
  // Runtime configurable base URL (can be changed dynamically)
  static String? _runtimeBaseUrl;
  
  // Get current base URL
  // Logic: If _isProduction=true, use _baseUrlProd, else use _baseUrlDev
  static String get baseUrl => _runtimeBaseUrl ?? (_isProduction ? _baseUrlProd : _baseUrlDev);
  
  // Set custom base URL at runtime
  static void setBaseUrl(String url) {
    _runtimeBaseUrl = url;
    print('✅ API Base URL changed to: $url');
  }
  
  // Reset to default configuration
  static void resetToDefault() {
    _runtimeBaseUrl = null;
    print('✅ API Base URL reset to default: $baseUrl');
  }
  
  // Get current configuration info
  static String getConfigInfo() {
    return '''
╔════════════════════════════════════════════════════════════╗
║              API Configuration Details                     ║
╠════════════════════════════════════════════════════════════╣
║ Current Base URL: $baseUrl
║ Environment: ${_isProduction ? 'PRODUCTION' : 'DEVELOPMENT'}
║ Dev URL: $_baseUrlDev
║ Prod URL: $_baseUrlProd
╚════════════════════════════════════════════════════════════╝
    ''';
  }
  
  // Connection timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(minutes: 5);
  
  // API endpoints
  static const String authEndpoint = '/auth';
  static const String patientEndpoint = '/patient';
  static const String doctorEndpoint = '/doctor';
  static const String adminEndpoint = '/admin';
  static const String pharmacistEndpoint = '/pharmacist';
  static const String nurseEndpoint = '/nurse';
  static const String ambulanceEndpoint = '/ambulance';
  static const String pathologyEndpoint = '/pathology';
  static const String bloodbankEndpoint = '/bloodbank';
  
  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
