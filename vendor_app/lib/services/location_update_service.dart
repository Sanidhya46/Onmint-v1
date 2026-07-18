import 'package:geolocator/geolocator.dart';
import 'package:api_client/api_client.dart';
import 'dart:async';

/// Service to continuously update provider location to backend
/// Used by Ambulance, Doctor (home visit), Nurse (home visit)
class LocationUpdateService {
  static final LocationUpdateService _instance = LocationUpdateService._internal();
  factory LocationUpdateService() => _instance;
  LocationUpdateService._internal();

  Timer? _locationTimer;
  final _socketService = SocketService();
  String? _currentBookingId;
  bool _isUpdating = false;

  /// Start sending location updates for a booking
  Future<void> startLocationUpdates({
    required String bookingId,
    required String token,
    int intervalSeconds = 5,
  }) async {
    if (_isUpdating) {
      print('⚠️ Location updates already running');
      return;
    }

    _currentBookingId = bookingId;
    _isUpdating = true;

    // Connect to Socket.IO
    _socketService.connect(token);
    _socketService.joinBooking(bookingId);

    // Check location permission
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied || 
          requested == LocationPermission.deniedForever) {
        print('❌ Location permission denied');
        _isUpdating = false;
        return;
      }
    }

    print('✅ Starting location updates for booking: $bookingId');

    // Send initial location immediately
    await _sendCurrentLocation();

    // Start periodic updates
    _locationTimer = Timer.periodic(
      Duration(seconds: intervalSeconds),
      (timer) async {
        await _sendCurrentLocation();
      },
    );
  }

  /// Stop sending location updates
  void stopLocationUpdates() {
    if (!_isUpdating) return;

    _locationTimer?.cancel();
    _locationTimer = null;
    
    if (_currentBookingId != null) {
      _socketService.leaveBooking(_currentBookingId!);
    }
    
    _isUpdating = false;
    _currentBookingId = null;
    
    print('🛑 Location updates stopped');
  }

  /// Send current location to backend via Socket.IO
  Future<void> _sendCurrentLocation() async {
    final bookingId = _currentBookingId;
    if (bookingId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _socketService.updateLocation(
        bookingId: bookingId,
        latitude: position.latitude,
        longitude: position.longitude,
      );

      print('📍 Location sent: ${position.latitude}, ${position.longitude}');
    } catch (e) {
      // Silently swallow location errors - don't crash the app
      print('⚠️ Location update skipped: $e');
    }
  }

  /// Get current location once (without starting updates)
  Future<Position?> getCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('❌ Error getting location: $e');
      return null;
    }
  }

  /// Check if location updates are running
  bool get isUpdating => _isUpdating;

  /// Get current booking ID
  String? get currentBookingId => _currentBookingId;

  /// Dispose resources
  void dispose() {
    stopLocationUpdates();
  }
}
