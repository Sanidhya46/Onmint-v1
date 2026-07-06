import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/screens/booking/user_video_call_screen.dart';
import 'package:user_app/screens/booking/user_consultation_ended_screen.dart';

class UserActiveConsultationScreen extends StatefulWidget {
  final String bookingId;

  const UserActiveConsultationScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<UserActiveConsultationScreen> createState() =>
      _UserActiveConsultationScreenState();
}

class _UserActiveConsultationScreenState
    extends State<UserActiveConsultationScreen> {
  final _apiClient = OnMintApiClient();
  final _socketService = SocketService();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isDoctorOnCall = false;
  StreamSubscription? _consultationEndedSub;
  StreamSubscription? _doctorJoinedSub;

  @override
  void initState() {
    super.initState();
    _loadBooking();
    _setupSocketListeners();
  }

  @override
  void dispose() {
    _consultationEndedSub?.cancel();
    _doctorJoinedSub?.cancel();
    _socketService.leaveBooking(widget.bookingId);
    super.dispose();
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


  void _setupSocketListeners() {
    _socketService.joinBooking(widget.bookingId);

    _doctorJoinedSub = _socketService.doctorJoined.listen((data) {
      if (data['bookingId'] == widget.bookingId && mounted) {
        setState(() => _isDoctorOnCall = true);
      }
    });

    _consultationEndedSub = _socketService.consultationEnded.listen((data) {
      if (data['bookingId'] == widget.bookingId && mounted) {
        final provider = _getSafeProvider(_booking);
        final fullName = provider['fullName'] ??
            '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserConsultationEndedScreen(
              bookingId: widget.bookingId,
              doctorName: fullName.isEmpty ? 'Doctor' : fullName,
              duration: data['duration'] is int ? data['duration'] : 0,
            ),
          ),
        );
      }
    });
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.patient.getBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = data.toJson();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading consultation: $e')),
        );
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

  Future<void> _joinVideoCall() async {
    final provider = _getSafeProvider(_booking);
    final fullName = provider['fullName'] ??
        '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
        
    final videoCallLink = _booking!['videoCallLink'];

    if (videoCallLink != null && videoCallLink.toString().isNotEmpty) {
      final uri = Uri.parse(videoCallLink.toString());
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        debugPrint('Could not launch video call link: $e');
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserVideoCallScreen(
          bookingId: widget.bookingId,
          doctorName: fullName.isEmpty ? 'Doctor' : fullName,
          doctorImage: provider['profilePicture'],
        ),
      ),
    );

    // Reload booking after returning
    _loadBooking();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1565C0),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1565C0),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(
            child: Text('Consultation not found',
                style: TextStyle(color: Colors.white))),
      );
    }

    final status = _booking!['status'] ?? 'accepted';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: RefreshIndicator(
        onRefresh: _loadBooking,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildTopSection(status),
              const SizedBox(height: 110), // Space for overlapping card
              _buildServiceProgress(status),
              const SizedBox(height: 16),
              if (status == 'in_progress') _buildJoinCallAction(),
              if (status != 'in_progress') _buildActionButtonsRow(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(String status) {
    final provider = _getSafeProvider(_booking);
    final fullName = provider['fullName'] ??
        '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
    final specialization = provider['specialization'] ?? 'Doctor';

    final price = _booking!['price'] ??
        _booking!['totalAmount'] ??
        _booking!['fees'] ??
        300;

    String formattedDate = 'Unknown';
    String formattedTime = 'Unknown';
    if (_booking!['createdAt'] != null) {
      final date = DateTime.tryParse(_booking!['createdAt']);
      if (date != null) {
        formattedDate = DateFormat('dd MMM yyyy').format(date);
        formattedTime = DateFormat('hh:mm a').format(date);
      }
    }

    // Status UI Configuration
    String headerTitle;
    String subTitle;
    IconData headerIcon;

    switch (status) {
      case 'in_progress':
        headerTitle = 'Consultation Live';
        subTitle = 'The doctor is ready and waiting for you.';
        headerIcon = Icons.videocam;
        break;
      case 'completed':
        headerTitle = 'Consultation Completed';
        subTitle = 'The doctor has ended the consultation.';
        headerIcon = Icons.check_circle;
        break;
      case 'requested':
      case 'pending':
        headerTitle = 'Request Pending';
        subTitle = 'Waiting for doctor to accept.';
        headerIcon = Icons.access_time;
        break;
      case 'accepted':
      default:
        headerTitle = 'Request Accepted';
        subTitle =
            '${fullName.isEmpty ? "The doctor" : fullName} has accepted your request.';
        headerIcon = Icons.check_circle;
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 260,
          decoration: const BoxDecoration(
            color: Color(0xFF0D47A1),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text(
                        'Active Consultation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        onPressed: _loadBooking,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(headerIcon, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      headerTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  subTitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Doctor Details Overlapping Card
        if (status != 'requested' && status != 'pending')
          Positioned(
            bottom: -90,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: provider['profilePicture'] != null
                            ? ClipOval(
                                child: Image.network(
                                  provider['profilePicture'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.person, color: Color(0xFF0D47A1), size: 32),
                                ),
                              )
                            : const Icon(Icons.person, color: Color(0xFF0D47A1), size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty ? 'Doctor' : fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF152238),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              specialization,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_outlined,
                                  size: 16, color: Color(0xFF1565C0)),
                              const SizedBox(width: 6),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 22.0),
                            child: Text(
                              formattedTime,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹$price',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'Paid Securely',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildServiceProgress(String status) {
    if (status == 'requested' || status == 'pending') {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF1565C0)),
              SizedBox(height: 16),
              Text('Waiting for Doctor to accept...',
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    bool isLive = status == 'in_progress';
    bool isCompleted = status == 'completed';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Consultation Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildProgressStep('Accepted', Icons.check, true, 'Done'),
              _buildProgressLine(isLive || isCompleted),
              _buildProgressStep(
                  'In Consultation',
                  Icons.videocam,
                  isCompleted || isLive,
                  isLive ? 'Live Now' : (isCompleted ? 'Done' : 'Upcoming'),
                  isActive: isLive),
              _buildProgressLine(isCompleted),
              _buildProgressStep('Completed', Icons.flag, isCompleted,
                  isCompleted ? 'Done' : 'Upcoming',
                  isGrey: !isCompleted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(
      String label, IconData icon, bool isCompleted, String subLabel,
      {bool isActive = false, bool isGrey = false}) {
    Color mainColor;
    if (isActive) {
      mainColor = Colors.blue;
    } else if (isCompleted) {
      mainColor = Colors.green;
    } else {
      mainColor = Colors.grey.shade300;
    }

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCompleted || isActive ? mainColor : Colors.white,
            shape: BoxShape.circle,
            border: isCompleted || isActive
                ? null
                : Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color:
                isCompleted || isActive ? Colors.white : Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: mainColor == Colors.grey.shade300
                ? Colors.grey.shade600
                : mainColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subLabel,
          style: TextStyle(
            fontSize: 10,
            color: isActive ? Colors.blue : Colors.grey.shade500,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30),
        color: isCompleted ? Colors.green : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildJoinCallAction() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text(
            'Doctor has started the call',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text('Please join the consultation room.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _joinVideoCall,
              icon: const Icon(Icons.videocam),
              label: const Text('Join Consultation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF43A047),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    final status = _booking!['status'];
    if (status == 'requested' || status == 'completed')
      return const SizedBox.shrink();

    final provider = _getSafeProvider(_booking);
    final providerPhone = provider['phone'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildActionButton(Icons.phone, 'Call Clinic', () {
            if (providerPhone != null) {
              _makePhoneCall(providerPhone);
            }
          }),
          _buildActionButton(Icons.chat, 'Chat', () {}),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF152238),
            ),
          ),
        ],
      ),
    );
  }
}
