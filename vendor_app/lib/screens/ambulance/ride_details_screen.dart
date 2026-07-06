import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/location_update_service.dart';

class RideDetailsScreen extends StatefulWidget {
  final String rideId;

  const RideDetailsScreen({
    super.key,
    required this.rideId,
  });

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  final _apiClient = OnMintApiClient();
  final _locationService = LocationUpdateService();
  Map<String, dynamic>? _ride;
  bool _isLoading = true;
  bool _isProcessing = false;

  /// Safely extract address string from any type (String, Map, int, etc.)
  String _safeAddress(dynamic addr, [String fallback = 'Not specified']) {
    if (addr == null) return fallback;
    if (addr is String) return addr.isEmpty ? fallback : addr;
    if (addr is Map) {
      // Try nested 'address' key, then build from parts
      if (addr['address'] != null) return addr['address'].toString();
      final parts = [
        addr['street']?.toString(),
        addr['city']?.toString(),
        addr['state']?.toString(),
      ].where((p) => p != null && p.isNotEmpty).toList();
      return parts.isNotEmpty ? parts.join(', ') : fallback;
    }
    return addr.toString();
  }

  // Step timestamps
  DateTime? _acceptedAt;
  DateTime? _onTheWayAt;
  DateTime? _atPickupAt;
  DateTime? _atDropAt;

  @override
  void initState() {
    super.initState();
    _loadRide();
  }

  @override
  void dispose() {
    if (_locationService.isUpdating) {
      _locationService.stopLocationUpdates();
    }
    super.dispose();
  }

