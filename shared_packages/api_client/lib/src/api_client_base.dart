import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'config/api_config.dart';

class ApiClient {
  late final Dio _dio;
  String? _token;
  bool _tokenLoaded = false;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: ApiConfig.defaultHeaders,
    ));

    // Add interceptors
    _dio.interceptors.add(PrettyDioLogger(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      responseHeader: false,
      error: true,
      compact: true,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Ensure token is loaded before making request
        if (!_tokenLoaded) {
          await loadToken();
          _tokenLoaded = true;
        }
        
        // Add token to headers if available
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        // Handle 401 Unauthorized
        if (error.response?.statusCode == 401) {
          await clearAuthToken();
        }
        return handler.next(error);
      },
    ));
  }

  // Token management
  Future<void> setAuthToken(String token) async {
    _token = token;
    _tokenLoaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> setToken(String token) async {
    await setAuthToken(token);
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _tokenLoaded = true;
  }

  Future<void> clearAuthToken() async {
    _token = null;
    _tokenLoaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  Future<void> clearToken() async {
    await clearAuthToken();
  }

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  // Generic request methods
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Map<String, dynamic>? headers}) async {
    try {
      return await _dio.post(
        path, 
        data: data, 
        queryParameters: queryParameters,
        options: headers != null ? Options(headers: headers) : null,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> patch(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.patch(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      rethrow;
    }
  }

  // File upload
  Future<Response> uploadFile(String path, String filePath, {Map<String, dynamic>? data}) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        ...?data,
      });
      return await _dio.post(path, data: formData);
    } catch (e) {
      rethrow;
    }
  }

  // Multiple files upload with form data (Web compatible)
  Future<Response> uploadMultipartData(String path, Map<String, dynamic> data, {List<String>? filePaths, String fileFieldName = 'images', Map<String, String>? namedFiles, List<XFile>? xFiles, Map<String, XFile>? namedXFiles}) async {
    try {
      final formData = FormData.fromMap(data);
      
      // Add XFile objects (web compatible)
      if (xFiles != null && xFiles.isNotEmpty) {
        for (final xFile in xFiles) {
          final bytes = await xFile.readAsBytes();
          final String fileName = xFile.name.isNotEmpty 
              ? (xFile.name.contains('.') ? xFile.name : '${xFile.name}.jpg') 
              : 'image.jpg';
          formData.files.add(MapEntry(
            fileFieldName,
            MultipartFile.fromBytes(
              bytes,
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            ),
          ));
        }
      }
      // Fallback to file paths for mobile (if xFiles not provided)
      else if (filePaths != null && filePaths.isNotEmpty) {
        for (final filePath in filePaths) {
          try {
            formData.files.add(MapEntry(
              fileFieldName,
              await MultipartFile.fromFile(filePath),
            ));
          } catch (e) {
            // If fromFile fails (web), skip this file
            print('Warning: Could not add file from path on web: $filePath');
          }
        }
      }
      
      // Add named files (different field names)
      if (namedFiles != null && namedFiles.isNotEmpty) {
        for (final entry in namedFiles.entries) {
          try {
            formData.files.add(MapEntry(
              entry.key,
              await MultipartFile.fromFile(entry.value),
            ));
          } catch (e) {
            print('Warning: Could not add named file from path on web: ${entry.value}');
          }
        }
      }
      
      // Add named XFiles (Web compatible specific named fields)
      if (namedXFiles != null && namedXFiles.isNotEmpty) {
        for (final entry in namedXFiles.entries) {
          final bytes = await entry.value.readAsBytes();
          final String fileName = entry.value.name.isNotEmpty 
              ? (entry.value.name.contains('.') ? entry.value.name : '${entry.value.name}.jpg') 
              : 'image.jpg';
          formData.files.add(MapEntry(
            entry.key,
            MultipartFile.fromBytes(
              bytes, 
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            ),
          ));
        }
      }
      
      return await _dio.post(path, data: formData);
    } catch (e) {
      rethrow;
    }
  }

  // Update with multipart data (Web compatible)
  Future<Response> updateMultipartData(String path, Map<String, dynamic> data, {List<String>? filePaths, String fileFieldName = 'images', List<XFile>? xFiles}) async {
    try {
      final formData = FormData.fromMap(data);
      
      // Add XFile objects (web compatible)
      if (xFiles != null && xFiles.isNotEmpty) {
        for (final xFile in xFiles) {
          final bytes = await xFile.readAsBytes();
          final String fileName = xFile.name.isNotEmpty 
              ? (xFile.name.contains('.') ? xFile.name : '${xFile.name}.jpg') 
              : 'image.jpg';
          formData.files.add(MapEntry(
            fileFieldName,
            MultipartFile.fromBytes(
              bytes,
              filename: fileName,
              contentType: MediaType('image', 'jpeg'),
            ),
          ));
        }
      }
      // Fallback to file paths for mobile (if xFiles not provided)
      else if (filePaths != null && filePaths.isNotEmpty) {
        for (final filePath in filePaths) {
          try {
            formData.files.add(MapEntry(
              fileFieldName,
              await MultipartFile.fromFile(filePath),
            ));
          } catch (e) {
            print('Warning: Could not add file from path on web: $filePath');
          }
        }
      }
      
      return await _dio.put(path, data: formData);
    } catch (e) {
      rethrow;
    }
  }
}
