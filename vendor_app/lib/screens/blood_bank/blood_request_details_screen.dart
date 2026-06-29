import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'blood_bank_accepted_order_screen.dart';
import 'package:intl/intl.dart';

class BloodRequestDetailsScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? initialData;

  const BloodRequestDetailsScreen({
    super.key,
    required this.bookingId,
    this.initialData,
  });

  @override
  State<BloodRequestDetailsScreen> createState() =>
      _BloodRequestDetailsScreenState();
}

class _BloodRequestDetailsScreenState
    extends State<BloodRequestDetailsScreen> {
  bool _isActionLoading = false;
  bool _isLoadingData = false;
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
    if (widget.initialData != null) {
      _booking = widget.initialData;
    } else {
      _fetchBooking();
    }
  }

  Future<void> _fetchBooking() async {
    setState(() => _isLoadingData = true);
    try {
      final res = await _apiClient.get('/realtime/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = res.data['data'] ?? {};
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  /// Safely extract address string from any type
  String _safeAddress(dynamic loc, [String fallback = 'Not specified']) {
    if (loc == null) return fallback;
    if (loc is String) return loc.isEmpty ? fallback : loc;
    if (loc is Map) {
      final addr = loc['address'];
      if (addr is Map) {
        return addr['address']?.toString() ??
            addr['street']?.toString() ??
            fallback;
      }
      if (addr != null) return addr.toString();
      return loc['street']?.toString() ??
          loc['city']?.toString() ??
          fallback;
    }
    return loc.toString();
  }

  void _handleAction(bool accept) async {
    setState(() => _isActionLoading = true);
    try {
      if (accept) {
        await _apiClient.post('/realtime/${widget.bookingId}/accept');
        if (mounted) {
          setState(() => _isActionLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request Accepted Successfully'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BloodBankAcceptedOrderScreen(
                bookingId: widget.bookingId,
                initialData: _booking,
              ),
            ),
          );
        }
      } else {
        await _apiClient.patch('/realtime/${widget.bookingId}/status',
            data: {'status': 'rejected'});
        if (mounted) {
          setState(() => _isActionLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Request Rejected'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActionLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Blood Request Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFC62828),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: _isLoadingData
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)))
          : _booking == null
              ? const Center(child: Text('Request not found'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final b = _booking!;
    final patient = b['patientDetails'] ?? b['patient'] ?? {};
    final patientName = (patient is Map)
        ? (patient['fullName'] ??
            '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim())
        : (b['patientName'] ?? 'Patient');
    final patientAge = (patient is Map)
        ? (patient['age']?.toString() ?? b['patientAge']?.toString() ?? '--')
        : '--';
    final patientGender = (patient is Map)
        ? (patient['gender'] ?? b['patientGender'] ?? 'Male')
        : 'Male';
    final patientPhone = (patient is Map)
        ? (patient['phone'] ?? b['patientPhone'] ?? b['contactNumber'] ?? 'N/A')
        : 'N/A';

    final bloodGroup = b['bloodGroup'] ?? 'N/A';
    final units = b['unitsRequired']?.toString() ?? b['units']?.toString() ?? '1';
    final hospitalName = b['hospitalName'] ?? 'Not specified';
    final address = _safeAddress(b['location'] ?? b['address']);
    final city = b['city'] ?? '';
    final state = b['state'] ?? '';
    final emergencyNote = b['description'] ?? b['notes'] ?? b['emergencyNote'] ?? 'No notes';
    final isEmergency = b['isEmergency'] == true;

    String requestedOn = '';
    if (b['createdAt'] != null) {
      final dt = DateTime.tryParse(b['createdAt'].toString());
      if (dt != null) {
        requestedOn =
            DateFormat('dd MMM yyyy, hh:mm a').format(dt.toLocal());
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient summary card
          _buildSection('Patient Summary', [
            _buildDetailRow(Icons.person_outline, 'Name', patientName.isNotEmpty ? patientName : 'N/A'),
            _buildDetailRow(Icons.calendar_today, 'Age / Gender', '$patientAge Years / $patientGender'),
            _buildDetailRow(Icons.phone_outlined, 'Phone', patientPhone),
            if (requestedOn.isNotEmpty)
              _buildDetailRow(Icons.access_time_outlined, 'Requested On', requestedOn),
          ]),
          const SizedBox(height: 14),

          // Blood request details
          _buildSection('Blood Request Details', [
            _buildDetailRow(Icons.bloodtype, 'Blood Group', bloodGroup,
                iconColor: Colors.red),
            _buildDetailRow(Icons.water_drop_outlined, 'Units Required', '$units Units',
                iconColor: Colors.red),
            _buildDetailRow(Icons.local_hospital_outlined, 'Hospital',
                hospitalName.isNotEmpty ? hospitalName : 'Not specified',
                iconColor: Colors.red),
            _buildDetailRow(Icons.location_on_outlined, 'Pickup Address',
                address.isNotEmpty ? address : 'Not specified',
                iconColor: Colors.red),
            if (city.isNotEmpty)
              _buildDetailRow(Icons.location_city, 'City', city, iconColor: Colors.red),
            if (state.isNotEmpty)
              _buildDetailRow(Icons.map_outlined, 'State', state, iconColor: Colors.red),
            _buildDetailRow(Icons.note_alt_outlined, 'Emergency Note',
                emergencyNote.isNotEmpty ? emergencyNote : 'None',
                iconColor: Colors.orange),
          ]),
          const SizedBox(height: 20),

          // Action buttons
          if (_isActionLoading)
            const Center(child: CircularProgressIndicator(color: Color(0xFFC62828)))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _handleAction(false),
                    icon: const Icon(Icons.close, color: Colors.red, size: 18),
                    label: const Text('Reject',
                        style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAction(true),
                    icon: const Icon(Icons.check, color: Colors.white, size: 18),
                    label: const Text('Accept',
                        style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFC62828),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Once accepted, the patient will be notified.\nYou can then update the request status.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const SizedBox(height: 12),
          ...rows.expand((w) => [w, const Divider(height: 1, thickness: 0.5)]).toList()
            ..removeLast(),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {Color iconColor = const Color(0xFFC62828)}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(label,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
