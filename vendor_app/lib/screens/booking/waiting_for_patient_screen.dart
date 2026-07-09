import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import '../ambulance/ride_details_screen.dart';
import '../nurse/active_booking_screen.dart';
import '../pathology/lab_test_booking_screen.dart';
import '../blood_bank/blood_bank_accepted_order_screen.dart';

class WaitingForPatientScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const WaitingForPatientScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<WaitingForPatientScreen> createState() => _WaitingForPatientScreenState();
}

class _WaitingForPatientScreenState extends State<WaitingForPatientScreen> {
  bool _isLoading = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final response = await ApiClient().get('/realtime-bookings/${widget.bookingId}');
      final data = response.data['data'] ?? response.data;
      final status = data['status']?.toString().toLowerCase() ?? '';
      
      if (status == 'accepted' || status == 'completed' || status == 'rejected' || status == 'cancelled') {
        if (mounted) {
          _pollingTimer?.cancel();
          
          if (status == 'rejected' || status == 'cancelled') {
            Navigator.of(context).popUntil((route) => route.isFirst);
            return;
          }

          final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
          
          bool myOfferAccepted = false;
          final offers = data['offers'] as List?;
          if (offers != null && currentUserId != null) {
            for (var o in offers) {
              final vId = o is Map ? (o['vendorId'] ?? o['vendor'] ?? o['vendor_id']) : null;
              bool isMyOffer = vId == currentUserId || (vId is Map && (vId['_id'] == currentUserId || vId['id'] == currentUserId));
              if (isMyOffer && o is Map && o['status'] == 'accepted') {
                myOfferAccepted = true;
                break;
              }
            }
          }
          
          final assignedTo = data['assignedTo'];
          bool assignedToMe = false;
          if (assignedTo != null && currentUserId != null) {
            final aId = assignedTo is Map ? (assignedTo['_id'] ?? assignedTo['id']) : assignedTo;
            assignedToMe = (aId == currentUserId);
          }
          
          if ((status == 'accepted' || status == 'completed') && (myOfferAccepted || assignedToMe)) {
            _navigateToConnectedScreen(data);
          } else {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
          return;
        }
      }
    } catch (e) {
      // Ignore fallback silently
    }
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToConnectedScreen(Map<String, dynamic> data) {
    final serviceType = (data['serviceType'] ?? widget.bookingData['serviceType'])?.toString().toLowerCase() ?? '';
    
    Widget targetScreen;
    if (serviceType == 'ambulance') {
      targetScreen = RideDetailsScreen(rideId: widget.bookingId);
    } else if (serviceType == 'nurse') {
      targetScreen = ActiveBookingScreen(bookingId: widget.bookingId, bookingData: data);
    } else if (serviceType == 'pathology') {
      targetScreen = LabTestBookingScreen(bookingId: widget.bookingId, bookingData: data);
    } else if (serviceType == 'bloodbank' || serviceType == 'blood_request') {
      targetScreen = BloodBankAcceptedOrderScreen(bookingId: widget.bookingId, initialData: data);
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bookingData = widget.bookingData;
    final patientData = bookingData['patient'] ?? bookingData['patientDetails'] ?? {};
    String pName = 'Patient';
    if (patientData is Map) {
      pName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    }
    if (pName.isEmpty) pName = bookingData['patientName'] ?? 'Patient';

    // Find the offer date for this vendor
    String sentDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final offers = bookingData['offers'] as List?;
    if (offers != null && offers.isNotEmpty) {
      final lastOffer = offers.last;
      if (lastOffer['createdAt'] != null) {
        final dt = DateTime.tryParse(lastOffer['createdAt'].toString());
        if (dt != null) {
          sentDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8FD),
        foregroundColor: const Color(0xFF152238),
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Waiting for Patient',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF152238),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              constraints: const BoxConstraints(
                minHeight: 180,
                maxHeight: 280,
              ),
              width: double.infinity,
              child: Image.asset(
                'assets/images/request_send_top_image.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback icon placeholder if image is missing
                  return Container(
                    height: 200,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time_filled, size: 80, color: Color(0xFF0056D2)),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Card 1: Summary Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.hourglass_empty,
                    iconColor: Colors.deepPurple,
                    bgColor: const Color(0xFFF3E5F5),
                    label: 'Status',
                    value: 'Waiting for Patient',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F3F9)),
                  ),
                  _buildDetailRow(
                    icon: Icons.calendar_month_outlined,
                    iconColor: Colors.blue,
                    bgColor: const Color(0xFFE8F1FF),
                    label: 'Sent On',
                    value: sentDateStr,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F3F9)),
                  ),
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    iconColor: Colors.blue,
                    bgColor: const Color(0xFFE8F1FF),
                    label: 'Requested By',
                    value: pName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Blue Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Color(0xFF0056D2), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "The patient will review your offer.\nYou'll be notified once they respond.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF0056D2),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact Support Row Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.phone_in_talk, color: Color(0xFF0056D2), size: 20),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Support',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF152238),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Need help? Call our support team.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Footer check notice
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, color: Colors.indigo.shade400, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Stay online to get faster responses and better chances.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF152238),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
