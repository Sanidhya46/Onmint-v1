import 'package:api_client/api_client.dart';

/// Authentication service for OnMint healthcare platform
class AuthService {
  final OnMintApiClient _apiClient = OnMintApiClient();

  /// Register new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> registrationData) async {
    try {
      return await _apiClient.auth.register(registrationData);
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final loginData = {'phone': phone, 'password': password};
      return await _apiClient.auth.login(loginData);
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _apiClient.auth.logout();
    } catch (e) {
      throw Exception('Logout failed: $e');
    }
  }

  /// Get user profile
  Future<User> getProfile() async {
    try {
      return await _apiClient.auth.getProfile();
    } catch (e) {
      throw Exception('Failed to get profile: $e');
    }
  }

  /// Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      await _apiClient.auth.changePassword(currentPassword, newPassword);
    } catch (e) {
      throw Exception('Password change failed: $e');
    }
  }

  /// Update device token for push notifications
  Future<void> updateDeviceToken(String deviceToken) async {
    try {
      await _apiClient.auth.updateDeviceToken(deviceToken);
    } catch (e) {
      throw Exception('Device token update failed: $e');
    }
  }

  /// Delete account and wipe all data (GDPR compliance)
  Future<void> deleteAccount({String? confirmPassword, String? reason}) async {
    try {
      await _apiClient.auth.deleteAccount(confirmPassword: confirmPassword, reason: reason);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
}