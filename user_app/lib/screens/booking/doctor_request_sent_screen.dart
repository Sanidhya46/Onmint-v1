import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'package:user_app/screens/home/home_screen.dart';

class DoctorRequestSentScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const DoctorRequestSentScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<DoctorRequestSentScreen> createState() => _DoctorRequestSentScreenState();
}

class _DoctorRequestSentScreenState extends State<DoctorRequestSentScreen> {
  final _apiClient = OnMintApiClient();
  bool _isLoading = false;
  Map<String, dynamic> _booking = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
    _booking = widget.bookingData;
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _pollBooking());
    // Initial fetch
    _pollBooking();
  }

  Future<void> _pollBooking() async {
    try {
      final res = await _apiClient.get('/realtime-bookings/${widget.bookingId}');
      if (!mounted) return;
      
      final data = res.data['data'];
      setState(() {
        _booking = data;
      });

      final status = _booking['status'];
      if (status == 'active') {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => user_active.UserActiveConsultationScreen(bookingId: widget.bookingId),
          ),
        );
      } else if (status == 'completed' || status == 'ended') {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => user_ended.UserConsultationEndedScreen(
              bookingId: widget.bookingId,
              doctorName: 'Doctor',
              duration: 0,
            ),
          ),
        );
      }
    } catch (e) {
      // Silently ignore polling errors
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleCancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Request'),
        content: const Text('Are you sure you want to cancel this booking request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _apiClient.patch('/realtime-bookings/${widget.bookingId}/status', data: {'status': 'cancelled'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking Cancelled')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (r) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _handleReschedule() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('To reschedule, please cancel and book a new appointment.')),
    );
  }

  Future<void> _handleContactSupport() async {
    final uri = Uri.parse('tel:+918000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch dialer')));
      }
    }
  }

  Widget _buildAcceptedUI(String pName, String phone, String age, String gender, String category, DateTime dt, String formattedDate) {
    // Get doctor info
    final provider = _booking['acceptedProvider'] ?? _booking['provider'] ?? {};
    final docName = provider['fullName'] ?? '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
    final docSpec = provider['specialization'] ?? category;
    final docExp = provider['experience']?.toString() ?? '8+';
    final docImage = provider['profilePic'] ?? provider['profilePicture'];
    final timeStr = _booking['scheduledTime'] ?? DateFormat('hh:mm a').format(dt);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Accept Your Consultation Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF28A745), size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Accept Your Consultation',
                      style: TextStyle(
                        color: Color(0xFF28A745),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your consultation request has been accepted.\nYou\'re all set for your appointment.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Online Consultation Title
        const Text(
          'Online Consultation – Doctor',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF152238),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Accepted on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),

        // Doctor Card Info
        Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: docImage != null ? NetworkImage(docImage) : null,
                  child: docImage == null ? const Icon(Icons.person, size: 36, color: Colors.blue) : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: const Color(0xFF28A745),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    docName.isEmpty ? 'Dr. Shubham Singh' : (docName.startsWith('Dr') ? docName : 'Dr. $docName'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF152238),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'MBBS – $docSpec',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFB800), size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        '4.9',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF152238),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(230+ Reviews)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.verified, color: Colors.blue, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Verified Doctor',
                          style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),

        _buildInfoRow(Icons.cases_outlined, 'Experience', '$docExp Years'),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.medical_services_outlined, 'Specialization', docSpec),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.calendar_today_outlined, 'Consultation Time', timeStr),
        const SizedBox(height: 24),

        // Consultation Confirmed Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F9F4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF28A745), size: 36),
                  const SizedBox(width: 12),
                  const Text(
                    'Consultation Confirmed',
                    style: TextStyle(
                      color: Color(0xFF28A745),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.grey, size: 18),
                  const SizedBox(width: 8),
                  Text('Consultation Time:', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26.0),
                child: Text(
                  timeStr,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF152238),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${docName.isEmpty ? 'Dr. Shubham Singh' : docName} will connect with you at the scheduled time. Please be available a few minutes before the consultation.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // What's Next
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What\'s Next?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF152238),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We will notify you once the doctor is assigned.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Image.asset(
              'assets/images/request_order/doctor.png', // Temporary placeholder for clipboard graphic
              width: 80,
              height: 80,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF152238),
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPendingUI(String pName, String phone, String age, String gender, String category, DateTime dt, String formattedDate) {
    return Column(
      children: [
        // Top Title
        Row(
          children: [
            const Text(
              'Doctor',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Booking',
              style: TextStyle(
                color: Color(0xFF1A1A60),
                fontSize: 24,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.blue),
            const SizedBox(width: 6),
            Text(
              'Requested on $formattedDate',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        
        // Doctor Graphic
        Image.asset(
          'assets/images/request_order/doctor.png',
          width: double.infinity,
          height: 280,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),
        
        // Success Texts
        const Text(
          'Request Sent Successfully',
          style: TextStyle(
            color: Color(0xFF1A1A60),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We are waiting for a doctor to accept\nyour request.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
            height: 1.5,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 32),
        
        // Booking Details Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Booking Details',
                style: TextStyle(
                  color: Color(0xFF1A1A60),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(Icons.person_outline, 'Patient Name', pName),
              _buildDetailRow(Icons.phone_outlined, 'Phone Number', phone),
              _buildDetailRow(Icons.calendar_today_outlined, 'Age', '$age Years'),
              _buildDetailRow(Icons.male, 'Gender', gender),
              _buildDetailRow(Icons.medical_services_outlined, 'Doctor Category', category, isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extract patient details
    final patientData = _booking['patient'] ?? _booking['patientDetails'] ?? _booking;
    String pName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    if (pName.isEmpty || pName == 'Patient') pName = _booking['patientName'] ?? 'Ali Raza';
    
    final phone = _booking['phone'] ?? patientData['phone'] ?? '+92 300 1234567';
    final age = _booking['age'] ?? patientData['age']?.toString() ?? '45';
    final gender = _booking['gender'] ?? patientData['gender'] ?? 'Male';
    final category = _booking['category'] ?? _booking['specialization'] ?? 'General Physician';
    
    final dateStr = _booking['createdAt'] ?? DateTime.now().toIso8601String();
    DateTime dt = DateTime.now();
    try { dt = DateTime.parse(dateStr).toLocal(); } catch (_) {}
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);

    final status = _booking['status'] ?? 'pending';
    final isAccepted = status == 'accepted' || status == 'confirmed';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (r) => false,
            );
          },
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
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined, color: Color(0xFF152238)),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade100, height: 1.0),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (isAccepted)
                  _buildAcceptedUI(pName, phone, age, gender, category, dt, formattedDate)
                else
                  _buildPendingUI(pName, phone, age, gender, category, dt, formattedDate),
                
                const SizedBox(height: 24),
                
                // Bottom Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildActionButton('Reschedule', Icons.calendar_month, Colors.blue, _handleReschedule),
                    _buildActionButton('Cancel\nAppointment', Icons.close, Colors.red, _handleCancel, isRed: true),
                    _buildActionButton('Contact\nSupport', Icons.headset_mic_outlined, Colors.blue, _handleContactSupport),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1A60),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 12),
          Divider(color: Colors.grey.shade100),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap, {bool isRed = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isRed ? Colors.red : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: isRed ? Colors.white : color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF1A1A60),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
