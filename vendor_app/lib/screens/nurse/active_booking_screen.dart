import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ui_components/ui_components.dart';

class ActiveBookingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingData;

  const ActiveBookingScreen({
    super.key,
    required this.bookingId,
    this.bookingData,
  });

  @override
  State<ActiveBookingScreen> createState() => _ActiveBookingScreenState();
}

class _ActiveBookingScreenState extends State<ActiveBookingScreen> {
  final _apiClient = OnMintApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _bookingDetails;
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
    setState(() => _isLoading = true);
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isActing = true);
    try {
      await _apiClient.initialize();
      final isRealtime = (_bookingDetails ?? widget.bookingData ?? {})['isRealtimeBooking'] == true || (_bookingDetails ?? widget.bookingData ?? {})['bookingType'] == 'realtime';

      if (isRealtime) {
        await _apiClient.nurse.updateRealtimeBookingStatus(widget.bookingId, newStatus);
      } else {
        if (newStatus == 'completed') {
          await _apiClient.nurse.completeVisit(widget.bookingId);
        } else if (newStatus == 'reached') {
          await _apiClient.nurse.startVisit(widget.bookingId); 
        } else if (newStatus == 'on_the_way') {
          try {
            await _apiClient.nurse.startVisit(widget.bookingId);
          } catch (e) {}
        }
      }
      
      if (mounted) {
        setState(() {
          if (_bookingDetails != null) {
            _bookingDetails!['status'] = newStatus;
          }
        });
        ToastUtils.showSuccess('Status updated to $newStatus');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to update status');
      }
    } finally {
      if (mounted) {
        setState(() => _isActing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bookingDetails == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text('Order not found')),
      );
    }

    final booking = _bookingDetails!;
    final patientData = booking['patient'] ?? booking['patientDetails'] ?? {};
    
    final fullName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Umeya Khan' : fullName;
    final age = patientData['age']?.toString() ?? '27';
    final gender = patientData['gender'] ?? 'Female';
    final phone = patientData['phone'] ?? '';
    final profilePicture = patientData['profilePicture']?.toString() ?? '';
    
    final locationData = booking['location'];
    final address = (locationData is Map && locationData['address'] != null) 
        ? locationData['address'] 
        : 'Not specified';

    // Dates
    String dateStr = '13 May 2025';
    String timeStr = '10:00 AM';
    if (booking['createdAt'] != null) {
      final dt = DateTime.tryParse(booking['createdAt'].toString());
      if (dt != null) {
        dateStr = DateFormat('dd MMM yyyy').format(dt);
        timeStr = DateFormat('hh:mm a').format(dt);
      }
    }

    final status = booking['status']?.toString().toLowerCase() ?? 'accepted';
    final fees = booking['fees'] ?? booking['price'] ?? booking['totalAmount'] ?? 300;
    
    final notes = booking['notes'] ?? booking['requirements']?['description'] ?? 'Requires experienced nurse';
    final serviceType = booking['title'] ?? booking['serviceType'] ?? 'Baby & Mother Care';

    return _buildConnectedScreen(booking, displayName, age, gender, phone, address, fees, notes, serviceType);
  }

  Widget _buildRowItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF152238)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF152238)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline(String status) {
    int currentIndex = 0;
    if (status == 'on_the_way') {
      currentIndex = 1;
    } else if (status == 'reached' || status == 'in_progress') {
      currentIndex = 2;
    } else if (status == 'completed') {
      currentIndex = 3;
    }

    // Time mock logic (should be real from booking data ideally)
    String timeAccepted = 'Just Now';
    String timeOnWay = currentIndex >= 1 ? '10:05 AM' : '--:--';
    String timeReached = currentIndex >= 2 ? '10:30 AM' : '--:--';
    String timeComplete = currentIndex >= 3 ? '11:00 AM' : '--:--';

    return Stack(
      children: [
        // Background lines
        Positioned(
          top: 11,
          left: 40,
          right: 40,
          child: Row(
            children: [
              Expanded(child: Container(height: 2, color: 0 < currentIndex ? Colors.green : Colors.grey.shade300)),
              Expanded(child: Container(height: 2, color: 1 < currentIndex ? Colors.green : Colors.grey.shade300)),
              Expanded(child: Container(height: 2, color: 2 < currentIndex ? Colors.green : Colors.grey.shade300)),
            ],
          ),
        ),
        // Nodes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildTimelineNode('Accepted', timeAccepted, 0 <= currentIndex)),
            Expanded(child: _buildTimelineNode('On The Way', timeOnWay, 1 <= currentIndex)),
            Expanded(child: _buildTimelineNode('Reached', timeReached, 2 <= currentIndex)),
            Expanded(child: _buildTimelineNode('Complete', timeComplete, 3 <= currentIndex)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineNode(String label, String timeLabel, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.green : Colors.green,
              width: 2,
            ),
          ),
          child: isActive
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.green : Colors.grey.shade600,
          ),
        ),
        Text(
          timeLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectedScreen(
    Map<String, dynamic> booking,
    String displayName,
    String age,
    String gender,
    String phone,
    String address,
    dynamic fees,
    String notes,
    String serviceType,
  ) {
    final String pName = displayName.isEmpty ? 'Rahul Sharma' : displayName;
    final String displayPhone = phone.isEmpty ? '+91 98765 43210' : phone;

    final requestedOn = booking['createdAt'] != null ? DateTime.tryParse(booking['createdAt']) : DateTime.now();
    final String displayDate = requestedOn != null ? DateFormat('dd MMM yyyy').format(requestedOn) : '01 Jul 2026';
    
    String displayTime = '10:00 AM';
    if (booking['scheduledTime'] != null) {
      try {
        final dt = DateTime.parse(booking['scheduledTime']);
        displayTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.handshake, color: Color(0xFF2E7D32), size: 18),
            const SizedBox(width: 6),
            Text(
              'Connected with $pName', 
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF152238))
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Patient Details Card with left border highlighted
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 140,
                            color: const Color(0xFF7C3AED), // Nurse theme color
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey.shade200,
                                          image: const DecorationImage(
                                            image: AssetImage('assets/images/male_profile.png'),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  pName,
                                                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified, color: Color(0xFF7C3AED), size: 14),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Age: $age Years  |  Gender: $gender',
                                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Mobile: $displayPhone',
                                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 14),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'Location: ',
                                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                      Expanded(
                                        child: Text(
                                          address.isEmpty || address == 'Not specified' ? 'B-102, Ashok Nagar, Near District Hospital, Varanasi, Uttar Pradesh - 221001' : address,
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF475569)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nurse Visit Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nurse Visit Details',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Visit Date & Time',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$displayDate (Wednesday), $displayTime',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Patient Problem / Description',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notes.isEmpty || notes == 'Requires experienced nurse' 
                              ? 'Patient needs general nursing care and daily dressing/vital checks.' 
                              : notes,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Nursing Services Request',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          serviceType,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Booking Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Details',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 10),
                        _buildConnectedDetailRow('Service Type', 'Nurse Visit'),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildConnectedDetailRow('Offered Amount', '₹$fees'),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildConnectedDetailRow('Booking Date & Time', '25 May 2025, 10:15 AM'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Details',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 10),
                        _buildConnectedDetailRow('Payment Type', 'Direct to Vendor'),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        const Text(
                          'Customer will pay after service completion.',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons Row (Call Patient & WhatsApp)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final Uri telUri = Uri(scheme: 'tel', path: displayPhone);
                              if (await canLaunchUrl(telUri)) {
                                await launchUrl(telUri);
                              }
                            },
                            icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                            label: const Text(
                              'Call Patient',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C3AED),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final url = "https://wa.me/${displayPhone.replaceAll(RegExp(r'[^\d]'), '')}";
                              try {
                                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                              } catch (e) {
                                debugPrint("Could not launch WhatsApp: $e");
                              }
                            },
                            icon: Image.asset('assets/images/whatsap_icon.png', width: 24, height: 24),
                            label: const Text(
                              'WhatsApp',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Need Assistance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F5FF), // Purple-tinted bg
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Need Assistance?',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF6D28D9)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'If you face any issues, please contact ONMINT Support.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF7C3AED)),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: OutlinedButton(
                            onPressed: () async {
                              final Uri supportUri = Uri(scheme: 'tel', path: '+919999999999');
                              if (await canLaunchUrl(supportUri)) {
                                await launchUrl(supportUri);
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF7C3AED)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Contact Support',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
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

            // Green Safety Priority Bar
            Container(
              width: double.infinity,
              color: const Color(0xFFDCFCE7),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF15803D), size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Your safety is our priority.',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildConnectedDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
        ),
      ],
    );
  }
}
