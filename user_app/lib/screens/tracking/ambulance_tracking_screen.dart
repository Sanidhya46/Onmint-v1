import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:api_client/api_client.dart';

/// Patient-side ambulance tracking screen.
/// Shows the same 4-step stepper the driver progresses through,
/// with a live map and real-time status updates via Socket.IO.
class AmbulanceTrackingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const AmbulanceTrackingScreen({
    super.key,
    required this.bookingId,
    required this.bookingData,
  });

  @override
  State<AmbulanceTrackingScreen> createState() =>
      _AmbulanceTrackingScreenState();
}

class _AmbulanceTrackingScreenState extends State<AmbulanceTrackingScreen> {
  // ── Map ──────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  Position? _userPosition;
  LatLng? _ambulancePosition;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // ── Socket / API ─────────────────────────────────────────────────
  final _socketService = SocketService();
  final _apiClient = OnMintApiClient();
  StreamSubscription? _locationSub;
  StreamSubscription? _statusSub;

  // ── Booking state ────────────────────────────────────────────────
  Map<String, dynamic>? _booking;
  String _currentStatus = 'accepted';
  double _distance = 0.0;
  String _eta = 'Calculating...';

  // Step timestamps
  DateTime? _acceptedAt;
  DateTime? _onTheWayAt;
  DateTime? _atPickupAt;
  DateTime? _atDropAt;

