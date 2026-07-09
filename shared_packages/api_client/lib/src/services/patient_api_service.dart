import '../api_client_base.dart';
import '../models/models.dart';
import '../utils/response_handler.dart';
import 'package:dio/dio.dart';

class PatientApiService {
  final ApiClient _client;

  PatientApiService(this._client);

  // Search Services
  Future<Map<String, dynamic>> globalSearch(String query, {int page = 1, int limit = 20}) async {
    final response = await _client.get('/patient/search', queryParameters: {
      'query': query,
      'page': page,
      'limit': limit,
    });
    return response.data['data'];
  }

  Future<Map<String, dynamic>> searchDoctors({
    String? search,
    String? specialization,
    String? city,
    bool? isAvailable,
    String? consultationType, // NEW: Filter by consultation type
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get('/patient/search/doctors', queryParameters: {
        if (search != null) 'search': search,
        if (specialization != null) 'specialization': specialization,
        if (city != null) 'city': city,
        if (isAvailable != null) 'isAvailable': isAvailable.toString(),
        if (consultationType != null) 'consultationType': consultationType,
        'page': page,
        'limit': limit,
      });
      return ResponseHandler.extractPaginatedData(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> searchMedicines({
    String? search,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? requiresPrescription,
    bool? inStock,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _client.get('/patient/search/medicines', queryParameters: {
        if (search != null) 'search': search,
        if (category != null) 'category': category,
        if (minPrice != null) 'minPrice': minPrice,
        if (maxPrice != null) 'maxPrice': maxPrice,
        if (requiresPrescription != null) 'requiresPrescription': requiresPrescription.toString(),
        if (inStock != null) 'inStock': inStock.toString(),
        'page': page,
        'limit': limit,
      });
      return ResponseHandler.extractPaginatedData(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> searchPharmacies({String? city, int page = 1, int limit = 20}) async {
    final response = await _client.get('/patient/search/pharmacies', queryParameters: {
      if (city != null) 'city': city,
      'page': page,
      'limit': limit,
    });
    return response.data; // Return the full response
  }

  Future<Map<String, dynamic>> searchLabs({String? city, int page = 1, int limit = 20}) async {
    final response = await _client.get('/patient/search/labs', queryParameters: {
      if (city != null) 'city': city,
      'page': page,
      'limit': limit,
    });
    return response.data; // Return the full response
  }

  Future<Map<String, dynamic>> searchBloodBanks({
    String? bloodGroup,
    String? city,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _client.get('/patient/search/bloodbanks', queryParameters: {
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (city != null) 'city': city,
      'page': page,
      'limit': limit,
    });
    return response.data; // Return the full response
  }

  Future<List<User>> getNearbyServices({
    required double latitude,
    required double longitude,
    required String serviceType,
    double maxDistance = 10,
  }) async {
    final response = await _client.get('/patient/services/nearby', queryParameters: {
      'latitude': latitude,
      'longitude': longitude,
      'serviceType': serviceType,
      'maxDistance': maxDistance,
    });
    return (response.data['data'] as List).map((e) => User.fromJson(e)).toList();
  }

  // Bookings
  
  /// Create a booking
  /// For medicine orders (serviceType: 'pharmacist' or 'pharmacy'), 
  /// provider field is optional and will be assigned when a pharmacist accepts
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    try {
      final response = await _client.post('/patient/bookings', data: data);
      return ResponseHandler.extractData<Map<String, dynamic>>(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }

  Future<Map<String, dynamic>> getBookings({
    int page = 1,
    int limit = 10,
    String? status,
    String? serviceType,
  }) async {
    try {
      final response = await _client.get('/patient/bookings', queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
        if (serviceType != null) 'serviceType': serviceType,
      });
      if (response.data['success'] == true) {
        return response.data; // Return the full response with data and pagination
      }
      return {'data': [], 'pagination': {}};
    } catch (e) {
      print('Error fetching bookings: $e');
      return {'data': [], 'pagination': {}};
    }
  }

  // Alias for getBookings to support existing UI code
  Future<Map<String, dynamic>> getUserBookings({
    int page = 1,
    int limit = 10,
    String? status,
    String? serviceType,
  }) {
    return getBookings(
      page: page,
      limit: limit,
      status: status,
      serviceType: serviceType,
    );
  }

  Future<List<Booking>> getActiveBookings() async {
    try {
      final response = await _client.get('/patient/bookings/active');
      if (response.data['success'] == true && response.data['data'] != null) {
        return (response.data['data'] as List).map((e) => Booking.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching active bookings: $e');
      return [];
    }
  }

  Future<Booking> getBookingDetails(String bookingId) async {
    final response = await _client.get('/patient/bookings/$bookingId');
    return Booking.fromJson(response.data['data']);
  }

  Future<void> cancelBooking(String bookingId, {required String reason}) async {
    await _client.post('/patient/bookings/$bookingId/cancel', data: {
      'reason': reason,
    });
  }

  Future<void> rateBooking(String bookingId, {required int rating, String? review}) async {
    await _client.post('/patient/bookings/$bookingId/rate', data: {
      'rating': rating,
      if (review != null) 'review': review,
    });
  }

  /// Add rating/review for a completed booking
  Future<void> addRating(String bookingId, int rating, String? review) async {
    await _client.post('/patient/bookings/$bookingId/rate', data: {
      'rating': rating,
      if (review != null && review.isNotEmpty) 'review': review,
    });
  }

  // Emergency Services
  Future<Map<String, dynamic>> triggerEmergency({
    required Map<String, dynamic> location,
    required String address,
    String? notes,
    String? type, // 'doctor' or 'ambulance'
  }) async {
    final response = await _client.post('/patient/emergency', data: {
      'location': location,
      'address': address,
      if (notes != null) 'notes': notes,
      if (type != null) 'type': type,
    });
    // Return full response data including booking, ambulance/doctor, eta
    return response.data;
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final response = await _client.get('/patient/notifications', queryParameters: {
      'page': page,
      'limit': limit,
    });
    return response.data; // Return the full response
  }

  Future<int> getUnreadNotificationsCount() async {
    final response = await _client.get('/patient/notifications/unread-count');
    return response.data['data']['count'] ?? 0;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _client.post('/patient/notifications/$notificationId/read');
  }
  
  // Provider Details
  Future<Map<String, dynamic>> getNurseDetails(String nurseId) async {
    final response = await _client.get('/patient/nurses/$nurseId');
    return response.data['data'];
  }
  
  /// Get doctor availability schedule
  Future<Map<String, dynamic>> getDoctorAvailability(String doctorId, {DateTime? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date.toIso8601String();
      }
      
      final response = await _client.get(
        '/patient/doctors/$doctorId/availability',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }
  
  /// Get nurse availability schedule
  Future<Map<String, dynamic>> getNurseAvailability(String nurseId, {DateTime? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date.toIso8601String();
      }
      
      final response = await _client.get(
        '/patient/nurses/$nurseId/availability',
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }
  
  Future<Map<String, dynamic>> getPharmacyDetails(String pharmacyId) async {
    final response = await _client.get('/patient/pharmacies/$pharmacyId');
    return response.data['data'];
  }
  
  Future<Map<String, dynamic>> getBloodBankDetails(String bloodBankId) async {
    final response = await _client.get('/patient/bloodbanks/$bloodBankId');
    return response.data['data'];
  }
  
  Future<Map<String, dynamic>> getPathologyLabDetails(String labId) async {
    final response = await _client.get('/patient/labs/$labId');
    return response.data['data'];
  }
  
  // Profile Management
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _client.put('/auth/profile', data: data);
    return response.data['data'];
  }
  
  // Blood Request
  Future<Booking> createBloodRequest(Map<String, dynamic> data) async {
    final response = await _client.post('/patient/bookings', data: {
      ...data,
      'serviceType': 'bloodbank',
    });
    return Booking.fromJson(response.data['data']);
  }
  
  // Test Booking
  Future<Booking> createTestBooking(Map<String, dynamic> data) async {
    final response = await _client.post('/patient/bookings', data: {
      ...data,
      'serviceType': 'pathology',
    });
    return Booking.fromJson(response.data['data']);
  }
  
  // ============================================
  // REALTIME BOOKING ENDPOINTS
  // ============================================
  
  // Real-time Booking
  Future<dynamic> createRealtimeBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await _client.post('/realtime/create', data: bookingData);
      return ResponseHandler.extractData(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }

  // Cart
  Future<dynamic> syncCart(String serviceType, List<Map<String, dynamic>> items, {double? price}) async {
    try {
      final response = await _client.post('/realtime/cart/sync', data: {
        'serviceType': serviceType,
        'medicines': items,
        'price': price,
      });
      return ResponseHandler.extractData(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }

  Future<dynamic> getCart(String serviceType) async {
    try {
      final response = await _client.get('/realtime/cart', queryParameters: {
        'serviceType': serviceType,
      });
      return ResponseHandler.extractData(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }

  Future<dynamic> checkoutCart(String bookingId, Map<String, dynamic> checkoutData) async {
    try {
      final response = await _client.post('/realtime/$bookingId/checkout', data: checkoutData);
      return ResponseHandler.extractData(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }
  
  /// Get my realtime bookings
  Future<Map<String, dynamic>> getMyRealtimeBookings({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final response = await _client.get('/realtime/my-bookings', queryParameters: {
        'page': page,
        'limit': limit,
        if (status != null) 'status': status,
      });
      return ResponseHandler.extractPaginatedData(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }
  
  /// Get realtime booking details
  Future<Map<String, dynamic>> getRealtimeBookingDetails(String bookingId) async {
    try {
      final response = await _client.get('/realtime/$bookingId');
      return ResponseHandler.extractData<Map<String, dynamic>>(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }
  
  /// Cancel realtime booking
  Future<void> cancelRealtimeBooking(String bookingId, {required String reason}) async {
    try {
      await _client.post('/realtime-bookings/$bookingId/cancel', data: {
        'reason': reason,
      });
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }
  
  /// Get patient dashboard for realtime bookings
  Future<Map<String, dynamic>> getRealtimeBookingDashboard() async {
    try {
      final response = await _client.get('/realtime-bookings/patient/dashboard');
      return ResponseHandler.extractData<Map<String, dynamic>>(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }

  // ============================================
  // REGULAR BOOKING ENDPOINT (NEW - Added April 19, 2026)
  // ============================================
  
  /// Create regular/scheduled booking without document upload
  /// Use this for scheduled appointments that don't require immediate document upload
  /// For instant bookings with documents, use createBooking() or createRealtimeBooking()
  Future<Map<String, dynamic>> createRegularBooking({
    required String serviceType,
    required String providerId,
    required DateTime scheduledTime,
    required double price,
    required Map<String, dynamic> location,
    String? notes,
    String? consultationType,
    Map<String, String>? timeSlot,
  }) async {
    try {
      final response = await _client.post('/bookings', data: {
        'serviceType': serviceType,
        'provider': providerId,
        'scheduledTime': scheduledTime.toIso8601String(),
        'price': price,
        'location': location,
        if (notes != null) 'notes': notes,
        if (consultationType != null) 'consultationType': consultationType,
        if (timeSlot != null) 'timeSlot': timeSlot,
      });
      return ResponseHandler.extractData<Map<String, dynamic>>(response);
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }

  // ============================================
  // VIDEO CALL ENDPOINTS
  // ============================================

  /// Join video call (marks patient_on_call = true)
  Future<Map<String, dynamic>> joinVideoCall(String bookingId) async {
    try {
      final response = await _client.post('/video/room', data: {
        'bookingId': bookingId,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }

  /// Get real-time call status
  Future<Map<String, dynamic>> getCallStatus(String bookingId) async {
    try {
      final response = await _client.get('/video/call-status/$bookingId');
      return response.data['data'];
    } on DioException catch (e) {
      throw Exception(ResponseHandler.handleDioError(e));
    }
  }
}
