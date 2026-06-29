/// API Configuration for OnMint Healthcare Platform
class ApiConfig {
  /// Base URL for the backend API
  /// Update this to your actual backend URL
  static const String baseUrl = 'https://api.onmint.in/api/v1';
  
  /// Mock mode for development (set to false to use real backend)
  static const bool mockMode = false;
  
  /// Request timeout duration
  static const Duration timeout = Duration(seconds: 30);
  
  /// Default headers for all requests
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
  
  /// API Endpoints
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authLogout = '/auth/logout';
  static const String authRefresh = '/auth/refresh';
  static const String authProfile = '/auth/profile';
  
  /// Patient endpoints
  static const String patientServices = '/patient/services/nearby';
  static const String patientBookings = '/patient/bookings';
  static const String patientEmergency = '/patient/emergency';
  
  /// Doctor endpoints
  static const String doctorAvailability = '/doctor/availability';
  static const String doctorAppointments = '/doctor/appointments';
  
  /// Vendor endpoints
  static const String vendorProfile = '/vendor/profile';
  static const String vendorServices = '/vendor/services';
  
  /// Admin endpoints
  static const String adminUsers = '/admin/users';
  static const String adminProviders = '/admin/providers';
  
  /// Get full URL for endpoint
  static String getUrl(String endpoint) {
    return '$baseUrl$endpoint';
  }
}