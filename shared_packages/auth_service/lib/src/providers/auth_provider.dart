import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:api_client/api_client.dart';
import '../models/auth_token.dart';
import '../auth_service.dart';

/// Authentication state provider
class AuthProvider extends ChangeNotifier {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final AuthService _authService = AuthService();
  final ApiClient _apiClient = ApiClient();
  
  User? _currentUser;
  AuthToken? _currentToken;
  bool _isLoading = false;
  String? _error;

  /// Current authenticated user
  User? get currentUser => _currentUser;
  
  /// Current authentication token
  AuthToken? get currentToken => _currentToken;
  
  /// Loading state
  bool get isLoading => _isLoading;
  
  /// Error message
  String? get error => _error;
  
  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null && _currentToken?.isValid == true;
  
  /// Check if current user is patient
  bool get isPatient => _currentUser?.isPatient == true;
  
  /// Check if current user is vendor
  bool get isVendor => _currentUser?.isVendor == true;
  
  /// Check if current user is admin
  bool get isAdmin => _currentUser?.isAdmin == true;

  /// Initialize auth state from storage
  Future<void> initialize() async {
    // Set loading without notifying listeners initially
    _isLoading = true;
    
    try {
      debugPrint('AuthProvider: Initializing...');
      
      // Load from storage first
      await _loadFromStorage();
      
      // If we have a valid token, set it in the API client
      if (_currentToken != null && _currentToken!.isValid) {
        _apiClient.setAuthToken(_currentToken!.token);
        debugPrint('Token loaded and set in API client');
      } else {
        debugPrint('No valid token found, clearing auth data');
        await _clearAuthData();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('AuthProvider initialization error: $e');
      _error = 'Failed to initialize authentication: $e';
      _isLoading = false;
      // Clear corrupted data
      await _clearAuthData();
      notifyListeners();
    }
  }

  /// Login with phone and password
  Future<bool> login(String phone, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('Starting login process for: $phone');
      
      final result = await _authService.login(phone, password);
      
      debugPrint('Login result received');
      
      // result is Map<String, dynamic> directly
      if (result['success'] == true && result['data'] != null) {
        debugPrint('Login successful');
        
        // Handle different response formats from backend
        final responseData = result['data'] as Map<String, dynamic>;
        Map<String, dynamic> userData;
        String tokenString;
        
        if (responseData.containsKey('user') && responseData.containsKey('token')) {
          // Format: { user: {...}, token: "..." }
          debugPrint('Using format: user + token');
          userData = responseData['user'] as Map<String, dynamic>;
          tokenString = responseData['token'] as String;
        } else if (responseData.containsKey('user') && responseData.containsKey('accessToken')) {
          // Format: { user: {...}, accessToken: "..." }
          debugPrint('Using format: user + accessToken');
          userData = responseData['user'] as Map<String, dynamic>;
          tokenString = responseData['accessToken'] as String;
        } else {
          // Assume the entire response is user data and look for token
          debugPrint('Using format: direct response');
          userData = responseData;
          tokenString = responseData['accessToken'] as String? ?? responseData['token'] as String? ?? '';
        }
        
        debugPrint('User role from backend: ${userData['role']}');
        
        if (tokenString.isEmpty) {
          throw Exception('No token received from backend');
        }
        
        await _setAuthData(userData, tokenString);
        
        return true;
      } else {
        final errorMessage = result['message']?.toString() ?? 'Login failed';
        debugPrint('Login failed: $errorMessage');
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      final errorMessage = 'Login failed: $e';
      debugPrint('Login exception: $errorMessage');
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register new user
  Future<bool> register(Map<String, dynamic> registrationData, {List<dynamic>? xFiles, Map<String, dynamic>? namedXFiles}) async {
    _setLoading(true);
    _clearError();
    
    try {
      debugPrint('Starting registration process...');
      
      final result = await _authService.register(registrationData, xFiles: xFiles, namedXFiles: namedXFiles);
      
      debugPrint('Registration result received');
      
      // result is Map<String, dynamic> directly
      if (result['success'] == true && result['data'] != null) {
        debugPrint('Registration successful');
        
        // Handle different response formats from backend
        final responseData = result['data'] as Map<String, dynamic>;
        Map<String, dynamic> userData;
        String tokenString;
        
        if (responseData.containsKey('user') && responseData.containsKey('token')) {
          // Format: { user: {...}, token: "..." }
          userData = responseData['user'] as Map<String, dynamic>;
          tokenString = responseData['token'] as String;
        } else if (responseData.containsKey('user') && responseData.containsKey('accessToken')) {
          // Format: { user: {...}, accessToken: "..." }
          userData = responseData['user'] as Map<String, dynamic>;
          tokenString = responseData['accessToken'] as String;
        } else {
          // Assume the entire response is user data and look for token
          userData = responseData;
          tokenString = responseData['token'] as String? ?? responseData['accessToken'] as String? ?? '';
        }
        
        debugPrint('User role from backend: ${userData['role']}');
        
        if (tokenString.isEmpty) {
          throw Exception('No token received from backend');
        }
        
        await _setAuthData(userData, tokenString);
        return true;
      } else {
        final errorMessage = result['message']?.toString() ?? 'Registration failed';
        debugPrint('Registration failed: $errorMessage');
        _setError(errorMessage);
        return false;
      }
    } catch (e) {
      final errorMessage = 'Registration failed: $e';
      debugPrint('Registration exception: $errorMessage');
      _setError(errorMessage);
      return false;
    } finally {
      _setLoading(false);
    }
  }
  /// Logout user
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      // Call logout API if token exists
      if (_currentToken != null) {
        await _authService.logout();
      }
    } catch (e) {
      // Continue with logout even if API call fails
      debugPrint('Logout API call failed: $e');
    }
    
    // Clear local data
    await _clearAuthData();
    _setLoading(false);
  }

  /// Refresh authentication token
  Future<bool> refreshToken() async {
    if (_currentToken == null) return false;
    
    try {
      // Token refresh not implemented in auth service yet
      debugPrint('Token refresh not implemented');
      return false;
    } catch (e) {
      debugPrint('Token refresh failed: $e');
    }
    
    return false;
  }

  /// Refresh user profile data
  Future<bool> refreshProfile() async {
    if (!isAuthenticated) return false;
    
    try {
      final result = await _authService.getProfile();
      
      // result is User object directly
      _currentUser = result;
      await _saveUserToStorage(_currentUser!);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Profile refresh failed: $e');
    }
    
    return false;
  }

  /// Update user profile
  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    if (!isAuthenticated) return false;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Update profile not implemented in auth service yet
      debugPrint('Update profile not implemented');
      _setError('Profile update not available');
      return false;
    } catch (e) {
      _setError('Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Set authentication data
  Future<void> _setAuthData(Map<String, dynamic> userData, String tokenString) async {
    try {
      debugPrint('Setting auth data...');
      debugPrint('User data email: ${userData['email']}');
      debugPrint('User data role: ${userData['role']}');
      debugPrint('Token string: ${tokenString.substring(0, 20)}...');
      
      // Validate and clean userData before creating User object
      final cleanedUserData = _cleanUserData(userData);
      
      _currentUser = User.fromJson(cleanedUserData);
      _currentToken = AuthToken.fromJwtPayload(tokenString, cleanedUserData);
      
      // Set token in API client for authenticated requests
      _apiClient.setAuthToken(tokenString);
      
      // Save to storage for persistence
      await _saveUserToStorage(_currentUser!);
      await _saveTokenToStorage(_currentToken!);
      
      debugPrint('Auth data set successfully');
      debugPrint('Final user: ${_currentUser?.email}, role: ${_currentUser?.role}, isAdmin: ${_currentUser?.isAdmin}');
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error setting auth data: $e');
      rethrow;
    }
  }

  /// Clean user data to ensure all fields are correct types
  Map<String, dynamic> _cleanUserData(Map<String, dynamic> userData) {
    final cleaned = Map<String, dynamic>.from(userData);
    
    // Ensure emergencyContact is a Map or null
    if (cleaned['emergencyContact'] != null && cleaned['emergencyContact'] is! Map) {
      debugPrint('Warning: emergencyContact is not a Map, setting to null');
      cleaned['emergencyContact'] = null;
    }
    
    // Ensure bloodStock is a List
    if (cleaned['bloodStock'] != null && cleaned['bloodStock'] is! List) {
      debugPrint('Warning: bloodStock is not a List, setting to empty list');
      cleaned['bloodStock'] = [];
    }
    
    // Ensure testsOffered is a List
    if (cleaned['testsOffered'] != null && cleaned['testsOffered'] is! List) {
      debugPrint('Warning: testsOffered is not a List, setting to empty list');
      cleaned['testsOffered'] = [];
    }
    
    // Ensure availability is a List
    if (cleaned['availability'] != null && cleaned['availability'] is! List) {
      debugPrint('Warning: availability is not a List, setting to empty list');
      cleaned['availability'] = [];
    }
    
    return cleaned;
  }

  /// Clear authentication data
  Future<void> _clearAuthData() async {
    debugPrint('Clearing auth data...');
    _currentUser = null;
    _currentToken = null;
    
    // Clear token from API client
    _apiClient.clearAuthToken();
    
    await _secureStorage.delete(key: _userKey);
    await _secureStorage.delete(key: _tokenKey);
    
    debugPrint('Auth data cleared');
    notifyListeners();
  }

  /// Load data from secure storage
  Future<void> _loadFromStorage() async {
    try {
      final userJson = await _secureStorage.read(key: _userKey);
      final tokenJson = await _secureStorage.read(key: _tokenKey);
      
      if (userJson != null && tokenJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));
        _currentToken = AuthToken.fromJson(jsonDecode(tokenJson));
      }
    } catch (e) {
      debugPrint('Failed to load auth data from storage: $e');
    }
  }

