import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:api_client/api_client.dart';
import '../doctors/doctor_categories_screen.dart';
import '../services/nurses_screen.dart';
import 'ambulance_booking_screen.dart';
import 'blood_request_screen.dart';
import 'lab_test_booking_screen.dart';

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

  void _rescheduleAppointment() {
    final type = widget.serviceType.toLowerCase();
    switch (type) {
      case 'doctor':
      case 'consultation':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorCategoriesScreen()),
        );
        break;
      case 'nurse':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NursesScreen()),
        );
        break;
      case 'ambulance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AmbulanceBookingScreen()),
        );
        break;
      case 'bloodbank':
      case 'blood bank':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BloodRequestScreen()),
        );
        break;
      case 'pathology':
      case 'lab_test':
      case 'lab test':
      case 'labtest':
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LabTestBookingScreen()),
        );
        break;
    }
  }
  
  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to Support...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.serviceType.toLowerCase();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = screenWidth < 380 ? screenWidth / 380.0 : 1.0;

    Color serviceColor;
    String serviceTitle;
    String serviceTitleBlack;
    String imagePath;

    switch (type) {
      case 'doctor':
        serviceColor = const Color(0xFF1565C0);
        serviceTitle = 'Doctor ';
        serviceTitleBlack = 'Booking';
        imagePath = 'assets/images/request_order/doctor.png';
        break;
      case 'nurse':
        serviceColor = const Color(0xFF1565C0);
        serviceTitle = 'Nurse ';
        serviceTitleBlack = 'Booking';
        imagePath = 'assets/images/request_order/nurse.png';
        break;
      case 'ambulance':
        serviceColor = Colors.red;
        serviceTitle = 'Ambulance ';
        serviceTitleBlack = 'Booking';
        imagePath = 'assets/images/request_order/ambulance.png';
        break;
      case 'bloodbank':
      case 'blood bank':
        serviceColor = Colors.red;
        serviceTitle = 'Blood Bank ';
        serviceTitleBlack = 'Booking';
        imagePath = 'assets/images/request_order/bloodbank.png';
        break;
      case 'pathology':
      case 'lab_test':
      case 'lab test':
      default:
        serviceColor = Colors.green[700]!;
        serviceTitle = 'Lab Test ';
        serviceTitleBlack = 'Booking';
        imagePath = 'assets/images/request_order/labtest.png';
        break;
    }

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
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A60)),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            }
          },
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
            color: Color(0xFF1A1A60),
            fontSize: 16,
            fontWeight: FontWeight.w700,
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
            icon: const Icon(Icons.headset_mic_outlined,
                color: Color(0xFF1A1A60)),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: serviceTitle,
                                style: TextStyle(
                                  color: serviceColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: serviceTitleBlack,
                                style: const TextStyle(
                                  color: Color(0xFF1A1A60),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_month_outlined,
                                size: 12, color: const Color(0xFF5A78FF)),
                            const SizedBox(width: 4),
                            Text(
                              'Requested on ${_extractDate(widget.bookingData)}',
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
                ),

                const SizedBox(height: 8),

                // Image Graphic containing arc, images, and text
                SizedBox(
                  width: double.infinity,
                  height: 245,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 245,
                        color: Colors.grey[100],
                        alignment: Alignment.center,
                        child: const Text('Image not found',
                            style: TextStyle(color: Colors.red)),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Booking Details Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Booking Details',
                        style: TextStyle(
                          color: Color(0xFF1A1A60),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...detailsRows,
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Bottom Actions Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.calendar_today_outlined,
                          label: 'Reschedule',
                          iconColor: const Color(0xFF1565C0),
                          onTap: _rescheduleAppointment,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.cancel,
                          label: type == 'doctor' ? 'Cancel\nAppointment' : 'Cancel\nBooking',
                          iconColor: Colors.red,
                          onTap: _cancelAppointment,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.headset_mic,
                          label: 'Contact\nSupport',
                          iconColor: const Color(0xFF1565C0),
                          onTap: _contactSupport,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
    ));
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
