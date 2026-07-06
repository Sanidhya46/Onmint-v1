import 'user_model.dart';

class BookingTimeSlot {
  final String startTime;
  final String endTime;
  final bool isAvailable;

  BookingTimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
  });

  factory BookingTimeSlot.fromJson(Map<String, dynamic> json) {
    return BookingTimeSlot(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isAvailable': isAvailable,
    };
  }
}

class Booking {
  final String id;
  final String patient;
  final String provider;
  final User? patientDetails;
  final User? providerDetails;
  final String serviceType;
  final String status;
  final DateTime scheduledTime;
  final BookingLocation location;
  final BookingTimeSlot? timeSlot;
  final String? notes;
  final double price;
  final Rating? rating;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? cancellationReason;
  final DateTime? cancelledAt;
  final bool isEmergency;
  final String? bloodGroup;
  final int? unitsRequired;
  final List<Map<String, dynamic>>? tests;
  final String? consultationType;
  final String? urgency;
  final String? videoCallLink;
  final dynamic prescription;
  final bool videoCallCompleted;
  final String? report;
  final DateTime? reportUploadedAt;
  final bool collectionScheduled;
  final bool doctorOnCall;
  final bool patientOnCall;
  final bool consultationEnded;
  final DateTime? consultationEndedAt;
  final Map<String, dynamic>? rawData; // Preserve original JSON

