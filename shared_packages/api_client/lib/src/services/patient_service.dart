import 'package:api_client/api_client.dart';

class PatientService {
  final ApiClient _apiClient;

  PatientService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Create a booking/appointment
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await _apiClient.post('/patient/bookings', data: bookingData);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create booking');
      }
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  /// Get patient's bookings
  Future<List<Map<String, dynamic>>> getBookings({
    String? status,
    String? serviceType,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'status': status ?? 'all',
        'serviceType': serviceType ?? 'all',
      };

      final response = await _apiClient.get('/patient/bookings', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch bookings');
      }
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }
  
  /// Get active bookings
  Future<List<Map<String, dynamic>>> getActiveBookings({
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      final response = await _apiClient.get('/patient/bookings/active', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get booking details by ID
  Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    try {
      final response = await _apiClient.get('/patient/bookings/$bookingId');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch booking details');
      }
    } catch (e) {
      throw Exception('Failed to fetch booking details: $e');
    }
  }

  /// Cancel a booking
  Future<bool> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final data = <String, dynamic>{};
      if (reason != null) data['reason'] = reason;

      final response = await _apiClient.put('/patient/bookings/$bookingId/cancel', data: data);
      
      return response.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  /// Search for doctors
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
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null) queryParams['search'] = search;
      if (specialization != null) queryParams['specialization'] = specialization;
      if (city != null) queryParams['city'] = city;
      if (isAvailable != null) queryParams['isAvailable'] = isAvailable.toString();
      if (consultationType != null) queryParams['consultationType'] = consultationType;

      final response = await _apiClient.get('/patient/search/doctors', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search doctors');
      }
    } catch (e) {
      throw Exception('Failed to search doctors: $e');
    }
  }

  /// Search for nurses
  Future<Map<String, dynamic>> searchNurses({
    String? search,
    String? specialization,
    String? city,
    bool? isAvailable,
    String? consultationType, // NEW: Filter by consultation type
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null) queryParams['search'] = search;
      if (specialization != null) queryParams['specialization'] = specialization;
      if (city != null) queryParams['city'] = city;
      if (isAvailable != null) queryParams['isAvailable'] = isAvailable.toString();
      if (consultationType != null) queryParams['consultationType'] = consultationType;

      final response = await _apiClient.get('/patient/search/nurses', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search nurses');
      }
    } catch (e) {
      throw Exception('Failed to search nurses: $e');
    }
  }

  /// Get doctor availability
  Future<Map<String, dynamic>> getDoctorAvailability(String doctorId, {DateTime? date}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (date != null) {
        queryParams['date'] = date.toIso8601String().split('T')[0]; // YYYY-MM-DD format
      }

      final response = await _apiClient.get('/patient/doctors/$doctorId/availability', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch doctor availability');
      }
    } catch (e) {
      throw Exception('Failed to fetch doctor availability: $e');
    }
  }

  /// Search for medicines
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
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null) queryParams['search'] = search;
      if (category != null) queryParams['category'] = category;
      if (minPrice != null) queryParams['minPrice'] = minPrice;
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice;
      if (requiresPrescription != null) queryParams['requiresPrescription'] = requiresPrescription.toString();
      if (inStock != null) queryParams['inStock'] = inStock.toString();

      final response = await _apiClient.get('/patient/search/medicines', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search medicines');
      }
    } catch (e) {
      throw Exception('Failed to search medicines: $e');
    }
  }

  /// Search for ambulances within radius
  Future<Map<String, dynamic>> searchAmbulances({
    double? latitude,
    double? longitude,
    int? maxDistance,
    String? vehicleType,
    bool? isAvailable,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (maxDistance != null) queryParams['maxDistance'] = maxDistance;
      if (vehicleType != null) queryParams['vehicleType'] = vehicleType;
      if (isAvailable != null) queryParams['isAvailable'] = isAvailable.toString();

      final response = await _apiClient.get('/patient/search/ambulances', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search ambulances');
      }
    } catch (e) {
      throw Exception('Failed to search ambulances: $e');
    }
  }

  /// Search for blood banks
  Future<Map<String, dynamic>> searchBloodBanks({
    String? search,
    String? bloodGroup,
    String? city,
    double? latitude,
    double? longitude,
    int? maxDistance,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null) queryParams['search'] = search;
      if (bloodGroup != null) queryParams['bloodGroup'] = bloodGroup;
      if (city != null) queryParams['city'] = city;
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (maxDistance != null) queryParams['maxDistance'] = maxDistance;

      final response = await _apiClient.get('/patient/search/bloodbanks', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search blood banks');
      }
    } catch (e) {
      throw Exception('Failed to search blood banks: $e');
    }
  }

  /// Search for pathology labs
  Future<Map<String, dynamic>> searchPathologyLabs({
    String? search,
    String? city,
    String? testType,
    bool? homeCollectionAvailable,
    double? latitude,
    double? longitude,
    int? maxDistance,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (search != null) queryParams['search'] = search;
      if (city != null) queryParams['city'] = city;
      if (testType != null) queryParams['testType'] = testType;
      if (homeCollectionAvailable != null) queryParams['homeCollectionAvailable'] = homeCollectionAvailable.toString();
      if (latitude != null) queryParams['latitude'] = latitude;
      if (longitude != null) queryParams['longitude'] = longitude;
      if (maxDistance != null) queryParams['maxDistance'] = maxDistance;

      final response = await _apiClient.get('/patient/search/labs', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to search pathology labs');
      }
    } catch (e) {
      throw Exception('Failed to search pathology labs: $e');
    }
  }

  /// Get medicine details by ID
  Future<Map<String, dynamic>> getMedicineById(String medicineId) async {
    try {
      final response = await _apiClient.get('/patient/medicines/$medicineId');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch medicine details');
      }
    } catch (e) {
      throw Exception('Failed to fetch medicine details: $e');
    }
  }

  /// Create emergency booking (ambulance)
  Future<Map<String, dynamic>> createEmergencyBooking({
    required double latitude,
    required double longitude,
    required String address,
    String? notes,
    String? contactNumber,
  }) async {
    try {
      final bookingData = {
        'serviceType': 'ambulance',
        'location': {
          'coordinates': [longitude, latitude],
          'address': address,
        },
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'isEmergency': true,
        if (notes != null) 'notes': notes,
        if (contactNumber != null) 'contactNumber': contactNumber,
      };

      return await createBooking(bookingData);
    } catch (e) {
      throw Exception('Failed to create emergency booking: $e');
    }
  }

  /// Trigger emergency (uses /patient/emergency endpoint)
  Future<Map<String, dynamic>> triggerEmergency({
    required Map<String, dynamic> location,
    String? address,
    String? notes,
    String? type,
  }) async {
    try {
      final data = {
        'location': location,
        if (address != null) 'address': address,
        if (notes != null) 'notes': notes,
        if (type != null) 'type': type,
      };

      final response = await _apiClient.post('/patient/emergency', data: data);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to trigger emergency');
      }
    } catch (e) {
      throw Exception('Failed to trigger emergency: $e');
    }
  }

  /// Rate a service/provider
  Future<bool> rateService({
    required String bookingId,
    required int rating,
    String? review,
  }) async {
    try {
      final data = {
        'rating': rating,
        if (review != null) 'review': review,
      };

      final response = await _apiClient.post('/patient/bookings/$bookingId/rate', data: data);
      
      return response.data['success'] == true;
    } catch (e) {
      throw Exception('Failed to rate service: $e');
    }
  }
  
  // ============================================
  // REALTIME BOOKING METHODS
  // ============================================
  
  /// Create instant/realtime booking request
  /// Notifies nearby providers who can accept the request
  Future<Map<String, dynamic>> createRealtimeBooking(Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.post('/realtime/create', data: data);
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to create realtime booking');
      }
    } catch (e) {
      throw Exception('Failed to create realtime booking: $e');
    }
  }
  
  /// Get my realtime bookings
  Future<Map<String, dynamic>> getMyRealtimeBookings({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'status': status ?? 'all',
        'serviceType': 'all',
      };

      final response = await _apiClient.get('/patient/bookings', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch bookings');
      }
    } catch (e) {
      throw Exception('Failed to fetch bookings: $e');
    }
  }
  
  /// Get realtime booking details
  Future<Map<String, dynamic>> getRealtimeBookingDetails(String bookingId) async {
    try {
      final response = await _apiClient.get('/realtime-bookings/$bookingId');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch booking details');
      }
    } catch (e) {
      throw Exception('Failed to fetch booking details: $e');
    }
  }
  
  /// Cancel realtime booking
  Future<void> cancelRealtimeBooking(String bookingId, {required String reason}) async {
    try {
      final response = await _apiClient.post('/realtime-bookings/$bookingId/cancel', data: {
        'reason': reason,
      });
      
      if (response.data['success'] != true) {
        throw Exception(response.data['message'] ?? 'Failed to cancel booking');
      }
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }
  
  /// Get patient dashboard for realtime bookings
  Future<Map<String, dynamic>> getRealtimeBookingDashboard() async {
    try {
      final response = await _apiClient.get('/realtime-bookings/patient/dashboard');
      
      if (response.data['success'] == true) {
        return response.data['data'];
      } else {
        throw Exception(response.data['message'] ?? 'Failed to fetch dashboard');
      }
    } catch (e) {
      throw Exception('Failed to fetch dashboard: $e');
    }
  }

  /// Get medicine orders for patient (from bookings with serviceType=pharmacist)
  Future<List<Map<String, dynamic>>> getMedicineOrders({
    int page = 1,
    int limit = 50,
    String? status,
  }) async {
    try {
      // Medicine orders are in /patient/bookings with serviceType=pharmacist
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'status': status ?? 'all',
        'serviceType': 'pharmacist',
      };

      final response = await _apiClient.get('/patient/bookings', queryParameters: queryParams);
      
      if (response.data['success'] == true) {
        final data = response.data['data'];
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        }
        return [];
      }
      return [];
    } catch (e) {
      // Return empty list instead of throwing
      return [];
    }
  }
}

