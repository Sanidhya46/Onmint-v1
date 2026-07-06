import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:async';

/// Socket.IO service for real-time communication
/// Handles connection, room management, and event listeners
class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Event stream controllers
  final _locationUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _statusUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController = StreamController<Map<String, dynamic>>.broadcast();
  final _doctorJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _patientJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _consultationEndedController = StreamController<Map<String, dynamic>>.broadcast();

  // Getters for streams
  Stream<Map<String, dynamic>> get locationUpdates => _locationUpdateController.stream;
  Stream<Map<String, dynamic>> get statusUpdates => _statusUpdateController.stream;
  Stream<Map<String, dynamic>> get notifications => _notificationController.stream;
  Stream<Map<String, dynamic>> get doctorJoined => _doctorJoinedController.stream;
  Stream<Map<String, dynamic>> get patientJoined => _patientJoinedController.stream;
  Stream<Map<String, dynamic>> get consultationEnded => _consultationEndedController.stream;

  bool get isConnected => _isConnected;

  /// Connect to Socket.IO server
  void connect(String token, {String? baseUrl}) {
    if (_socket != null && _isConnected) {
      print('Socket already connected');
      return;
    }

    String socketUrl = baseUrl ?? 'https://api.onmint.in';
    if (baseUrl == null) {
      if (kIsWeb) {
        socketUrl = 'http://localhost:5000';
      } else {
        try {
          if (Platform.isAndroid) {
            socketUrl = 'http://10.0.2.2:5000';
          } else {
            socketUrl = 'http://localhost:5000';
          }
        } catch (_) {
          socketUrl = 'http://localhost:5000';
        }
      }
    }

    _socket = IO.io(socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'auth': {
        'token': token,
      },
    });

    _socket!.on('connect', (_) {
      print('✅ Socket connected');
      _isConnected = true;
    });

    _socket!.on('disconnect', (_) {
      print('❌ Socket disconnected');
      _isConnected = false;
    });

    _socket!.on('error', (data) {
      print('⚠️ Socket error: $data');
    });

    // Listen for location updates
    _socket!.on('location:updated', (data) {
      if (data is Map<String, dynamic>) {
        _locationUpdateController.add(data);
      }
    });

    // Listen for status updates
    _socket!.on('booking:status:updated', (data) {
      if (data is Map<String, dynamic>) {
        _statusUpdateController.add(data);
      }
    });

    // Listen for notifications
    _socket!.on('notification', (data) {
      if (data is Map<String, dynamic>) {
        _notificationController.add(data);
      }
    });

    // Video call tracking events
    _socket!.on('call:doctor_joined', (data) {
      if (data is Map<String, dynamic>) {
        _doctorJoinedController.add(data);
      }
    });

    _socket!.on('call:patient_joined', (data) {
      if (data is Map<String, dynamic>) {
        _patientJoinedController.add(data);
      }
    });

    _socket!.on('call:consultation_ended', (data) {
      if (data is Map<String, dynamic>) {
        _consultationEndedController.add(data);
      }
    });
  }

  /// Disconnect from Socket.IO server
  void disconnect() {
    _socket?.disconnect();
    _socket = null;
    _isConnected = false;
  }

  /// Join a booking room for real-time updates
  void joinBooking(String bookingId) {
    if (!_isConnected) {
      return;
    }
    _socket?.emit('join:booking', bookingId);
  }

  /// Leave a booking room
  void leaveBooking(String bookingId) {
    if (!_isConnected) return;
    _socket?.emit('leave:booking', bookingId);
  }

  /// Update location (for providers: ambulance, doctor, nurse)
  void updateLocation({
    required String bookingId,
    required double latitude,
    required double longitude,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot update location: Socket not connected');
      return;
    }
    
    _socket?.emit('location:update', {
      'bookingId': bookingId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    print('📍 Location updated: $latitude, $longitude');
  }

  /// Update booking status
  void updateStatus({
    required String bookingId,
    required String status,
    String? message,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot update status: Socket not connected');
      return;
    }
    
    _socket?.emit('booking:status:update', {
      'bookingId': bookingId,
      'status': status,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    print('📊 Status updated: $status');
  }

  /// Send a message in booking chat
  void sendMessage({
    required String bookingId,
    required String message,
  }) {
    if (!_isConnected) {
      print('⚠️ Cannot send message: Socket not connected');
      return;
    }
    
    _socket?.emit('message:send', {
      'bookingId': bookingId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Dispose resources
  void dispose() {
    _locationUpdateController.close();
    _statusUpdateController.close();
    _notificationController.close();
    disconnect();
  }
}