  /// Save user to secure storage
  Future<void> _saveUserToStorage(User user) async {
    try {
      await _secureStorage.write(key: _userKey, value: jsonEncode(user.toJson()));
    } catch (e) {
      debugPrint('Failed to save user to storage: $e');
    }
  }

  /// Save token to secure storage
  Future<void> _saveTokenToStorage(AuthToken token) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: jsonEncode(token.toJson()));
    } catch (e) {
      debugPrint('Failed to save token to storage: $e');
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Force clear all authentication data (for debugging)
  Future<void> forceLogout() async {
    debugPrint('Force clearing all authentication data');
    await _clearAuthData();
    // Also clear any cached data from secure storage
    try {
      await _secureStorage.deleteAll();
      debugPrint('Cleared all secure storage data');
    } catch (e) {
      debugPrint('Error clearing secure storage: $e');
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await _authService.changePassword(currentPassword, newPassword);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(e.toString().replaceAll('Exception: ', ''));
      _setLoading(false);
      return false;
    }
  }

  /// Permanently delete account
  Future<bool> deleteAccount({
    required String confirmPassword,
    String? reason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final user = _currentUser;
      await _authService.deleteAccount(
        confirmPassword: confirmPassword,
        reason: reason,
        role: user?.role,
        phone: user?.phone,
        email: user?.email,
      );

      // Server deletion succeeded; clear all local auth state and storage
      await _clearAuthData();
      _setLoading(false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _setError(msg);
      _setLoading(false);
      return false;
    }
  }

}
