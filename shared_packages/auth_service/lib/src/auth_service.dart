import 'package:api_client/api_client.dart';
import 'package:dio/dio.dart';

/// Authentication service for OnMint healthcare platform
class AuthService {
  final OnMintApiClient _apiClient = OnMintApiClient();

  /// Register new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> registrationData, {Map<String, String>? files, List<dynamic>? xFiles, Map<String, dynamic>? namedXFiles}) async {
    try {
      if ((files != null && files.isNotEmpty) || (xFiles != null && xFiles.isNotEmpty) || (namedXFiles != null && namedXFiles.isNotEmpty)) {
        return await _apiClient.auth.registerWithFiles(registrationData, files: files, xFiles: xFiles, namedXFiles: namedXFiles);
      }
      return await _apiClient.auth.register(registrationData);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final message = e.response?.data['message'] ?? 'Registration failed';
        throw Exception(message);
      }
      throw Exception('Registration failed: ${e.message}');
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login(String phone, String password) async {
    try {
      final loginData = {'phone': phone, 'password': password};
      return await _apiClient.auth.login(loginData);
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final message = e.response?.data['message'] ?? 'Login failed';
        throw Exception(message);
      }
      throw Exception('Login failed: ${e.message}');
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

  /// Permanently delete account
  Future<void> deleteAccount({
    required String confirmPassword,
    String? reason,
    String? role,
    String? phone,
    String? email,
  }) async {
    try {
      await _apiClient.auth.deleteAccount(
        confirmPassword: confirmPassword,
        reason: reason,
        role: role,
        phone: phone,
        email: email,
      );
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final message = e.response?.data['message'] ?? 'Account deletion failed';
        throw Exception(message);
      }
      throw Exception('Account deletion failed: ${e.message}');
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }
}