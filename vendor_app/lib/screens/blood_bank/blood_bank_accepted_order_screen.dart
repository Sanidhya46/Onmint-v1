import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class BloodBankAcceptedOrderScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? initialData;

  const BloodBankAcceptedOrderScreen({
    super.key,
    required this.bookingId,
    this.initialData,
  });

  @override
  State<BloodBankAcceptedOrderScreen> createState() => _BloodBankAcceptedOrderScreenState();
}

class _BloodBankAcceptedOrderScreenState extends State<BloodBankAcceptedOrderScreen> {
  final _apiClient = OnMintApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _booking;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _booking = widget.initialData;
      _isLoading = false;
    } else {
      _loadBooking();
    }
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/realtime/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading order details: $e')),
        );
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
    setState(() => _isLoading = true);
    try {
      await _apiClient.patch('/realtime/${widget.bookingId}/status', data: {'status': newStatus});
      await _loadBooking();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    }
  }

  Future<void> _handleConnectWithPatient(String phoneNumber, String patientName) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    
    // Update status to in_progress before calling
    // Removed to prevent API error
    
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
      
      // Show call log confirmation dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Call Completed'),
            content: Text('Called $patientName successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Reload booking to show updated timeline
                  _loadBooking();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF1A1A60))),
      );
    }

    if (_booking == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text('Order not found', style: TextStyle(color: Colors.black))),
      );
    }

    final patientData = _booking!['patientDetails'] ?? _booking!['patient'];
    final patient = (patientData is Map) ? patientData : {};
    
    final fullName = patient['fullName'] ?? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Rahul Verma' : fullName;
    final age = patient['age']?.toString() ?? '35';
    final gender = patient['gender'] ?? 'Male';
    final phone = patient['phone'] ?? '';
    
    // Bloodbank specific
    final units = _booking!['unitsRequired']?.toString() ?? '2';
    final isEmergency = _booking!['isEmergency'] ?? true;
    final emergencyNote = _booking!['notes'] ?? 'Urgent requirement for surgery.\nPlease help.';
    
    final locationData = _booking!['location'];
    String address;
    if (locationData is Map) {
      final addr = locationData['address'];
      if (addr is Map) {
        address = addr['address']?.toString() ?? addr['street']?.toString() ?? 'Location not specified';
      } else if (addr != null) {
        address = addr.toString();
      } else {
        address = locationData['street']?.toString() ?? locationData['city']?.toString() ?? 'Location not specified';
      }
    } else if (locationData is String && locationData.isNotEmpty) {
      address = locationData;
    } else {
      address = _booking!['hospitalName'] ?? _booking!['address']?.toString() ?? 'Location not specified';
    }

    // Dates
    String dateStr = '13 May 2025';
    String timeStr = '10:00 AM';
    if (_booking!['scheduledTime'] != null) {
      final dt = DateTime.tryParse(_booking!['scheduledTime']);
      if (dt != null) {
        dateStr = DateFormat('dd MMM yyyy').format(dt);
        timeStr = DateFormat('hh:mm a').format(dt);
      }
    }

    return _buildConnectedScreen(_booking!, displayName, age, gender, phone, address, units, isEmergency, emergencyNote);
  }


  Widget _buildRowItem(
    IconData icon, 
    String label, 
    String value, {
    Color? valueColor,
    FontWeight? valueWeight,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? const Color(0xFF5A6684), size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
        const Spacer(),
        Expanded(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: valueWeight ?? FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalTimeline(String status) {
    int currentIndex = 0;
    if (status == 'on_the_way' || status == 'sample_collected' || status == 'in_progress') {
      currentIndex = 1;
    } else if (status == 'completed') {
      currentIndex = 2;
    }

    return Stack(
      children: [
        // Background lines
        Positioned(
          top: 11, // half of 24px circle
          left: 40,
          right: 40,
          child: Row(
            children: [
              Expanded(child: Container(height: 2, color: 0 < currentIndex ? Colors.green : Colors.grey.shade300)),
              Expanded(child: Container(height: 2, color: 1 < currentIndex ? Colors.green : Colors.grey.shade300)),
            ],
          ),
        ),
        // Nodes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildTimelineNode('Accepted', 0 <= currentIndex)),
            Expanded(child: _buildTimelineNode('Connect with Patient', 1 <= currentIndex)),
            Expanded(child: _buildTimelineNode('Completed', 2 <= currentIndex)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineNode(String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.green : Colors.grey.shade400,
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
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? Colors.green : Colors.grey.shade600,
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
    String units,
    bool isEmergency,
    String emergencyNote,
  ) {
    final String pName = displayName.isEmpty ? 'Rahul Sharma' : displayName;
    final String displayPhone = phone.isEmpty ? '+91 98765 43210' : phone;

    final requestedOn = booking['createdAt'] != null ? DateTime.tryParse(booking['createdAt']) : DateTime.now();
    final String displayDate = requestedOn != null ? DateFormat('dd MMM yyyy').format(requestedOn) : '30 Jun 2026';
    
    String displayTime = '11:30 AM';
    if (booking['scheduledTime'] != null) {
      try {
        final dt = DateTime.parse(booking['scheduledTime']);
        displayTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final price = booking['price'] ?? booking['totalAmount'] ?? booking['fees'] ?? 2500;
    final bloodGroup = booking['bloodGroup'] ?? 'O+ (Positive)';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A60)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.handshake, color: Color(0xFF2E7D32), size: 18),
            const SizedBox(width: 6),
            Text(
              'Connected with $pName', 
              style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1A1A60))
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
                            color: const Color(0xFF1A1A60), // Blood bank theme color
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
                                                const Icon(Icons.verified, color: Color(0xFF1A1A60), size: 14),
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
                                          address.isEmpty || address == 'Location not specified' ? 'B-102, Ashok Nagar, Near District Hospital, Varanasi, Uttar Pradesh - 221001' : address,
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

                  // Blood Request Details Card
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
                          'Blood Request Details',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Requested Group',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    bloodGroup,
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Units Required',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '$units Units',
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Hospital / Clinic Name',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          address.isEmpty || address == 'Location not specified' ? 'Varanasi District Hospital' : address,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                        ),
                        if (isEmergency) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'EMERGENCY',
                                  style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            emergencyNote,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF475569), fontStyle: FontStyle.italic),
                          ),
                        ],
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
                        _buildConnectedDetailRow('Service Type', 'Blood Request'),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        _buildConnectedDetailRow('Offered Amount', '₹$price'),
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
                        _buildConnectedDetailRow('Payment Type', 'Direct to Blood Bank'),
                        const Divider(height: 16, color: Color(0xFFF1F5F9)),
                        const Text(
                          'Direct payment to blood bank on delivery.',
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
                              await _handleConnectWithPatient(displayPhone, pName);
                            },
                            icon: const Icon(Icons.phone, color: Colors.white, size: 18),
                            label: const Text(
                              'Call Patient',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A60),
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
                              if (await canLaunchUrl(Uri.parse(url))) {
                                await launchUrl(Uri.parse(url));
                              }
                            },
                            icon: const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
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
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Need Assistance?',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A1A60)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'If you face any issues, please contact ONMINT Support.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF1D4ED8)),
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
                              side: const BorderSide(color: Color(0xFF1D4ED8)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'Contact Support',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
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
