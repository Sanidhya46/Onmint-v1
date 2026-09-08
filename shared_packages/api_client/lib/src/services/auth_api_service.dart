import '../api_client_base.dart';
import '../models/models.dart';

class AuthApiService {
  final ApiClient _client;

  AuthApiService(this._client);

  // Register
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _client.post('/auth/register', data: data);
    return response.data;
  }

  // Register with files (profile picture and documents)
  Future<Map<String, dynamic>> registerWithFiles(Map<String, dynamic> data, {Map<String, String>? files, List<dynamic>? xFiles, Map<String, dynamic>? namedXFiles}) async {
    // We use dynamic for xFiles to avoid tight coupling if not needed, but we pass it down
    final response = await _client.uploadMultipartData('/auth/register', data, namedFiles: files, xFiles: xFiles?.cast(), namedXFiles: namedXFiles?.cast());
    return response.data;
  }

  // Login
  Future<Map<String, dynamic>> login(Map<String, dynamic> credentials) async {
    final response = await _client.post('/auth/login', data: credentials);
    if (response.data['success'] == true && response.data['data']?['accessToken'] != null) {
      await _client.setToken(response.data['data']['accessToken']);
    }
    return response.data;
  }

  // Get current user profile
  Future<User> getProfile() async {
    final response = await _client.get('/auth/me');
    return User.fromJson(response.data['data']);
  }

  // Update profile
  Future<User> updateProfile(Map<String, dynamic> data, {String? profilePicturePath}) async {
    final response = profilePicturePath != null
        ? await _client.uploadMultipartData('/auth/profile', data, filePaths: [profilePicturePath], fileFieldName: 'profilePicture')
        : await _client.put('/auth/profile', data: data);
    return User.fromJson(response.data['data']);
  }

  // Delete profile picture
  Future<User> deleteProfilePicture() async {
    final response = await _client.delete('/auth/profile/picture');
    return User.fromJson(response.data['data']);
  }

  // Update device token for push notifications
  Future<void> updateDeviceToken(String deviceToken) async {
    await _client.post('/auth/device-token', data: {'deviceToken': deviceToken});
  }

  // Change password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _client.post('/auth/change-password', data: {
      'oldPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // Logout
  Future<void> logout() async {
    await _client.post('/auth/logout');
    await _client.clearToken();
  }

  // Logout from all devices
  Future<void> logoutAll() async {
    await _client.post('/auth/logout-all');
    await _client.clearToken();
  }

  // Delete account (GDPR permanent erasure)
  Future<Map<String, dynamic>> deleteAccount({
    required String confirmPassword,
    String? reason,
    String? role,
    String? phone,
    String? email,
  }) async {
    try {
      // 1. Authenticated DELETE request
      final response = await _client.delete(
        '/account/delete',
        data: {
          'confirmPassword': confirmPassword,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        },
      );
      await _client.clearToken();
      if (response.data is Map<String, dynamic>) {
        return response.data as Map<String, dynamic>;
      }
      return {'success': true, 'message': 'Account deleted successfully'};
    } catch (e) {
      // Fallback: Direct POST request
      try {
        final directPayload = <String, dynamic>{
          'role': role ?? 'patient',
          'password': confirmPassword,
          'confirmPassword': confirmPassword,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
        };
        if (email != null && email.isNotEmpty) {
          directPayload['email'] = email;
        } else if (phone != null && phone.isNotEmpty) {
          final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
          final rawPhone = cleanPhone.startsWith('91') && cleanPhone.length == 12
              ? cleanPhone.substring(2)
              : cleanPhone;
          directPayload['phone'] = rawPhone;
        }
        final directRes = await _client.post('/account/delete', data: directPayload);
        await _client.clearToken();
        if (directRes.data is Map<String, dynamic>) {
          return directRes.data as Map<String, dynamic>;
        }
        return {'success': true, 'message': 'Account deleted successfully'};
      } catch (_) {
        rethrow;
      }
    }
  }
}
