import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/screens/booking/user_consultation_ended_screen.dart';
import 'package:user_app/screens/home/home_screen.dart';

class UserActiveConsultationScreen extends StatefulWidget {
  final String bookingId;

  const UserActiveConsultationScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<UserActiveConsultationScreen> createState() => _UserActiveConsultationScreenState();
}

class _UserActiveConsultationScreenState extends State<UserActiveConsultationScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  Timer? _pollingTimer;
  Timer? _durationTimer;
  int _durationSeconds = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollBooking();
    });
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startTime != null && mounted) {
        setState(() {
          _durationSeconds = DateTime.now().difference(_startTime!).inSeconds;
        });
      }
    });
  }

  Future<void> _pollBooking() async {
    try {
      final res = await _apiClient.get('/realtime-bookings/${widget.bookingId}');
      if (!mounted) return;
      
      final data = res.data['data'];
      if (data == null) return;

      setState(() {
        _booking = data;
      });

      if (_startTime == null && _booking!['actualStartTime'] != null) {
        _startTime = DateTime.parse(_booking!['actualStartTime']).toLocal();
        _startDurationTimer();
      }

      final status = _booking!['status'];
      if (status == 'completed' || status == 'ended') {
        _pollingTimer?.cancel();
        _durationTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserConsultationEndedScreen(
              bookingId: widget.bookingId,
              doctorName: 'Doctor',
              duration: _durationSeconds,
            ),
          ),
        );
      }
    } catch (e) {
      // Silently ignore polling errors
    }
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/realtime-bookings/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = res.data['data'];
          _isLoading = false;
        });
        
        if (_booking != null && _booking!['actualStartTime'] != null) {
          _startTime = DateTime.parse(_booking!['actualStartTime']).toLocal();
          _startDurationTimer();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _durationTimer?.cancel();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Map<String, dynamic> _getSafeProvider(Map<String, dynamic>? bookingData) {
    if (bookingData == null) return {};
    var p = bookingData['acceptedProvider'] ?? bookingData['provider'];
    if (p is List) {
      return p.isNotEmpty && p.first is Map ? Map<String, dynamic>.from(p.first) : {};
    }
    if (p is Map) {
      return Map<String, dynamic>.from(p);
    }
    return {};
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} min';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, 
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(child: Text('Consultation not found')),
      );
    }

    final provider = _getSafeProvider(_booking);
    final docName = provider['fullName'] ?? '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
    final docSpec = provider['specialization'] ?? _booking!['category'] ?? 'General Physician';
    final docImage = provider['profilePic'] ?? provider['profilePicture'];
    
    String startTimeStr = '10:00 AM';
    if (_startTime != null) {
      startTimeStr = DateFormat('hh:mm a').format(_startTime!);
    } else if (_booking!['scheduledTime'] != null) {
      startTimeStr = _booking!['scheduledTime'];
    } else if (_booking!['createdAt'] != null) {
      startTimeStr = DateFormat('hh:mm a').format(DateTime.parse(_booking!['createdAt']).toLocal());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade50,
                  backgroundImage: docImage != null ? NetworkImage(docImage) : null,
                  child: docImage == null ? const Icon(Icons.person, size: 30, color: Colors.blue) : null,
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _buildInfoCard(Icons.calendar_today_outlined, 'Consultation Time', startTimeStr)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(Icons.timer_outlined, 'Consultation Duration', _formatDuration(_durationSeconds))),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(Icons.security, 'Secure &\nPrivate', '')),
              ],
            ),
            const SizedBox(height: 32),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/request_order/doctor.png',
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Complete your consultation',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF152238),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your consultation is in progress.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildTimelineStep(
                    icon: Icons.check,
                    title: 'Accepted',
                    isCompleted: true,
                  ),
                  _buildTimelineLine(isCompleted: true),
                  _buildTimelineStep(
                    icon: Icons.radio_button_checked,
                    title: 'Complete Consultant',
                    subtitle: 'Started $startTimeStr',
                    isCompleted: true,
                    isCurrent: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recall (Call Again)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF152238),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'If the call got disconnected, you can call the doctor again.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      final phone = provider['phone'] ?? _booking!['doctorPhone'];
                      if (phone != null) _makePhoneCall(phone);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    child: const Text('Recall Doctor', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              height: 1.2,
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF152238),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep({required IconData icon, required String title, String? subtitle, required bool isCompleted, bool isCurrent = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFF28A745) : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted ? Colors.white : Colors.grey.shade400,
            size: 16,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  color: isCompleted ? const Color(0xFF152238) : Colors.grey.shade500,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineLine({required bool isCompleted}) {
    return Container(
      margin: const EdgeInsets.only(left: 13),
      height: 32,
      child: VerticalDivider(
        color: isCompleted ? const Color(0xFF28A745) : Colors.grey.shade200,
        thickness: 2,
      ),
    );
  }
}
