import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';

class BookingDetailsScreenEnhanced extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingData;

  const BookingDetailsScreenEnhanced({
    super.key,
    required this.bookingId,
    this.bookingData,
  });

  @override
  State<BookingDetailsScreenEnhanced> createState() =>
      _BookingDetailsScreenEnhancedState();
}

class _BookingDetailsScreenEnhancedState
    extends State<BookingDetailsScreenEnhanced> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _bookingDetails;
  bool _isLoading = true;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookingData != null) {
      _bookingDetails = widget.bookingData;
      _isLoading = false;
    } else {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    try {
      await _apiClient.initialize();
      final response = await _apiClient.nurse.getBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _bookingDetails = response['data'] ?? response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.showError('Failed to load details');
      }
    }
  }

  Future<void> _acceptBooking() async {
    setState(() => _isActing = true);
    try {
      await _apiClient.initialize();
      final isRealtime = (_bookingDetails ?? widget.bookingData ?? {})['isRealtimeBooking'] == true || (_bookingDetails ?? widget.bookingData ?? {})['bookingType'] == 'realtime';
      
      if (isRealtime) {
        await _apiClient.nurse.acceptRealtimeBooking(widget.bookingId);
      } else {
        await _apiClient.nurse.acceptBooking(widget.bookingId);
      }
      
      if (mounted) {
        ToastUtils.showSuccess('Booking accepted successfully');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActing = false);
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('409') || errStr.contains('already accepted') || errStr.contains('expired')) {
          ToastUtils.showError('This booking has already been accepted or expired.');
          Navigator.pop(context, true);
        } else {
          ToastUtils.showError('Failed to accept booking. Please try again.');
        }
      }
    }
  }

  Future<void> _rejectBooking() async {
    setState(() => _isActing = true);
    try {
      await _apiClient.initialize();
      final isRealtime = (_bookingDetails ?? widget.bookingData ?? {})['isRealtimeBooking'] == true || (_bookingDetails ?? widget.bookingData ?? {})['bookingType'] == 'realtime';
      
      if (isRealtime) {
        // Just mark as viewed and dismiss locally for realtime requests
        try {
          await _apiClient.nurse.markRealtimeBookingAsViewed(widget.bookingId);
        } catch (_) {}
      } else {
        await _apiClient.nurse.rejectBooking(widget.bookingId, reason: 'Rejected by nurse');
      }
      
      if (mounted) {
        ToastUtils.showSuccess('Booking rejected');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isActing = false);
        ToastUtils.showError('Failed to reject booking. Please try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _bookingDetails ?? {};
    final patientData = booking['patient'] ?? {};
    
    String patientName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    if (patientName.isEmpty) patientName = 'Patient';
    
    final int age = patientData['age'] ?? 35; // Default age if missing
    final String gender = patientData['gender'] ?? 'Male';
    final String profilePicture = patientData['profilePicture']?.toString() ?? '';
    final String address = booking['location']?['address'] ?? 'Not specified';
    final String status = booking['status']?.toString() ?? 'Pending';
    final String notes = booking['notes']?.toString() ?? 'Nursing Service';
    final String emergencyType = booking['isEmergency'] == true ? 'Urgent' : 'Normal';
    final String patientCity = patientData['city']?.toString() ?? booking['city']?.toString() ?? '';
    final String patientState = patientData['state']?.toString() ?? booking['state']?.toString() ?? '';

    String requestedOn = 'Just Now';
    if (booking['createdAt'] != null) {
      final dt = DateTime.tryParse(booking['createdAt'].toString());
      if (dt != null) {
        final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final monthStr = months[dt.month - 1];
        requestedOn = '${dt.day.toString().padLeft(2, '0')} $monthStr ${dt.year}, ${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F4CBA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Nurse Request Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetails,
        child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            // Request Summary
            _buildCard(
              title: 'Request Summary',
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    backgroundImage: profilePicture.isNotEmpty ? NetworkImage(profilePicture) : null,
                    child: profilePicture.isEmpty ? const Icon(Icons.person, size: 35, color: Colors.blue) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$gender • $age Years',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Requested On',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        requestedOn,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Patient Details
            _buildCard(
              title: 'Patient Details',
              child: Column(
                children: [
                  _buildDetailRow(Icons.person_outline, 'Name', patientName),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildDetailRow(Icons.calendar_today_outlined, 'Age/Gender', '$age Years / $gender'),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildDetailRow(Icons.medical_services_outlined, 'Service', notes),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildDetailRow(Icons.location_on_outlined, 'Address', address),
                  if (patientCity.isNotEmpty) ...[
                    const Divider(color: Color(0xFFF1F5F9), height: 16),
                    _buildDetailRow(Icons.location_city, 'City', patientCity),
                  ],
                  if (patientState.isNotEmpty) ...[
                    const Divider(color: Color(0xFFF1F5F9), height: 16),
                    _buildDetailRow(Icons.map_outlined, 'State', patientState),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            
            // Service Request Details
            _buildCard(
              title: 'Service Request Details',
              child: Column(
                children: [
                  _buildDetailRow(Icons.health_and_safety_outlined, 'Type', 'Home Care Nursing'),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildDetailRow(Icons.warning_amber_rounded, 'Emergency', emergencyType),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildDetailRow(Icons.assignment_outlined, 'Status', status.toUpperCase()),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildDetailRow(Icons.note_alt_outlined, 'Note', notes),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Once accepted, your details will be shared with the patient.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
              ),
            ),
            
            const SizedBox(height: 20),
            
          ],
        ),
      ),
      ), // closes RefreshIndicator
      bottomNavigationBar: (status.toLowerCase() == 'requested' || status.toLowerCase() == 'pending')
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: _isActing
                    ? const SizedBox(height: 48, child: Center(child: CircularProgressIndicator()))
                    : Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _rejectBooking,
                              icon: const Icon(Icons.close, color: Color(0xFFE53935), size: 18),
                              label: const Text(
                                'Reject',
                                style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _acceptBooking,
                              icon: const Icon(Icons.check, color: Color(0xFF2E7D32), size: 18),
                              label: const Text(
                                'Accept',
                                style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            )
          : null,
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