  // ── Polling ──────────────────────────────────────────────────────
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    _statusSub?.cancel();
    _pollTimer?.cancel();
    _socketService.leaveBooking(widget.bookingId);
    _mapController?.dispose();
    super.dispose();
  }

  // ── Initialise ───────────────────────────────────────────────────

  Future<void> _init() async {
    await _apiClient.initialize();
    await _getUserLocation();
    await _loadBooking();
    _startSocketTracking();
    // Poll every 10 sec for status updates as fallback
    _pollTimer =
        Timer.periodic(const Duration(seconds: 10), (_) => _loadBooking());
  }

  Future<void> _getUserLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (mounted) {
        setState(() {
          _userPosition = position;
          _updateMarkers();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadBooking() async {
    try {
      // Use patient booking API to get booking details
      final response = await _apiClient.get(
        '/patient/bookings/${widget.bookingId}',
      );
      final data = response.data?['data'] ?? response.data;
      if (data == null || !mounted) return;
      setState(() {
        _booking = data;
        _currentStatus = data['status'] ?? 'accepted';
        _parseTimestamps(data);
      });
    } catch (_) {
      // Fallback: use bookingData passed in
      if (mounted && _booking == null) {
        setState(() {
          _booking = widget.bookingData;
          _currentStatus = widget.bookingData['status'] ?? 'accepted';
          _parseTimestamps(widget.bookingData);
        });
      }
    }
  }

  void _parseTimestamps(Map<String, dynamic> data) {
    if (data['acceptedAt'] != null) {
      _acceptedAt = DateTime.tryParse(data['acceptedAt'].toString());
    }
    if (data['onTheWayAt'] != null) {
      _onTheWayAt = DateTime.tryParse(data['onTheWayAt'].toString());
    } else if (data['startTime'] != null) {
      _onTheWayAt = DateTime.tryParse(data['startTime'].toString());
    }
    if (data['atPickupAt'] != null) {
      _atPickupAt = DateTime.tryParse(data['atPickupAt'].toString());
    }
    if (data['atDropAt'] != null) {
      _atDropAt = DateTime.tryParse(data['atDropAt'].toString());
    } else if (data['endTime'] != null) {
      _atDropAt = DateTime.tryParse(data['endTime'].toString());
    }
  }

  void _startSocketTracking() {
    final token = _apiClient.token ?? '';
    _socketService.connect(token);
    _socketService.joinBooking(widget.bookingId);

    // Live location from ambulance
    _locationSub = _socketService.locationUpdates.listen((data) {
      if (data['bookingId'] == widget.bookingId) {
        if (!mounted) return;
        setState(() {
          _ambulancePosition = LatLng(
            (data['latitude'] as num).toDouble(),
            (data['longitude'] as num).toDouble(),
          );
          _updateMarkers();
          _updateRoute();
          _calcETA();
        });
      }
    });

    // Status updates from ambulance driver actions
    _statusSub = _socketService.statusUpdates.listen((data) {
      if (data['bookingId'] == widget.bookingId) {
        if (!mounted) return;
        final newStatus = data['status'] as String?;
        if (newStatus != null) {
          setState(() => _currentStatus = newStatus);
          _loadBooking(); // refresh timestamps
        }
      }
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────

  String _fmt(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('hh:mm a').format(dt.toLocal());
  }

  int get _currentStep {
    switch (_currentStatus) {
      case 'accepted':
        return 0;
      case 'on_the_way':
        return 1;
      case 'in_progress':
        return 2;
      case 'completed':
        return 3;
      default:
        return 0;
    }
  }

  bool get _isCompleted => _currentStatus == 'completed';

  void _updateMarkers() {
    _markers.clear();
    if (_userPosition != null) {
      _markers.add(Marker(
        markerId: const MarkerId('user'),
        position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
        infoWindow:
            const InfoWindow(title: 'Your Location', snippet: 'Pickup point'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ));
    }
    if (_ambulancePosition != null) {
      _markers.add(Marker(
        markerId: const MarkerId('ambulance'),
        position: _ambulancePosition!,
        infoWindow: InfoWindow(
          title: 'Ambulance',
          snippet: _booking?['provider']?['vehicleNumber'] ?? 'On the way',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        rotation: _calcBearing(),
      ));
    }
  }

  void _updateRoute() {
    if (_ambulancePosition == null || _userPosition == null) return;
    _polylines.clear();
    _polylines.add(Polyline(
      polylineId: const PolylineId('route'),
      points: [
        _ambulancePosition!,
        LatLng(_userPosition!.latitude, _userPosition!.longitude),
      ],
      color: const Color(0xFFE52329),
      width: 4,
      geodesic: true,
    ));
  }

  void _calcETA() {
    if (_ambulancePosition == null || _userPosition == null) return;
    _distance = Geolocator.distanceBetween(
          _ambulancePosition!.latitude,
          _ambulancePosition!.longitude,
          _userPosition!.latitude,
          _userPosition!.longitude,
        ) /
        1000;
    final mins = (_distance / 40 * 60).round();
    if (mounted) {
      setState(() {
        _eta = mins < 1 ? 'Less than 1 min' : '$mins min';
      });
    }
  }

  double _calcBearing() {
    if (_ambulancePosition == null || _userPosition == null) return 0;
    return Geolocator.bearingBetween(
      _ambulancePosition!.latitude,
      _ambulancePosition!.longitude,
      _userPosition!.latitude,
      _userPosition!.longitude,
    );
  }

  Future<void> _callDriver() async {
    final phone = _booking?['provider']?['phone'];
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  // ── Build ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Ambulance Booking',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // ── Completed Banner ──────────────────────────────
                  if (_isCompleted) ...[
                    _buildCompletedBanner(),
                    const SizedBox(height: 12),
                  ],

                  // ── Patient Info Card ─────────────────────────────
                  _buildPatientCard(),
                  const SizedBox(height: 12),

                  // ── Route Card ────────────────────────────────────
                  _buildRouteCard(),
                  const SizedBox(height: 12),

                  // ── Status Stepper ────────────────────────────────
                  _buildStatusStepper(),
                  const SizedBox(height: 12),

                  // ── Action Shortcuts ──────────────────────────────
                  _buildActionShortcuts(),
                  const SizedBox(height: 12),

                  // ── Map (only when ambulance is on the way) ───────
                  if (_currentStatus == 'on_the_way' ||
                      _currentStatus == 'in_progress') ...[
                    _buildMapCard(),
                    const SizedBox(height: 12),
                  ],

                  // ── Thank you card ────────────────────────────────
                  if (_isCompleted) ...[
                    _buildThankYouCard(),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }

  // ── Completed Banner ──────────────────────────────────────────────

  Widget _buildCompletedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF81C784), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service Completed',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'You have reached the drop point.',
                style: TextStyle(color: Color(0xFF388E3C), fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Patient Card ──────────────────────────────────────────────────

  Widget _buildPatientCard() {
    final patient = _booking?['patient'] ?? widget.bookingData['patient'] ?? {};
    final firstName = patient['firstName'] ?? '';
    final lastName = patient['lastName'] ?? '';
    final fullName = patient['fullName'] ??
        (firstName.isNotEmpty ? '$firstName $lastName'.trim() : 'Patient');
    final gender = _booking?['patientGender'] ?? patient['gender'] ?? 'Female';
    final age = _booking?['patientAge'] ?? patient['age'] ?? '--';
    final address = _booking?['location']?['address'] ??
        widget.bookingData['address'] ??
        'Address not available';
    final price = ((_booking ?? widget.bookingData)['price'] ?? 0).toString();

    String formattedDate = '--';
    String formattedTime = '--';
    final raw = (_booking ?? widget.bookingData)['createdAt']?.toString();
    if (raw != null) {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(dt.toLocal());
        formattedTime = DateFormat('hh:mm a').format(dt.toLocal());
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFEDF2F7),
            ),
            child: const Icon(Icons.person, color: Colors.grey, size: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.female, size: 14, color: Colors.pink),
                    const SizedBox(width: 2),
                    Text('$gender  •  $age Years',
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 15, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(address,
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(formattedDate,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(formattedTime,
                      style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                ],
              ),
              const SizedBox(height: 8),
              Text('₹$price',
                  style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text('Service Fee',
                  style: TextStyle(color: Colors.grey[500], fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Route Card ────────────────────────────────────────────────────

  Widget _buildRouteCard() {
    final booking = _booking ?? widget.bookingData;
    final pickup = booking['location']?['address'] ??
        booking['pickupLocation']?['address'] ??
        widget.bookingData['address'] ??
        'Pickup not specified';
    final drop = booking['dropLocation']?['address'] ??
        booking['dropOffLocation']?['address'] ??
        widget.bookingData['dropOffLocation'] ??
        'Drop not specified';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Column(
              children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF4CAF50), size: 22),
                Expanded(
                  child: CustomPaint(
                    painter: _DashedLinePainter(),
                    child: const SizedBox(width: 2, height: double.infinity),
                  ),
                ),
                const Icon(Icons.location_on,
                    color: Color(0xFFE52329), size: 22),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pickup row — show Call button on completed
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Pickup Point',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(pickup,
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 13)),
                          ],
                        ),
                      ),
                      if (_isCompleted) _buildCallChip(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Drop row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Drop Point',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 4),
                            Text(drop,
                                style: TextStyle(
                                    color: Colors.grey[700], fontSize: 13)),
                          ],
                        ),
                      ),
                      if (_isCompleted) _buildCallChip(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallChip() {
    return GestureDetector(
      onTap: _callDriver,
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.phone, color: Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(height: 4),
          Text('Call', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ── Status Stepper ────────────────────────────────────────────────

  Widget _buildStatusStepper() {
    final steps = [
      _StepData(
        label: 'Accepted',
        time: _acceptedAt != null ? _fmt(_acceptedAt) : 'Just Now',
        isActive: _currentStep >= 0,
      ),
      _StepData(
        label: 'On The Way',
        time: _fmt(_onTheWayAt),
        isActive: _currentStep >= 1,
      ),
      _StepData(
        label: 'At Pickup Point',
        time: _fmt(_atPickupAt),
        isActive: _currentStep >= 2,
      ),
      _StepData(
        label: 'At Drop Point',
        time: _fmt(_atDropAt),
        isActive: _currentStep >= 3,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Circles + connecting lines
          Row(
            children: List.generate(steps.length * 2 - 1, (i) {
              if (i.isOdd) {
                final leftActive = steps[i ~/ 2].isActive;
                final rightActive = steps[(i ~/ 2) + 1].isActive;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: (leftActive && rightActive)
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFE0E0E0),
                  ),
                );
              } else {
                return _buildStepCircle(steps[i ~/ 2].isActive);
              }
            }),
          ),
          const SizedBox(height: 8),
          // Labels + times
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.map((step) {
              return SizedBox(
                width: 60,
                child: Column(
                  children: [
                    Text(
                      step.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: step.isActive
                            ? const Color(0xFF4CAF50)
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step.time,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(bool isActive) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? const Color(0xFF4CAF50) : Colors.white,
        border: Border.all(
          color: isActive ? const Color(0xFF4CAF50) : const Color(0xFFBDBDBD),
          width: 2,
        ),
      ),
      child: isActive
          ? const Icon(Icons.check, color: Colors.white, size: 16)
          : null,
    );
  }

  // ── Action Shortcuts ──────────────────────────────────────────────

  Widget _buildActionShortcuts() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _shortcut(Icons.phone, 'Call Driver', _callDriver),
          _shortcut(Icons.chat_bubble_outline, 'Chat', () {}),
          _shortcut(Icons.map_outlined, 'Open Map', _openMaps),
          _shortcut(
              Icons.description_outlined, 'Trip Details', _showTripDetails),
        ],
      ),
    );
  }

  Widget _shortcut(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F1FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 24),
          ),
          const SizedBox(height: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Future<void> _openMaps() async {
    final booking = _booking ?? widget.bookingData;
    final coords = booking['location']?['coordinates'];
    if (coords == null || coords.length < 2) return;
    final lat = coords[1];
    final lng = coords[0];
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showTripDetails() {
    final booking = _booking ?? widget.bookingData;
    final patient = booking['patient'] ?? {};
    final fullName = patient['fullName'] ??
        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final phone = patient['phone'] ?? 'N/A';
    final gender = booking['patientGender'] ?? patient['gender'] ?? '--';
    final age = booking['patientAge'] ?? patient['age'] ?? '--';
    final price = (booking['price'] ?? 0).toString();

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Trip Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            _detailRow('Patient', fullName),
            _detailRow('Phone', phone),
            _detailRow('Gender / Age', '$gender / $age years'),
            _detailRow('Service Fee', '₹$price'),
            _detailRow('Status', _currentStatus.toUpperCase()),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Map Card ──────────────────────────────────────────────────────

  Widget _buildMapCard() {
    final initialTarget = _userPosition != null
        ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
        : const LatLng(20.5937, 78.9629);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition:
                CameraPosition(target: initialTarget, zoom: 15),
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (c) {
              _mapController = c;
              if (_userPosition != null) {
                c.animateCamera(CameraUpdate.newLatLng(initialTarget));
              }
            },
          ),
          // ETA pill
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: Color(0xFFE52329)),
                  const SizedBox(width: 4),
                  Text(
                    'ETA: $_eta',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFFE52329)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Thank You Card ────────────────────────────────────────────────

  Widget _buildThankYouCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Thank you!',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 4),
                Text('You have completed the service successfully.',
                    style: TextStyle(color: Colors.black87, fontSize: 13)),
                SizedBox(height: 4),
                Text('Payment will be transferred shortly.',
                    style: TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared helper classes ─────────────────────────────────────────

class _StepData {
  final String label;
  final String time;
  final bool isActive;
  _StepData({required this.label, required this.time, required this.isActive});
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const dashHeight = 5.0;
    const dashSpace = 4.0;
    final paint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 2;
    double startY = 0;
    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
