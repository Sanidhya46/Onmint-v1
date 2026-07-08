import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class UserActiveNurseTrackingScreen extends StatefulWidget {
  final String bookingId;

  const UserActiveNurseTrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<UserActiveNurseTrackingScreen> createState() =>
      _UserActiveNurseTrackingScreenState();
}

class _UserActiveNurseTrackingScreenState
    extends State<UserActiveNurseTrackingScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.patient.getBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
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
            child: Text('Booking not found',
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
              _buildActionButtonsRow(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(String status) {
    final provider =
        _booking!['acceptedProvider'] ?? _booking!['provider'] ?? {};
    final fullName = provider['fullName'] ??
        '${provider['firstName'] ?? ''} ${provider['lastName'] ?? ''}'.trim();
    final gender = provider['gender'] ?? 'Female';
    final age = _calculateAge(provider['dateOfBirth']);

    final price = _booking!['price'] ??
        _booking!['totalAmount'] ??
        _booking!['fees'] ??
        499;

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
      case 'on_the_way':
        headerTitle = 'Nurse is On The Way';
        subTitle = 'The nurse is heading to your location.';
        headerIcon = Icons.two_wheeler;
        break;
      case 'in_progress':
        headerTitle = 'Nurse Reached';
        subTitle = 'The nurse has arrived at your location.';
        headerIcon = Icons.location_on;
        break;
      case 'completed':
        headerTitle = 'Service Completed';
        subTitle = 'The nursing service has been completed.';
        headerIcon = Icons.check_circle;
        break;
      case 'requested':
        headerTitle = 'Searching for Nurse';
        subTitle = 'Waiting for a nearby nurse to accept.';
        headerIcon = Icons.search;
        break;
      case 'accepted':
      default:
        headerTitle = 'Connected';
        subTitle =
            '${fullName.isEmpty ? "A nurse" : fullName} has accepted your request.';
        headerIcon = Icons.check_circle;
        break;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: double.infinity,
          height: 260,
          color: const Color(0xFF0D47A1), // Dark blue top section
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
                        'Booking Status',
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

        // Nurse Details Overlapping Card
        if (status != 'requested')
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
                                      const Icon(Icons.medical_services, color: Color(0xFF0D47A1), size: 32),
                                ),
                              )
                            : const Icon(Icons.medical_services, color: Color(0xFF0D47A1), size: 32),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName.isEmpty ? 'Nurse' : fullName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF152238),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  gender.toLowerCase() == 'female'
                                      ? Icons.female
                                      : Icons.male,
                                  size: 14,
                                  color: Colors.pinkAccent,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$gender • $age',
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 3,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.workspace_premium,
                                size: 16, color: Color(0xFF1565C0)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Verified Professional Nurse\nCertified & Background Checked',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Icon(Icons.calendar_month_outlined,
                                    size: 14, color: Color(0xFF1565C0)),
                                const SizedBox(width: 6),
                                Text(
                                  formattedDate,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formattedTime,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹$price',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const Text(
                              'Paid securely',
                              style:
                                  TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
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
    if (status == 'requested') {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Center(
          child: Column(
            children: [
              CircularProgressIndicator(color: Color(0xFF1565C0)),
              SizedBox(height: 16),
              Text('Looking for nearby nurses...',
                  style: TextStyle(
                      color: Colors.grey, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }

    // Determine current step index
    int stepIndex = 0;
    if (status == 'on_the_way') stepIndex = 1;
    if (status == 'in_progress') stepIndex = 2; // Reached
    if (status == 'completed') stepIndex = 3;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Progress',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildProgressStep('Connected', Icons.check, stepIndex >= 0, isFirst: true),
              ),
              _buildProgressLine(stepIndex >= 1),
              Expanded(
                flex: 2,
                child: _buildProgressStep('On The Way', Icons.two_wheeler, stepIndex >= 1),
              ),
              _buildProgressLine(stepIndex >= 2),
              Expanded(
                flex: 2,
                child: _buildProgressStep('Reached', Icons.location_on, stepIndex >= 2),
              ),
              _buildProgressLine(stepIndex >= 3),
              Expanded(
                flex: 2,
                child: _buildProgressStep('Completed', Icons.flag, stepIndex >= 3, isLast: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(String label, IconData icon, bool isCompleted,
      {bool isFirst = false, bool isLast = false}) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green : Colors.white,
            shape: BoxShape.circle,
            border: isCompleted
                ? null
                : Border.all(color: Colors.grey.shade300, width: 2),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isCompleted ? Colors.white : Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isCompleted ? Colors.green : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isCompleted ? 'Just Now' : 'Pending',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 30), // Align with circles
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    final status = _booking!['status'];
    if (status == 'requested') return const SizedBox.shrink();

    final provider = _booking!['acceptedProvider'] ?? _booking!['provider'];
    final providerPhone = provider != null ? provider['phone'] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionButton(Icons.phone, 'Call Nurse', () {
            if (providerPhone != null) {
              _makePhoneCall(providerPhone);
            }
          }),
          _buildActionButton(Icons.chat, 'Chat', () {}),
          _buildActionButton(Icons.security, 'SOS', () {}),
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

  String _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return '28 Years'; // Fallback
    try {
      final birthDate = DateTime.parse(dateOfBirth.toString());
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return '$age Years';
    } catch (e) {
      return '28 Years';
    }
  }
}
