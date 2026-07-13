import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:user_app/screens/booking/user_unified_tracking_screen.dart';
import 'package:user_app/screens/booking/user_video_call_screen.dart';
import 'package:user_app/screens/booking/user_active_consultation_screen.dart';
import 'package:user_app/screens/booking/active_service_tracking_screen.dart';
import 'package:user_app/screens/booking/order_request_screen.dart';
import 'package:user_app/screens/booking/service_offers_screen.dart';

class OrderDetailFile extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingData;

  const OrderDetailFile({
    Key? key,
    required this.bookingId,
    this.bookingData,
  }) : super(key: key);

  @override
  State<OrderDetailFile> createState() => _OrderDetailFileState();
}

class _OrderDetailFileState extends State<OrderDetailFile>
    with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  final _socketService = SocketService();
  bool _isLoading = true;
  Map<String, dynamic>? _booking;
  late AnimationController _animationController;
  bool _isDoctorOnCall = false;
  StreamSubscription? _doctorJoinedSub;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadBookingDetails();
    _setupSocketListener();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _doctorJoinedSub?.cancel();
    _socketService.leaveBooking(widget.bookingId);
    super.dispose();
  }

  void _setupSocketListener() {
    _socketService.joinBooking(widget.bookingId);
    _doctorJoinedSub = _socketService.doctorJoined.listen((data) {
      if (data['bookingId'] == widget.bookingId && mounted) {
        setState(() => _isDoctorOnCall = true);
      }
    });
  }

  Future<void> _loadBookingDetails() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      // Fetch fresh details to get provider and precise status
      final booking =
          await _apiClient.patient.getBookingDetails(widget.bookingId);

      if (mounted) {
        setState(() {
          _booking = booking.toJson(); // Or just use the raw map if returned
          _isLoading = false;
        });

        // Direct auto-join to live video call if doctor is on call
        final serviceType = _booking?['serviceType']?.toString().toLowerCase() ?? '';
        final isDoctorOnCall = _booking?['doctor_on_call'] == true;
        final consultationEnded = _booking?['consultation_ended'] == true;

        if (serviceType == 'doctor' && isDoctorOnCall && !consultationEnded) {
          final provD = _booking?['provider'] ?? _booking?['acceptedProvider'] ?? {};
          final drName = provD['fullName'] ??
              '${provD['firstName'] ?? ''} ${provD['lastName'] ?? ''}'.trim();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserVideoCallScreen(
                bookingId: widget.bookingId,
                doctorName: drName.isEmpty ? 'Doctor' : drName,
                doctorImage: provD['profilePicture'],
              ),
            ),
          ).then((_) => _loadBookingDetails());
        }
      }
    } catch (e) {
      // Fallback to passed booking data if api fails
      if (mounted) {
        setState(() {
          _booking = widget.bookingData;
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]}, ${date.year} - ${date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour)}:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _booking == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final booking = _booking ?? widget.bookingData ?? {};
    final status = booking['status']?.toString().toLowerCase() ?? 'pending';
    final isRequested = status == 'requested' || status == 'pending';
    final serviceType = booking['serviceType']?.toString().toLowerCase() ?? '';

    if (serviceType == 'doctor' && !isRequested) {
      if (status == 'completed') {
        return _buildDoctorCompletedScreen(booking);
      } else {
        return _buildDoctorAcceptedScreen(booking, status);
      }
    }

    if (isRequested) {
      final hasOffers = booking['offers'] is List && (booking['offers'] as List).isNotEmpty;
      if (hasOffers) {
        return ServiceOffersScreen(
          bookingId: booking['_id']?.toString() ?? booking['id']?.toString() ?? '',
          serviceType: serviceType.isEmpty ? 'doctor' : serviceType,
          bookingData: booking,
        );
      }
      // Fall through to display _buildRequestedUI in the Scaffold below
    }

    final isLabTest = serviceType == 'pathology' || serviceType == 'labtest' || serviceType == 'lab_test' || serviceType == 'lab test';

    return Scaffold(
      backgroundColor: isLabTest ? Colors.white : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
            color: Color(0xFF152238),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: isRequested
          ? _buildRequestedUI(booking)
          : _buildAcceptedUI(booking, status),
      bottomNavigationBar: _buildBottomBar(booking),
    );
  }

  Widget _buildBottomBar(Map<String, dynamic> booking) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (booking['report'] != null && booking['report'].toString().isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () async {
                  try {
                    String urlStr = booking['report'].toString().trim();
                    urlStr = urlStr.replaceAll('"', '');
                    urlStr = urlStr.replaceAll(':5000api', ':5000/api');
                    urlStr = urlStr.replaceAll('localhost', '192.168.1.6');
                    
                    if (!urlStr.startsWith('http')) {
                      urlStr = 'http://192.168.1.6:5000' + (urlStr.startsWith('/') ? urlStr : '/$urlStr');
                    }
                    
                    final uri = Uri.parse(urlStr);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      debugPrint('Could not launch $urlStr');
                    }
                  } catch (e) {
                    debugPrint('Error launching url: $e');
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('View Lab Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1565C0),
                side: const BorderSide(color: Color(0xFF1565C0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Need help?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestedUI(Map<String, dynamic> booking) {
    final createdAt = booking['createdAt']?.toString() ??
        booking['scheduledTime']?.toString() ??
        '';
    final patient = (booking['patient'] is Map) ? booking['patient'] : {};
    final serviceType =
        booking['serviceType']?.toString().toLowerCase() ?? 'lab_test';
    final pName = patient['fullName'] ??
        '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final pPhone = patient['phone'] ?? '+91 0000000000';
    final pAge = patient['age'] ?? '35';
    final address = booking['location']?['address'] ?? 'Not specified';
    final testName = (booking['tests'] != null &&
            booking['tests'] is List &&
            booking['tests'].isNotEmpty)
        ? booking['tests'][0]['name'] ?? 'Lab Test'
        : 'Lab Test';
    final bloodGroup = booking['bloodGroup']?.toString() ?? 'Unknown';
    final units = booking['units']?.toString() ?? '1';

    String topTitle;
    String waitText;
    String imagePath;
    String waitCardTitle;
    String waitCardSub;

    switch (serviceType) {
      case 'doctor':
        topTitle = 'Doctor Consultation';
        waitText = 'We are waiting for a doctor to accept\nyour request.';
        imagePath = 'assets/images/request_order/doctor.png';
        waitCardTitle = 'Waiting for doctor to accept';
        waitCardSub = 'We will notify you once a doctor accepts your request.';
        break;
      case 'nurse':
        topTitle = 'Nursing Care';
        waitText =
            'We are waiting for a nurse provider to accept\nyour request.';
        imagePath = 'assets/images/request_order/nurse.png';
        waitCardTitle = 'Waiting for nurse to accept';
        waitCardSub = 'We will notify you once a nurse accepts your request.';
        break;
      case 'ambulance':
        topTitle = 'Ambulance Booking';
        waitText =
            'We are waiting for an ambulance provider to accept\nyour request.';
        imagePath = 'assets/images/request_order/ambulance.png';
        waitCardTitle = 'Waiting for ambulance to accept';
        waitCardSub =
            'We will notify you once an ambulance accepts your request.';
        break;
      case 'bloodbank':
      case 'blood bank':
        topTitle = 'Blood Request';
        waitText = 'We are waiting for a blood unit to accept\nyour request.';
        imagePath = 'assets/images/request_order/bloodbank.png';
        waitCardTitle = 'Waiting for blood bank to accept';
        waitCardSub =
            'We will notify you once a blood bank accepts your request.';
        break;
      case 'pathology':
      case 'lab_test':
      case 'lab test':
      default:
        topTitle = 'Lab Test Booking';
        waitText = 'We are waiting for a lab partner to accept\nyour request.';
        imagePath = 'assets/images/request_order/labtest.png';
        waitCardTitle = 'Waiting for lab partner to accept';
        waitCardSub =
            'We will notify you once a technician accepts your request.';
        break;
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  topTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF152238),
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Image Section
            Image.asset(
              imagePath,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to hourglass if asset missing
                return AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2.0 * math.pi,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.hourglass_empty,
                          size: 50,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            const Text(
              'Request Sent Successfully',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF152238),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              waitText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontFamily: 'Poppins',
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),

            // Booking Details Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF152238),
                      fontFamily: 'Poppins',
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDetailRow('Patient Name', pName),
                  const SizedBox(height: 16),
                  _buildDetailRow('Phone Number', pPhone),
                  const SizedBox(height: 16),
                  _buildDetailRow('Age', '$pAge Years'),
                  if (serviceType == 'pathology' ||
                      serviceType == 'lab_test' ||
                      serviceType == 'lab test') ...[
                    const SizedBox(height: 16),
                    _buildDetailRow('Test Name', testName),
                  ],
                  if (serviceType == 'bloodbank' ||
                      serviceType == 'blood bank') ...[
                    const SizedBox(height: 16),
                    _buildDetailRow('Blood Group', bloodGroup),
                    const SizedBox(height: 16),
                    _buildDetailRow('Units', units),
                  ],
                  const SizedBox(height: 16),
                  _buildDetailRow('Location', address),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Waiting Status Card
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.shade100),
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.info_outline,
                        color: Color(0xFF1565C0)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          waitCardTitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF152238),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          waitCardSub,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedUI(Map<String, dynamic> booking, String status) {
    final providerData = booking['provider'] ?? booking['acceptedProvider'];
    final provider = (providerData is Map) ? providerData : {};
    final prName = provider['fullName'] ??
        '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
    final prRating = provider['rating']?.toString() ?? '4.8';
    final prPhone = provider['phone']?.toString() ?? '';

    // Status map
    final steps = [
      {'key': 'accepted', 'title': 'Connected'},
      {'key': 'on_the_way', 'title': 'On The Way'},
      {'key': 'sample_collected', 'title': 'Sample Collected'},
      {'key': 'report_ready', 'title': 'Report Ready'},
      {'key': 'completed', 'title': 'Completed'},
    ];

    int currentIndex = -1;
    if (status == 'accepted')
      currentIndex = 0;
    else if (status == 'on_the_way')
      currentIndex = 1;
    else if (status == 'sample_collected')
      currentIndex = 2;
    else if (status == 'report_ready')
      currentIndex = 3;
    else if (status == 'completed') currentIndex = 4;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Technician Card
            const Text(
              'Your Technician',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF152238),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/male_profile.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prName.isNotEmpty ? prName : 'Lab Technician',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF152238),
                            fontFamily: 'Poppins',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              prRating,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          if (prPhone.isNotEmpty) {
                            final uri = Uri.parse('tel:$prPhone');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri);
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.call,
                              color: Colors.green, size: 20),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          // TODO: implement chat
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat,
                              color: Colors.blue, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Doctor On Call - Join Call Banner
            if (booking['serviceType']?.toString().toLowerCase() == 'doctor' &&
                (_isDoctorOnCall || booking['doctor_on_call'] == true) &&
                booking['consultation_ended'] != true)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF107C41), Color(0xFF0D6634)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.6),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Doctor is Ready — Join Call Now!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final provD = booking['provider'] ?? booking['acceptedProvider'] ?? {};
                          final drName = provD['fullName'] ??
                              '${provD['firstName'] ?? ''} ${provD['lastName'] ?? ''}'.trim();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserVideoCallScreen(
                                bookingId: widget.bookingId,
                                doctorName: drName.isEmpty ? 'Doctor' : drName,
                                doctorImage: provD['profilePicture'],
                              ),
                            ),
                          ).then((_) => _loadBookingDetails());
                        },
                        icon: const Icon(Icons.videocam, size: 20),
                        label: const Text('Join Video Call',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF107C41),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Live Status
            const Text(
              'Live Status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF152238),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: List.generate(steps.length, (index) {
                  final isActive = index <= currentIndex;
                  final isLast = index == steps.length - 1;
                  return _buildTimelineStep(
                    title: steps[index]['title']!,
                    isActive: isActive,
                    isLast: isLast,
                  );
                }),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF152238),
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStep(
      {required String title, required bool isActive, required bool isLast}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? Colors.green : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: isActive
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isActive ? Colors.green : Colors.grey.shade200,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive ? const Color(0xFF152238) : Colors.grey.shade500,
              fontFamily: 'Poppins',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorAcceptedScreen(Map<String, dynamic> booking, String status) {
    final providerData = booking['provider'] ?? booking['acceptedProvider'];
    final provider = (providerData is Map) ? providerData : {};
    final drName = provider.isNotEmpty
        ? 'Dr. ${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim()
        : 'Assigning Doctor...';
    final drSpecialty = provider.isNotEmpty
        ? (provider['specialization'] ?? booking['category'] ?? 'General Physician')
        : (booking['category'] ?? 'General Physician');
    final drExperience = provider.isNotEmpty
        ? '${provider['experience'] ?? 8}+ Years'
        : '8+ Years';
    final drRating = provider.isNotEmpty
        ? (provider['rating']?.toString() ?? '4.9')
        : '4.9';
    final drReviews = provider.isNotEmpty
        ? '${provider['reviewsCount'] ?? 230}+ Reviews'
        : '230+ Reviews';
    final isAssigned = provider.isNotEmpty;
    
    // Scheduled time formatting
    String scheduledTimeStr = '10:00 AM';
    String acceptedDateStr = 'Accepted on 12 May 2025, 09:30 AM';
    try {
      final scheduledTime = booking['scheduledTime'] ?? booking['createdAt'];
      if (scheduledTime != null) {
        final date = DateTime.parse(scheduledTime).toLocal();
        scheduledTimeStr = DateFormat('hh:mm a').format(date);
        acceptedDateStr = 'Accepted on ' + DateFormat('dd MMM yyyy, hh:mm a').format(date);
      }
    } catch (_) {}

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
            color: Color(0xFF152238),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined, color: Colors.green),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Accept Consultation Success Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Accept Your Consultation',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isAssigned 
                              ? 'Your consultation request has been accepted. You\'re all set for your appointment.'
                              : 'We are currently assigning a doctor to your consultation request.',
                          style: TextStyle(color: Colors.green[800], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Header info
            const Text(
              'Online Consultation – Doctor',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF152238)),
            ),
            const SizedBox(height: 4),
            Text(
              acceptedDateStr,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const SizedBox(height: 20),

            // Doctor details card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 36,
                            backgroundColor: Colors.blue[50],
                            backgroundImage: provider['profilePicture'] != null && provider['profilePicture'].toString().startsWith('http')
                                ? NetworkImage(provider['profilePicture'])
                                : null,
                            child: provider['profilePicture'] == null || !provider['profilePicture'].toString().startsWith('http')
                                ? const Icon(Icons.person, size: 36, color: Colors.blue)
                                : null,
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: isAssigned ? Colors.green : Colors.grey,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              drName,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF152238)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isAssigned ? 'MBBS - $drSpecialty' : drSpecialty,
                              style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$drRating ($drReviews)',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF152238)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified, color: Colors.blue[700], size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified Doctor',
                                    style: TextStyle(color: Colors.blue[700], fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  _buildDoctorDetailRow(Icons.business_center, 'Experience', drExperience),
                  _buildDoctorDetailRow(Icons.healing, 'Specialization', drSpecialty),
                  _buildDoctorDetailRow(Icons.access_time, 'Consultation Time', scheduledTimeStr, isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Consultation Confirmed Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC8E6C9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Consultation Confirmed',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: Colors.green),
                      const SizedBox(width: 6),
                      Text(
                        'Consultation Time: $scheduledTimeStr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isAssigned 
                        ? '$drName will connect with you at the scheduled time. Please be available a few minutes before the consultation.'
                        : 'Your doctor will connect with you at the scheduled time. Please keep the app open.',
                    style: TextStyle(color: Colors.green[800], fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // What's Next Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What\'s Next?',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF152238)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isAssigned 
                            ? 'We will notify you once the doctor starts the call.'
                            : 'We will notify you once the doctor is assigned.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.assignment, size: 48, color: Colors.blue[100]),
              ],
            ),
            const SizedBox(height: 30),

            // Bottom action buttons
            Row(
              children: [
                Expanded(
                  child: _buildDoctorActionButton(
                    icon: Icons.calendar_today,
                    label: 'Reschedule',
                    color: Colors.blue,
                    onTap: _rescheduleAppointment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDoctorActionButton(
                    icon: Icons.cancel,
                    label: 'Cancel Appointment',
                    color: Colors.red,
                    onTap: _cancelAppointment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDoctorActionButton(
                    icon: Icons.headset_mic,
                    label: 'Contact Support',
                    color: Colors.blue,
                    onTap: _contactSupport,
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCompletedScreen(Map<String, dynamic> booking) {
    final providerData = booking['provider'] ?? booking['acceptedProvider'];
    final provider = (providerData is Map) ? providerData : {};
    final drName = provider.isNotEmpty
        ? 'Dr. ${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim()
        : 'Doctor';
    final drSpecialty = provider.isNotEmpty
        ? (provider['specialization'] ?? booking['category'] ?? 'General Physician')
        : (booking['category'] ?? 'General Physician');
    final drRating = provider.isNotEmpty
        ? (provider['rating']?.toString() ?? '4.9')
        : '4.9';
    final drReviews = provider.isNotEmpty
        ? '${provider['reviewsCount'] ?? 230}+ Reviews'
        : '230+ Reviews';
    final drImage = provider['profilePicture']?.toString() ?? '';

    String consultationDate = '13 May 2025';
    String consultationTime = '10:00 AM';
    String acceptedDateStr = '12 May, 09:30 AM';
    try {
      final scheduledTime = booking['scheduledTime'] ?? booking['createdAt'];
      if (scheduledTime != null) {
        final sDate = DateTime.parse(scheduledTime).toLocal();
        consultationDate = DateFormat('dd MMM yyyy').format(sDate);
        consultationTime = DateFormat('hh:mm a').format(sDate);
      }
      final acceptedAt = booking['acceptedAt'] ?? booking['createdAt'];
      if (acceptedAt != null) {
        final aDate = DateTime.parse(acceptedAt).toLocal();
        acceptedDateStr = DateFormat('dd MMM, hh:mm a').format(aDate);
      }
    } catch (_) {}

    final hasPrescription = booking['prescription'] != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
            color: Color(0xFF152238),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined, color: Color(0xFF152238)),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: drImage.startsWith('http') ? NetworkImage(drImage) : null,
                          onBackgroundImageError: drImage.startsWith('http') ? (e, s) {} : null,
                          child: !drImage.startsWith('http')
                              ? const Icon(Icons.person, size: 38, color: Colors.blue)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                drName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF152238),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'MBBS - $drSpecialty',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$drRating ($drReviews)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF152238),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE3F2FD),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified, color: Colors.blue, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Verified Doctor',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Three column stats grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.calendar_today_outlined,
                          title: 'Consultation Time',
                          value: '$consultationDate\n$consultationTime',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.timer_outlined,
                          title: 'Consultation Duration',
                          value: booking['duration'] != null ? '${booking['duration']} mins' : '05:24',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.lock_outline,
                          title: 'Secure & Private',
                          value: 'Your consultation is\nsafe with us',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Blue Banner Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F7FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE1EBFD),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.videocam_outlined, color: Colors.blue, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasPrescription ? 'Consultation Completed' : 'Complete your consultation',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1A3B8B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                hasPrescription 
                                    ? 'Your consultation session is finished. Download your prescription below.' 
                                    : 'Your consultation is in progress. Please complete the session to help the doctor understand your health better.',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF4A6BB6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.healing_outlined, color: Color(0xFFB9D0FD), size: 36),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Horizontal Timeline
                  _buildHorizontalTimeline(booking, acceptedDateStr, consultationTime, hasPrescription),
                  const SizedBox(height: 24),

                  // Recall Doctor Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Recall (Call Again)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF152238),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'If the call got disconnected,\nyou can call the doctor again.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (booking['meetingLink'] != null) {
                              launchUrl(Uri.parse(booking['meetingLink']));
                            }
                          },
                          icon: const Icon(Icons.phone_in_talk, size: 14, color: Colors.blue),
                          label: const Text('Recall Doctor', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Security Banner Tile
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F9FF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade50),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified, color: Colors.blue, size: 18),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your consultation is secure and encrypted.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF152238),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.blue, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom button / Status text
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: hasPrescription
                  ? SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (booking['prescriptionUrl'] != null) {
                            launchUrl(Uri.parse(booking['prescriptionUrl']));
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('No prescription URL available')),
                            );
                          }
                        },
                        icon: const Icon(Icons.description, color: Colors.white, size: 18),
                        label: const Text(
                          'Go to Download Prescription',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32), // Green color
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    )
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Waiting for prescription to be uploaded...',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.blue, size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF152238),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline(Map<String, dynamic> booking, String acceptedDate, String consultationTime, bool hasPrescription) {
    return Row(
      children: [
        // Step 1: Accepted
        Expanded(
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Accepted',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 2),
              Text(
                acceptedDate,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),

        // Line 1
        Container(
          width: 30,
          height: 2,
          color: Colors.green,
        ),

        // Step 2: Complete Consultant
        Expanded(
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 16),
              ),
              const SizedBox(height: 8),
              const Text(
                'Complete Consultant',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(height: 2),
              Text(
                'Started $consultationTime',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),

        // Line 2
        Container(
          width: 30,
          height: 2,
          color: hasPrescription ? Colors.green : Colors.grey.shade300,
        ),

        // Step 3: Download Prescription
        Expanded(
          child: Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: hasPrescription ? Colors.green : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasPrescription ? Colors.green : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: hasPrescription
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                'Download Prescription',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: hasPrescription ? Colors.green : Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                hasPrescription ? 'Completed' : 'Pending',
                style: TextStyle(
                  fontSize: 10,
                  color: hasPrescription ? Colors.green : Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF152238))),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorDetailRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF1565C0), size: 18),
                const SizedBox(width: 8),
                Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w500)),
              ],
            ),
            Text(value, style: const TextStyle(color: Color(0xFF152238), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        if (!isLast) const Divider(height: 20),
      ],
    );
  }

  Widget _buildDoctorActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF152238)),
            ),
          ],
        ),
      ),
    );
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

    setState(() => _isLoading = true);
    try {
      final patientService = PatientService();
      await patientService.cancelBooking(widget.bookingId,
          reason: 'Patient cancelled');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment cancelled successfully')),
        );
        Navigator.pop(context, true);
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
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to Support...')),
    );
  }
}
