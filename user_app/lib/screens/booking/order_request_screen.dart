import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:api_client/api_client.dart';
import '../doctors/doctor_categories_screen.dart';
import '../services/nurses_screen.dart';
import 'ambulance_booking_screen.dart';
import 'blood_request_screen.dart';
import 'lab_test_booking_screen.dart';
import '../profile/help_support_screen.dart';
import '../medicines/medicines_list_screen.dart';
import 'service_offers_screen.dart';
import '../home/home_screen.dart';

class OrderRequestScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingData;
  final String serviceType;

  const OrderRequestScreen({
    super.key,
    required this.bookingId,
    this.bookingData,
    required this.serviceType,
  });

  @override
  State<OrderRequestScreen> createState() => _OrderRequestScreenState();
}

class _OrderRequestScreenState extends State<OrderRequestScreen> {
  bool _isLoading = false;
  final PatientService _patientService = PatientService();
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _pollStatus();
      }
    });
  }

  Future<void> _pollStatus() async {
    try {
      final updatedBooking = await _patientService.getRealtimeBookingDetails(widget.bookingId);
      if (!mounted) return;
      
      final offers = updatedBooking['offers'] as List<dynamic>? ?? [];
      
      if (offers.isNotEmpty || updatedBooking['status'] == 'accepted') {
        _pollingTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceOffersScreen(
              bookingId: widget.bookingId,
              serviceType: widget.serviceType,
              bookingData: updatedBooking,
            ),
          ),
        );
      }
    } catch (e) {
      // Silently ignore polling errors
    }
  }

  String _extractPatientName(Map<String, dynamic>? data) {
    if (data == null) return 'N/A';
    try {
      if (data['patientName'] != null) return data['patientName'].toString();
      if (data['name'] != null) return data['name'].toString();
      if (data['patient'] != null && data['patient'] is Map) {
        return '${data['patient']['firstName'] ?? ''} ${data['patient']['lastName'] ?? ''}'.trim();
      }
    } catch (e) {
      // Ignore
    }
    return 'N/A';
  }

  String _extractPhone(Map<String, dynamic>? data) {
    if (data == null) return 'N/A';
    return data['phone']?.toString() ??
        data['patientPhone']?.toString() ??
        'N/A';
  }

  String _extractAge(Map<String, dynamic>? data) {
    if (data == null) return 'N/A';
    return data['age']?.toString() ?? data['patientAge']?.toString() ?? 'N/A';
  }

  String _extractGender(Map<String, dynamic>? data) {
    if (data == null) return 'N/A';
    return data['gender']?.toString() ??
        data['patientGender']?.toString() ??
        'N/A';
  }

  String _extractLocation(Map<String, dynamic>? data) {
    if (data == null) return 'N/A';
    try {
      if (data['address'] != null) {
        if (data['address'] is Map) {
          return data['address']['address']?.toString() ?? 'N/A';
        }
        return data['address'].toString();
      }
      if (data['location'] != null && data['location'] is Map) {
        return data['location']['address']?.toString() ?? 'N/A';
      }
    } catch (e) {
      // Ignore
    }
    return 'N/A';
  }

  String _extractDate(Map<String, dynamic>? data) {
    if (data == null) return 'Just now';
    final dateStr = data['createdAt'] ?? data['date'];
    if (dateStr == null) return 'Just now';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(date);
    } catch (e) {
      return 'Just now';
    }
  }

  String _extractDropOffLocation(Map<String, dynamic>? data) {
    if (data == null) return 'N/A';
    return data['dropOffLocation']?.toString() ?? 'N/A';
  }

  String _extractNotes(Map<String, dynamic>? data) {
    if (data == null) return 'None';
    return data['notes']?.toString() ?? 'None';
  }

  String _extractBloodDetails(Map<String, dynamic>? data) {
    if (data == null) return 'N/A';
    final group = data['bloodGroup']?.toString() ?? 'N/A';
    final unit =
        data['units']?.toString() ?? data['quantity']?.toString() ?? '1';
    return '$group / $unit Unit${unit == '1' ? '' : 's'}';
  }

  String _extractTestName(Map<String, dynamic>? data) {
    if (data == null) return 'N/A';
    try {
      if (data['testDetails'] != null && data['testDetails'] is Map) {
        return data['testDetails']['testName']?.toString() ?? 'N/A';
      }
      return data['testName']?.toString() ?? 'N/A';
    } catch (e) {
      // Ignore
    }
    return 'N/A';
  }

  Future<void> _cancelAppointment() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content:
            const Text('Are you sure you want to cancel this appointment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (widget.bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot cancel: Booking ID not found')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _patientService.cancelBooking(widget.bookingId,
          reason: 'Patient cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled successfully')),
        );
        Navigator.pop(context, true); // Return to previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rescheduleAppointment() async {
    setState(() => _isLoading = true);
    try {
      if (widget.bookingId.isNotEmpty) {
        await _patientService.cancelBooking(widget.bookingId,
            reason: 'Rescheduled');
      }
      if (mounted) {
        final type = widget.serviceType.toLowerCase();
        Widget nextScreen;
        switch (type) {
          case 'doctor':
          case 'consultation':
            nextScreen = const DoctorCategoriesScreen();
            break;
          case 'nurse':
            nextScreen = const NursesScreen();
            break;
          case 'ambulance':
            nextScreen = const AmbulanceBookingScreen();
            break;
          case 'bloodbank':
          case 'blood bank':
            nextScreen = const BloodRequestScreen();
            break;
          case 'medicine':
          case 'pharmacy':
          case 'pharmacist':
            nextScreen = const MedicinesListScreen();
            break;
          case 'pathology':
          case 'lab_test':
          case 'lab test':
          case 'labtest':
          default:
            nextScreen = const LabTestBookingScreen();
            break;
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => nextScreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reschedule: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _contactSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
    );
  }

  Future<void> _refreshStatus() async {
    try {
      final updatedBooking = await _patientService.getRealtimeBookingDetails(widget.bookingId);
      if (!mounted) return;
      
      final offers = updatedBooking['offers'] as List<dynamic>? ?? [];
      
      if (offers.isNotEmpty || updatedBooking['status'] == 'accepted') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ServiceOffersScreen(
              bookingId: widget.bookingId,
              serviceType: widget.serviceType,
              bookingData: updatedBooking,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Still waiting for vendor offers...')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to refresh: $e')),
        );
      }
    }
  }

  Widget _buildBadge({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0F2147),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 8,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.serviceType.toLowerCase();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = screenWidth < 380 ? screenWidth / 380.0 : 1.0;

    List<Widget> detailsRows = [];
    if (type == 'ambulance') {
      detailsRows = [
        _buildDetailRow(Icons.location_on_outlined, 'Pickup Location',
            _extractLocation(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.location_on_outlined, 'Drop-off Location',
            _extractDropOffLocation(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.person_outline, 'Contact Name',
            _extractPatientName(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.phone_outlined, 'Phone Number',
            _extractPhone(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.note_alt_outlined, 'Additional Details',
            _extractNotes(widget.bookingData),
            isLast: true, scale: scale),
      ];
    } else if (type == 'bloodbank' || type == 'blood bank') {
      detailsRows = [
        _buildDetailRow(Icons.person_outline, 'Patient Name',
            _extractPatientName(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.phone_outlined, 'Phone Number',
            _extractPhone(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.bloodtype_outlined, 'Blood Group / Unit',
            _extractBloodDetails(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.calendar_today_outlined, 'Age',
            '${_extractAge(widget.bookingData)} Years', scale: scale),
        _buildDetailRow(Icons.location_on_outlined, 'Location',
            _extractLocation(widget.bookingData),
            isLast: true, scale: scale),
      ];
    } else if (type == 'pathology' ||
        type == 'lab_test' ||
        type == 'lab test') {
      detailsRows = [
        _buildDetailRow(Icons.person_outline, 'Patient Name',
            _extractPatientName(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.phone_outlined, 'Phone Number',
            _extractPhone(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.calendar_today_outlined, 'Age',
            '${_extractAge(widget.bookingData)} Years', scale: scale),
        _buildDetailRow(Icons.science_outlined, 'Test Name',
            _extractTestName(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.location_on_outlined, 'Location',
            _extractLocation(widget.bookingData),
            isLast: true, scale: scale),
      ];
    } else if (type == 'medicine' || type == 'pharmacy' || type == 'pharmacist') {
      detailsRows = [
        _buildDetailRow(Icons.person_outline, 'Patient Name',
            _extractPatientName(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.phone_outlined, 'Phone Number',
            _extractPhone(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.location_on_outlined, 'Delivery Location',
            _extractLocation(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.note_alt_outlined, 'Additional Details',
            _extractNotes(widget.bookingData),
            isLast: true, scale: scale),
      ];
    } else {
      detailsRows = [
        _buildDetailRow(Icons.person_outline, 'Patient Name',
            _extractPatientName(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.phone_outlined, 'Phone Number',
            _extractPhone(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.calendar_today_outlined, 'Age',
            '${_extractAge(widget.bookingData)} Years', scale: scale),
        _buildDetailRow(Icons.transgender_outlined, 'Gender',
            _extractGender(widget.bookingData), scale: scale),
        _buildDetailRow(Icons.location_on_outlined, 'Location',
            _extractLocation(widget.bookingData),
            isLast: true, scale: scale),
      ];
    }

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F2147)),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false,
              );
            },
          ),
          title: const Text(
            'Request Submitted',
            style: TextStyle(
              color: Color(0xFF0F2147),
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.black12,
              height: 1.0,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF0F2147)),
              onPressed: _contactSupport,
            ),
          ],
        ),
        body: Stack(
          children: [
            RefreshIndicator(
              onRefresh: _refreshStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 16),
                  
                  // Top Graphic Illustration
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    constraints: const BoxConstraints(
                      minHeight: 180,
                      maxHeight: 280,
                    ),
                    width: double.infinity,
                    child: Image.asset(
                      'assets/images/request_order/new_request_sent_top.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[100],
                          alignment: Alignment.center,
                          child: const Text('Image not found',
                              style: TextStyle(color: Colors.red)),
                        );
                      },
                    ),
                  ),



                  // Card 1: We're on it!
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              )
                            ]
                          ),
                          child: const Icon(
                            Icons.hourglass_empty_rounded,
                            color: Color(0xFF3B82F6),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "We're on it!",
                                style: TextStyle(
                                  color: Color(0xFF0F2147),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "You'll be notified as soon as vendors respond.",
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card 2: Need Help?
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone_in_talk,
                            color: Color(0xFF2563EB),
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Need Help?",
                          style: TextStyle(
                            color: Color(0xFF0F2147),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          "Our support team is here for you.",
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ElevatedButton(
                              onPressed: _contactSupport,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    "Contact Support",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tap to call our support team",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Card 3: Trust Badges Row
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildBadge(
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF5A78FF),
                            title: "Fast Response",
                            subtitle: "We act quickly",
                          ),
                        ),
                        Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                        Expanded(
                          child: _buildBadge(
                            icon: Icons.support_agent_outlined,
                            color: const Color(0xFF5A78FF),
                            title: "24/7 Support",
                            subtitle: "We're always here",
                          ),
                        ),
                        Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                        Expanded(
                          child: _buildBadge(
                            icon: Icons.lock_outline,
                            color: const Color(0xFF5A78FF),
                            title: "Secure & Safe",
                            subtitle: "Your data is safe",
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Green Banner: Your request is safe
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF2E7D32),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Your request is safe and secure with us.",
                            style: TextStyle(
                              color: const Color(0xFF2E7D32),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
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
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool isLast = false, double scale = 1.0}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 16 * scale, color: const Color(0xFF5A78FF)),
            SizedBox(width: 12 * scale),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFF1A1A60),
                  fontSize: 13 * scale,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 6),
          Divider(color: Colors.grey[100], thickness: 1, height: 1),
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 75,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1A1A60),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