  Future<void> _loadRide() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      final data = await _apiClient.ambulance.getRideDetails(widget.rideId);
      if (mounted) {
        setState(() {
          _ride = data;
          _isLoading = false;
          _parseTimestamps(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ride: $e')),
        );
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
    if (data['atDropAt'] != null || data['endTime'] != null) {
      _atDropAt = DateTime.tryParse(
          (data['atDropAt'] ?? data['endTime']).toString());
    }
  }

  String _fmt(DateTime? dt) {
    if (dt == null) return '--:--';
    return DateFormat('hh:mm a').format(dt.toLocal());
  }

  // ── Status helpers ──────────────────────────────────────────────

  String get _status => _ride?['status'] ?? 'requested';

  bool get _isRequested => _status == 'requested' || _status == 'pending';
  bool get _isAccepted => _status == 'accepted';
  bool get _isOnTheWay => _status == 'on_the_way';
  bool get _isAtPickup => _status == 'in_progress';
  bool get _isCompleted => _status == 'completed';

  // Step index: 0=Accepted, 1=OnTheWay, 2=AtPickup, 3=AtDrop
  int get _currentStep {
    switch (_status) {
      case 'accepted':
        return 0;
      case 'on_the_way':
        return 1;
      case 'in_progress':
        return 2;
      case 'completed':
        return 3;
      default:
        return -1; // not started
    }
  }

  // ── Action handlers ─────────────────────────────────────────────

  Future<void> _acceptRide() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.ambulance.acceptRideRequest(widget.rideId);
      if (mounted) {
        setState(() {
          _acceptedAt = DateTime.now();
          if (_ride != null) _ride!['status'] = 'accepted';
        });
        await _loadRide();
        // Start live location updates after accepting
        final token = _apiClient.token;
        if (token != null) {
          await _locationService.startLocationUpdates(
            bookingId: widget.rideId,
            token: token,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectRide() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Booking'),
        content: const Text('Are you sure you want to reject this booking request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking rejected')),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _startRide() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.ambulance.updateRealtimeBookingStatus(widget.rideId, 'on_the_way');
      if (mounted) {
        setState(() {
          _onTheWayAt = DateTime.now();
          if (_ride != null) _ride!['status'] = 'on_the_way';
        });
        await _loadRide();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _arriveAtPickup() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.ambulance.updateRealtimeBookingStatus(widget.rideId, 'in_progress');
      if (mounted) {
        setState(() {
          _atPickupAt = DateTime.now();
          if (_ride != null) _ride!['status'] = 'in_progress';
        });
        await _loadRide();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _completeRide() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.ambulance.updateRealtimeBookingStatus(widget.rideId, 'completed');
      if (mounted) {
        setState(() {
          _atDropAt = DateTime.now();
          if (_ride != null) _ride!['status'] = 'completed';
        });
        _locationService.stopLocationUpdates();
        await _loadRide();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _callPatient() async {
    final phone = _ride?['patient']?['phone'];
    if (phone == null) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openMap() async {
    final coords = _ride?['location']?['coordinates'];
    if (coords == null || coords.length < 2) return;
    final lat = coords[1];
    final lng = coords[0];
    final uri = Uri.parse('https://maps.google.com/?q=$lat,$lng');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading && _ride != null && !_isRequested) {
      return _buildConnectedScreen(_ride!);
    }

    final patient = _ride?['patient'] ?? {};
    final patientName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      appBar: AppBar(
        backgroundColor: _isRequested ? const Color(0xFFF75555) : Colors.white,
        foregroundColor: _isRequested ? Colors.white : const Color(0xFF152238),
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: _isRequested ? Colors.white : const Color(0xFF152238)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: _isRequested
            ? const Text('Ambulance Request Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handshake, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Connected with $patientName',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF152238),
                    ),
                  ),
                ],
              ),
        actions: _isRequested ? [] : [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF152238)),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE52329)))
          : _ride == null
              ? const Center(child: Text('Ride not found'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isRequested) {
      return Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Request Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  _buildRequestSummaryCard(),
                  const SizedBox(height: 10),
                  const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  _buildRequestPatientDetailsCard(),
                  const SizedBox(height: 10),
                  const Text('Service Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  _buildRequestServiceDetailsCard(),
                ],
              ),
            ),
          ),
          _buildAcceptRejectButtons(),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isCompleted) ...[
                  _buildCompletedBanner(),
                  const SizedBox(height: 12),
                ],
                _buildPatientCard(),
                const SizedBox(height: 12),
                _buildRouteCard(),
                const SizedBox(height: 12),
                _buildStatusStepperHorizontal(),
                const SizedBox(height: 12),
                if (!_isCompleted) ...[
                  _buildActionShortcuts(),
                  const SizedBox(height: 12),
                ],
                if (_isCompleted) ...[
                  _buildActionShortcuts(),
                  const SizedBox(height: 12),
                  _buildThankYouCard(),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
        _buildBottomButton(),
      ],
    );
  }
  // ── Request Summary Card ──────────────────────────────────────────

  Widget _buildRequestSummaryCard() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Male';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '--';

    String formattedDate = '--';
    if (_ride!['createdAt'] != null) {
      final dt = DateTime.tryParse(_ride!['createdAt'].toString());
      if (dt != null) {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
      }
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 50, height: 50,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFEDF2F7)),
            child: ClipOval(
              child: patient['profilePicture'] != null
                  ? Image.network(patient['profilePicture'], fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.grey, size: 28))
                  : const Icon(Icons.person, color: Colors.grey, size: 28),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text('$gender  •  $age Years', style: TextStyle(color: Colors.grey[700], fontSize: 11)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFFCF3F3), borderRadius: BorderRadius.circular(4)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.red, size: 10),
                      const SizedBox(width: 2),
                      Text('3.2 km away', style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Requested On', style: TextStyle(color: Colors.grey[500], fontSize: 10)),
              const SizedBox(height: 2),
              SizedBox(
                width: 90,
                child: Text(
                  formattedDate,
                  textAlign: TextAlign.end,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF152238)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Request Patient Details Card ────────────────────────────────

  Widget _buildRequestPatientDetailsCard() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Male';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '--';
    final pickup = _safeAddress(_ride!['location'] ?? _ride!['pickupLocation'], 'Pickup not specified');
    final drop = _safeAddress(_ride!['dropLocation'] ?? _ride!['dropOffLocation'], 'Drop not specified');
    final phone = patient['phone'] ?? 'N/A';
    final details = _ride!['notes'] ?? _ride!['requirements']?['description'] ?? 'Patient having chest pain and difficulty in breathing.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildDetailItem(Icons.person_outline, 'Name', fullName, color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.calendar_today_outlined, 'Age / Gender', '$age Years / $gender', color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.location_on_outlined, 'Pickup Location', pickup, color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.my_location_outlined, 'Drop-off Location (Optional)', drop, color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.phone_outlined, 'Phone Number', phone, color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.description_outlined, 'Additional Details', details, color: Colors.red),
        ],
      ),
    );
  }

  // ── Request Service Details Card ────────────────────────────────

  Widget _buildRequestServiceDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildDetailItem(Icons.local_hospital_outlined, 'Service Type', 'Ambulance', color: Colors.red),
          const Divider(),
          _buildDetailItem(Icons.health_and_safety_outlined, 'Purpose', 'Medical Emergency', color: Colors.red),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value, {Color color = Colors.grey}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.grey[800], fontSize: 11)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11), textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPatientDetailsCard() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Male';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '--';
    
    final pickup = _safeAddress(_ride!['location'] ?? _ride!['pickupLocation'], 'Pickup not specified');
    final drop = _safeAddress(_ride!['dropLocation'] ?? _ride!['dropOffLocation'], 'Drop not specified');
    final phone = patient['phone'] ?? 'N/A';
    final notes = _ride!['notes'] ??
        _ride!['requirements']?['description'] ??
        'Patient having medical emergency.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.person_outline, 'Name', fullName),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.calendar_today_outlined, 'Age / Gender', '$age Years / $gender'),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.location_on_outlined, 'Pickup Location', pickup),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.my_location_outlined, 'Drop-off Location (Optional)', drop),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.phone_outlined, 'Phone Number', phone),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.notes_outlined, 'Additional Details', notes),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFE52329), size: 18),
          const SizedBox(width: 12),
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewServiceDetailsCard() {
    final requirements = _ride!['requirements'] ?? {};
    final isEmergency = _ride!['isEmergency'] ?? false;
    final purpose = isEmergency ? 'Medical Emergency' : (requirements['urgency'] != null ? '${requirements['urgency']} Urgency' : 'Medical Transport');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.local_shipping_outlined, 'Service Type', 'Ambulance'),
          const Divider(height: 1, thickness: 0.5, color: Color(0xFFEEEEEE)),
          _buildDetailRow(Icons.health_and_safety_outlined, 'Purpose', purpose),
        ],
      ),
    );
  }

  Widget _buildNewAcceptRejectBottom() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _rejectRide,
                      icon: const Icon(Icons.close, color: Color(0xFFE52329), size: 20),
                      label: const Text('Reject Request', style: TextStyle(color: Color(0xFFE52329), fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE52329)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _acceptRide,
                      icon: const Icon(Icons.check, color: Color(0xFF4CAF50), size: 20),
                      label: const Text('Accept Request', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF4CAF50)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'You can accept or reject this booking request.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Once accepted, the patient will be notified.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
                style: TextStyle(
                  color: Color(0xFF388E3C),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Patient Card ──────────────────────────────────────────────────

  Widget _buildPatientCard() {
    final patient = _ride!['patient'] ?? {};
    final fullName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Unknown Patient';
    final gender = _ride!['patientGender'] ?? patient['gender'] ?? 'Female';
    final age = _ride!['patientAge'] ?? patient['age'] ?? '27';
    final address = _safeAddress(_ride!['location'] ?? _ride!['pickupLocation'], 'Address not available');
    final price = (_ride!['price'] ?? 0).toStringAsFixed(0);

    String formattedDate = '--';
    String formattedTime = '--';
    if (_ride!['createdAt'] != null) {
      final dt = DateTime.tryParse(_ride!['createdAt'].toString());
      if (dt != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(dt.toLocal());
        formattedTime = DateFormat('hh:mm a').format(dt.toLocal());
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8F1FF),
                ),
                child: ClipOval(
                  child: patient['profilePicture'] != null
                      ? Image.network(patient['profilePicture'], fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person,
                              color: Color(0xFF1565C0), size: 28))
                      : const Icon(Icons.person, color: Color(0xFF1565C0), size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(gender.toLowerCase() == 'female' ? Icons.female : Icons.male, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$gender  •  $age Years',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.black87),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.access_time, size: 14, color: Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(formattedTime, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E8E3E),
                      ),
                    ),
                    const Text(
                      'Service Fee',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Status Stepper ────────────────────────────────────────────────

  Widget _buildStatusStepperHorizontal() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHorizontalStep(
            title: 'Accepted',
            time: _acceptedAt != null ? _fmt(_acceptedAt) : 'Just Now',
            isActive: _currentStep >= 0,
            isFirst: true,
            isLast: false,
            isNextActive: _currentStep >= 1,
          ),
          _buildHorizontalStep(
            title: 'On The Way',
            time: _currentStep >= 1 ? (_onTheWayAt != null ? _fmt(_onTheWayAt) : _fmt(DateTime.now())) : '--:--',
            isActive: _currentStep >= 1,
            isFirst: false,
            isLast: false,
            isNextActive: _currentStep >= 2,
          ),
          _buildHorizontalStep(
            title: 'At Pickup Point',
            time: _currentStep >= 2 ? (_atPickupAt != null ? _fmt(_atPickupAt) : _fmt(DateTime.now())) : '--:--',
            isActive: _currentStep >= 2,
            isFirst: false,
            isLast: false,
            isNextActive: _currentStep >= 3,
          ),
          _buildHorizontalStep(
            title: 'At Drop Point',
            time: _currentStep >= 3 ? (_atDropAt != null ? _fmt(_atDropAt) : _fmt(DateTime.now())) : '--:--',
            isActive: _currentStep >= 3,
            isFirst: false,
            isLast: true,
            isNextActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalStep({
    required String title,
    required String time,
    required bool isActive,
    required bool isFirst,
    required bool isLast,
    required bool isNextActive,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  color: isFirst ? Colors.transparent : (isActive ? Colors.green : Colors.grey.shade300),
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green : Colors.white,
                  border: Border.all(
                    color: isActive ? Colors.transparent : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: isActive
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: isLast ? Colors.transparent : (isNextActive ? Colors.green : Colors.grey.shade300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isActive ? Colors.green : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildRouteCard() {
    final pickup = _safeAddress(_ride!['location'] ?? _ride!['pickupLocation'], 'Pickup not specified');
    final drop = _safeAddress(_ride!['dropLocation'] ?? _ride!['dropOffLocation'], 'Drop not specified');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.location_on, color: Color(0xFF1E8E3E), size: 20),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.transparent,
                    child: CustomPaint(painter: _DashedLinePainter()),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Pickup Point', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(pickup, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Color(0xFFE52329), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Drop Point', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(drop, style: const TextStyle(fontSize: 12, color: Colors.black87, height: 1.4)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepNode(int index, String title, String time, bool isCompleted, {bool isLast = false}) {
    return const SizedBox.shrink();
  }

  // ── Action Shortcuts ──────────────────────────────────────────────

  // ── Action Shortcuts ──────────────────────────────────────────────

  Widget _buildActionShortcuts() {
    final items = [
      _ShortcutItem(
        icon: Icons.phone,
        label: 'Call Patient',
        onTap: _callPatient,
      ),
      _ShortcutItem(
        icon: Icons.chat,
        label: 'Chat',
        onTap: () {},
      ),
      _ShortcutItem(
        icon: Icons.map,
        label: 'Open Map',
        onTap: _openMap,
      ),
      _ShortcutItem(
        icon: Icons.description,
        label: 'Trip Details',
        onTap: () => _showTripDetails(),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return GestureDetector(
            onTap: item.onTap,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon,
                      color: const Color(0xFF1A56DB), size: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showTripDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final patient = _ride!['patient'] ?? {};
        final fullName = patient['fullName'] ??
            '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
        final phone = patient['phone'] ?? 'N/A';
        final gender = _ride!['patientGender'] ?? patient['gender'] ?? '--';
        final age = _ride!['patientAge'] ?? patient['age'] ?? '--';
        final price = (_ride!['price'] ?? 0).toStringAsFixed(0);
        final notes = _ride!['notes'] ??
            _ride!['requirements']?['description'] ??
            'Medical Emergency';

        return Padding(
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              _detailRow('Patient', fullName),
              _detailRow('Phone', phone),
              _detailRow('Gender / Age', '$gender / $age years'),
              _detailRow('Service Fee', '₹$price'),
              _detailRow('Notes', notes),
              _detailRow('Status', _status.toUpperCase()),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
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
                style: const TextStyle(
                    color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ── Thank You Card ────────────────────────────────────────────────

  Widget _buildThankYouCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF81C784), width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thank you!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'You have completed the service successfully.',
                  style: TextStyle(color: Colors.black87, fontSize: 12),
                ),
                SizedBox(height: 2),
                Text(
                  'Payment will be transferred shortly.',
                  style: TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Action Button ──────────────────────────────────────────

  Widget _buildAcceptRejectButtons() {
    return Container(
      color: const Color(0xFFFCF3F3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isProcessing ? null : _rejectRide,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFFE52329), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      backgroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.close, color: Color(0xFFE52329), size: 18),
                    label: const Text(
                      'Reject Request',
                      style: TextStyle(color: Color(0xFFE52329), fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isProcessing ? null : _acceptRide,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: const BorderSide(color: Colors.green, width: 1.5),
                      ),
                    ),
                    icon: _isProcessing
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.green, strokeWidth: 2))
                        : const Icon(Icons.check, color: Colors.green, size: 18),
                    label: Text(
                      _isProcessing ? 'Wait...' : 'Accept Request',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'You can accept or reject this booking request.\nOnce accepted, the patient will be notified.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    if (_isCompleted) return const SizedBox.shrink();

    String label = '';
    VoidCallback? onPressed;
    IconData? iconData;

    if (_isAccepted) {
      label = 'I Am On The Way';
      iconData = Icons.directions_car;
      onPressed = _startRide;
    } else if (_isOnTheWay) {
      label = 'Reached Pickup Location';
      iconData = Icons.location_on;
      onPressed = _arriveAtPickup;
    } else if (_isAtPickup) {
      label = 'Complete Trip';
      iconData = Icons.check_circle;
      onPressed = _completeRide;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE52329),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: _isProcessing
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (iconData != null) ...[
                        Icon(iconData, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedScreen(Map<String, dynamic> booking) {
    final patientData = booking['patient'] ?? {};
    String patientName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    if (patientName.isEmpty) patientName = 'Rahul Sharma';
    
    final String gender = patientData['gender']?.toString() ?? 'Male';
    final String age = patientData['age']?.toString() ?? '32';
    final phone = patientData['phone']?.toString() ?? '+91 98765 43210';

    final pickup = _safeAddress(booking['pickupLocation'] ?? booking['location'] ?? booking['pickupAddress'], 'B-102, Ashok Nagar, Varanasi, UP');
    final drop = _safeAddress(booking['dropLocation'] ?? booking['destination'] ?? booking['dropAddress'], 'Apex Hospital, Varanasi, UP');

    final requestedOn = booking['createdAt'] != null ? DateTime.tryParse(booking['createdAt']) : DateTime.now();
    final String displayDate = requestedOn != null ? DateFormat('dd MMM yyyy').format(requestedOn) : '30 Jun 2026';
    
    String displayTime = '11:30 AM';
    if (booking['scheduledTime'] != null) {
      try {
        final dt = DateTime.parse(booking['scheduledTime']);
        displayTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final price = booking['price'] ?? booking['totalAmount'] ?? booking['fees'] ?? 1500;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Connected', 
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF152238))
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Patient Details Card with left border highlighted
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 140,
                            color: const Color(0xFFEF4444), // Ambulance theme color
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade200,
                                          image: const DecorationImage(
                                            image: AssetImage('assets/images/male_profile.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  patientName,
                                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified, color: Color(0xFFEF4444), size: 14),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Age: $age Years  |  Gender: $gender',
                                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Mobile: $phone',
                                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 14),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Location: ',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                      Expanded(
                                        child: Text(
                                          pickup,
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Route Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Route Details',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.my_location, color: Color(0xFF22C55E), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Pickup Location',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    pickup,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 7.0),
                          child: SizedBox(
                            height: 20,
                            child: VerticalDivider(width: 2, color: Color(0xFFCBD5E1), thickness: 1.5),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Drop Location',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    drop,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24, color: Color(0xFFE2E8F0)),
                        const Text(
                          'Booking Date & Time',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$displayDate, $displayTime',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Booking Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Details',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 10),
                        _buildConnectedDetailRow('Service Type', 'Ambulance Ride'),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildConnectedDetailRow('Offered Amount', '₹$price'),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildConnectedDetailRow('Booking Date & Time', '25 May 2025, 10:15 AM'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Details',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 10),
                        _buildConnectedDetailRow('Payment Type', 'Direct to Vendor'),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        const Text(
                          'Customer will pay after service completion.',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons Row (Call Patient & WhatsApp)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final Uri telUri = Uri(scheme: 'tel', path: phone);
                              if (await canLaunchUrl(telUri)) {
                                await launchUrl(telUri);
                              }
                            },
                            icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                            label: const Text(
                              'Call Patient',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = "https://wa.me/${phone.replaceAll(RegExp(r'[^\d]'), '')}";
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              }
                            },
                            icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Need Assistance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Need Assistance?',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'If you face any issues, please contact ONMINT Support.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF0284C7)),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: OutlinedButton(
                            onPressed: () async {
                              final Uri supportUri = Uri(scheme: 'tel', path: '+919999999999');
                              if (await canLaunchUrl(supportUri)) {
                                await launchUrl(supportUri);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF0284C7)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Contact Support',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Green Safety Priority Bar
            Container(
              width: double.infinity,
              color: const Color(0xFFDCFCE7),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF15803D), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Your safety is our priority.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildConnectedDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
      ],
    );
  }
}

// ── Helper classes ─────────────────────────────────────────────────

class _StepData {
  final String label;
  final String time;
  final bool isActive;
  _StepData({required this.label, required this.time, required this.isActive});
}

class _ShortcutItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ShortcutItem(
      {required this.icon, required this.label, required this.onTap});
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
