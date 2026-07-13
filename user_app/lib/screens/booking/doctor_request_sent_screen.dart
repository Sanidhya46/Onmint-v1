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

class _DoctorRequestSentScreenState extends State<DoctorRequestSentScreen> with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  bool _isLoading = false;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _progressController.dispose();
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
      await _apiClient.patch('/realtime/${widget.bookingId}/status', data: {'status': 'cancelled'});
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

  @override
  Widget build(BuildContext context) {
    // Extract patient details
    final patientData = widget.bookingData['patient'] ?? widget.bookingData['patientDetails'] ?? widget.bookingData;
    String pName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    if (pName.isEmpty || pName == 'Patient') pName = widget.bookingData['patientName'] ?? 'Ali Raza';
    
    final phone = widget.bookingData['phone'] ?? patientData['phone'] ?? '+92 300 1234567';
    final age = widget.bookingData['age'] ?? patientData['age'] ?? '45';
    final gender = widget.bookingData['gender'] ?? patientData['gender'] ?? 'Male';
    final category = widget.bookingData['category'] ?? widget.bookingData['specialization'] ?? 'General Physician';
    
    final dateStr = widget.bookingData['createdAt'] ?? DateTime.now().toIso8601String();
    DateTime dt = DateTime.now();
    try { dt = DateTime.parse(dateStr); } catch (_) {}
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF5E2B97)),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF5E2B97)),
            onPressed: _handleContactSupport,
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