  Booking({
    required this.id,
    required this.patient,
    required this.provider,
    this.patientDetails,
    this.providerDetails,
    required this.serviceType,
    required this.status,
    required this.scheduledTime,
    required this.location,
    this.timeSlot,
    this.notes,
    required this.price,
    this.rating,
    required this.createdAt,
    required this.updatedAt,
    this.cancellationReason,
    this.cancelledAt,
    this.isEmergency = false,
    this.bloodGroup,
    this.unitsRequired,
    this.tests,
    this.consultationType,
    this.urgency,
    this.videoCallLink,
    this.prescription,
    this.videoCallCompleted = false,
    this.report,
    this.reportUploadedAt,
    this.collectionScheduled = false,
    this.doctorOnCall = false,
    this.patientOnCall = false,
    this.consultationEnded = false,
    this.consultationEndedAt,
    this.rawData,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    try {
      // Handle provider field - can be String (ID or phone), Map (full object), or null
      String providerId = '';
      User? providerDetails;
      
      // First check if providerDetails exists as a separate field (populated by backend)
      if (json['providerDetails'] != null && json['providerDetails'] is Map<String, dynamic>) {
        try {
          providerDetails = User.fromJson(json['providerDetails'] as Map<String, dynamic>);
          providerId = providerDetails.id;
        } catch (e) {
          print('Error parsing providerDetails: $e');
        }
      }
      
      // Then check provider field
      final providerValue = json['provider'];
      if (providerValue is String) {
        // Could be ID or phone number - just store as string
        if (providerId.isEmpty) {
          providerId = providerValue;
        }
      } else if (providerValue is Map<String, dynamic>) {
        try {
          if (providerId.isEmpty) {
            providerId = providerValue['_id'] ?? providerValue['id'] ?? '';
          }
          if (providerDetails == null) {
            providerDetails = User.fromJson(providerValue);
          }
        } catch (e) {
          print('Error parsing provider map: $e');
        }
      }
      
      // Handle patient field - can be String or Map
      String patientId = '';
      User? patientDetails;
      
      // First check if patientDetails exists as a separate field
      if (json['patientDetails'] != null && json['patientDetails'] is Map<String, dynamic>) {
        try {
          patientDetails = User.fromJson(json['patientDetails'] as Map<String, dynamic>);
          patientId = patientDetails.id;
        } catch (e) {
          print('Error parsing patientDetails: $e');
        }
      }
      
      // Then check patient field
      final patientValue = json['patient'];
      if (patientValue is String) {
        if (patientId.isEmpty) {
          patientId = patientValue;
        }
      } else if (patientValue is Map<String, dynamic>) {
        try {
          if (patientId.isEmpty) {
            patientId = patientValue['_id'] ?? patientValue['id'] ?? '';
          }
          if (patientDetails == null) {
            patientDetails = User.fromJson(patientValue);
          }
        } catch (e) {
          print('Error parsing patient map: $e');
        }
      }
      
      // Handle location field - can be String, Map, or null
      BookingLocation location;
      final locationValue = json['location'];
      if (locationValue is Map<String, dynamic>) {
        try {
          location = BookingLocation.fromJson(locationValue);
        } catch (e) {
          print('Error parsing location map: $e');
          location = BookingLocation(address: 'No address provided');
        }
      } else if (locationValue is String) {
        location = BookingLocation(address: locationValue);
      } else {
        location = BookingLocation(address: 'No address provided');
      }
      
      // Handle timeSlot field - can be String, Map, or null
      BookingTimeSlot? timeSlot;
      final timeSlotValue = json['timeSlot'];
      if (timeSlotValue is Map<String, dynamic>) {
        try {
          timeSlot = BookingTimeSlot.fromJson(timeSlotValue);
        } catch (e) {
          print('Error parsing timeSlot: $e');
          timeSlot = null;
        }
      }
      
      // Handle rating field - can be int, Map, or null
      Rating? rating;
      final ratingValue = json['rating'];
      if (ratingValue is Map<String, dynamic>) {
        try {
          rating = Rating.fromJson(ratingValue);
        } catch (e) {
          print('Error parsing rating: $e');
          rating = null;
        }
      }
      
      // Handle tests field for pathology bookings
      List<Map<String, dynamic>>? tests;
      if (json['tests'] != null && json['tests'] is List) {
        tests = List<Map<String, dynamic>>.from(
          (json['tests'] as List).map((test) {
            if (test is Map<String, dynamic>) {
              return test;
            } else if (test is Map) {
              return Map<String, dynamic>.from(test);
            }
            return <String, dynamic>{};
          }),
        );
      }
      
      return Booking(
        id: json['_id'] ?? json['id'] ?? '',
        patient: patientId,
        provider: providerId,
        patientDetails: patientDetails,
        providerDetails: providerDetails,
        serviceType: json['serviceType'] ?? '',
        status: json['status'] ?? '',
        scheduledTime: _parseDateTime(json['scheduledTime']),
        location: location,
        timeSlot: timeSlot,
        notes: json['notes'],
        price: _parseDouble(json['price'] ?? json['fees'] ?? json['totalAmount'] ?? json['amount']),
        rating: rating,
        createdAt: _parseDateTime(json['createdAt']),
        updatedAt: _parseDateTime(json['updatedAt']),
        cancellationReason: json['cancellationReason'],
        cancelledAt: json['cancelledAt'] != null ? DateTime.parse(json['cancelledAt'].toString()) : null,
        isEmergency: json['isEmergency'] == true || json['isEmergency'] == 'true',
        bloodGroup: json['bloodGroup']?.toString(),
        unitsRequired: _parseInt(json['unitsRequired']),
        tests: tests,
        consultationType: json['consultationType']?.toString(),
        urgency: json['urgency']?.toString(),
        videoCallLink: json['videoCallLink']?.toString(),
        prescription: json['prescription'],
        videoCallCompleted: json['videoCallCompleted'] == true || json['videoCallCompleted'] == 'true',
        report: json['report']?.toString(),
        reportUploadedAt: json['reportUploadedAt'] != null ? DateTime.parse(json['reportUploadedAt'].toString()) : null,
        collectionScheduled: json['collectionScheduled'] == true || json['collectionScheduled'] == 'true',
        doctorOnCall: json['doctor_on_call'] == true,
        patientOnCall: json['patient_on_call'] == true,
        consultationEnded: json['consultation_ended'] == true,
        consultationEndedAt: json['consultation_ended_at'] != null ? DateTime.parse(json['consultation_ended_at'].toString()) : null,
        rawData: Map<String, dynamic>.from(json),
      );
    } catch (e, stack) {
      print('Error parsing booking: $e');
      print('Booking JSON: $json');
      rethrow;
    }
  }
  
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        print('Error parsing datetime string: $value');
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'patient': patient,
      'provider': provider,
      'serviceType': serviceType,
      'scheduledTime': scheduledTime.toIso8601String(),
      'location': location.toJson(),
      if (timeSlot != null) 'timeSlot': timeSlot!.toJson(),
      if (notes != null) 'notes': notes,
      'price': price,
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (unitsRequired != null) 'unitsRequired': unitsRequired,
      if (tests != null) 'tests': tests,
      if (consultationType != null) 'consultationType': consultationType,
      if (urgency != null) 'urgency': urgency,
      if (videoCallLink != null) 'videoCallLink': videoCallLink,
      if (prescription != null) 'prescription': prescription,
      'videoCallCompleted': videoCallCompleted,
      if (report != null) 'report': report,
      if (reportUploadedAt != null) 'reportUploadedAt': reportUploadedAt!.toIso8601String(),
      'collectionScheduled': collectionScheduled,
      'doctor_on_call': doctorOnCall,
      'patient_on_call': patientOnCall,
      'consultation_ended': consultationEnded,
      if (consultationEndedAt != null) 'consultation_ended_at': consultationEndedAt!.toIso8601String(),
    };
  }

  bool get isActive => ['requested', 'accepted', 'on_the_way', 'in_progress'].contains(status);
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get canBeCancelled => ['requested', 'accepted'].contains(status);
  bool get canBeRated => status == 'completed' && rating == null;
}

class BookingLocation {
  final String? address;
  final List<double>? coordinates;

  BookingLocation({
    this.address,
    this.coordinates,
  });

  factory BookingLocation.fromJson(Map<String, dynamic> json) {
    return BookingLocation(
      address: json['address'],
      coordinates: json['coordinates'] != null
          ? List<double>.from(json['coordinates'].map((x) => x.toDouble()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (address != null) 'address': address,
      if (coordinates != null) 'coordinates': coordinates,
    };
  }

  double? get longitude => coordinates != null && coordinates!.isNotEmpty ? coordinates![0] : null;
  double? get latitude => coordinates != null && coordinates!.length > 1 ? coordinates![1] : null;
}

class Rating {
  final int rating;
  final String? review;
  final DateTime? createdAt;

  Rating({
    required this.rating,
    this.review,
    this.createdAt,
  });

  factory Rating.fromJson(Map<String, dynamic> json) {
    return Rating(
      rating: json['rating'] ?? 0,
      review: json['review'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rating': rating,
      if (review != null) 'review': review,
    };
  }
}
