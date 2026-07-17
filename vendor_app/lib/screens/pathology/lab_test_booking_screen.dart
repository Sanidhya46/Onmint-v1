import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class LabTestBookingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingData;

  const LabTestBookingScreen({
    super.key,
    required this.bookingId,
    this.bookingData,
  });

  @override
  State<LabTestBookingScreen> createState() => _LabTestBookingScreenState();
}

class _LabTestBookingScreenState extends State<LabTestBookingScreen> {
  final _apiClient = OnMintApiClient();
  bool _isLoading = true;
  bool _isActing = false;
  Map<String, dynamic>? _bookingDetails;
  String _currentStatus = 'accepted'; 

  // Primary Theme Colors (Enforcing Blue instead of Purple)
  final Color primaryBlue = const Color(0xFF0D47A1); // Deep Blue
  final Color lightBlue = const Color(0xFFE3F2FD); // Light Blue for icon backgrounds
  final Color textDark = const Color(0xFF152238);
  final Color greenSuccess = const Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    if (widget.bookingData != null) {
      _bookingDetails = widget.bookingData;
      _currentStatus = _bookingDetails?['status']?.toString().toLowerCase() ?? 'accepted';
      if (_currentStatus == 'requested') _currentStatus = 'accepted';
      _isLoading = false;
    } else {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    try {
      await _apiClient.initialize();
      final response = await _apiClient.pathology.getBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _bookingDetails = response['data'] ?? response;
          _currentStatus = _bookingDetails?['status']?.toString().toLowerCase() ?? 'accepted';
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

  Future<void> _uploadReport() async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() => _isActing = true);
        
        await _apiClient.initialize();
        
        final file = result.files.first;
        if (file.bytes != null) {
          await _apiClient.pathology.uploadReportFileBytes(
            widget.bookingId,
            file.bytes!,
            file.name,
          );
        } else if (file.path != null) {
          await _apiClient.pathology.uploadReportFile(
            widget.bookingId,
            file.path!,
          );
        }

        // Once uploaded, mark the booking as completed locally since backend already did it
        if (mounted) {
          setState(() {
            _currentStatus = 'completed';
            if (_bookingDetails != null) {
              _bookingDetails!['status'] = 'completed';
            }
          });
          ToastUtils.showSuccess('Report uploaded successfully');
          _fetchDetails();
        }
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to upload report');
      }
    } finally {
      if (mounted) {
        setState(() => _isActing = false);
      }
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isActing = true);
    try {
      // Allow bypassing API for mockup flow if ID is a mock ID
      if (widget.bookingId == '649b5c3e7b1a2c3f1d4e5f6a') {
        await Future.delayed(const Duration(milliseconds: 600));
        if (mounted) {
          setState(() {
            _currentStatus = newStatus;
            if (_bookingDetails != null) {
              _bookingDetails!['status'] = newStatus;
            }
          });
          ToastUtils.showSuccess('Status updated');
        }
        return;
      }

      await _apiClient.initialize();
      await _apiClient.pathology.updateBookingStatus(widget.bookingId, newStatus);
      if (mounted) {
        setState(() {
          _currentStatus = newStatus;
          if (_bookingDetails != null) {
            _bookingDetails!['status'] = newStatus;
          }
        });
        ToastUtils.showSuccess('Status updated');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to update status.');
      }
    } finally {
      if (mounted) {
        setState(() => _isActing = false);
      }
    }
  }

  int get _statusStep {
    switch (_currentStatus) {
      case 'accepted': return 0;
      case 'on_the_way': return 1;
      case 'sample_collected': return 2;
      case 'report_ready': return 3;
      case 'completed': return 4;
      default: return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _bookingDetails == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    final booking = _bookingDetails ?? {};
    
    return _buildConnectedScreen(booking);
  }

  Widget _buildConnectedScreen(Map<String, dynamic> booking) {
    final patientData = booking['patient'] ?? {};
    String patientName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    if (patientName.isEmpty) patientName = 'Rahul Sharma';
    
    final String gender = patientData['gender']?.toString().capitalize() ?? 'Male';
    final String age = patientData['age']?.toString() ?? '32';
    
    final rawAddr = booking['location']?['address'];
    String address;
    if (rawAddr is Map) {
      address = rawAddr['address']?.toString() ?? 
          [rawAddr['street'], rawAddr['city'], rawAddr['state']].where((p) => p != null && p.toString().isNotEmpty).join(', ');
    } else {
      address = rawAddr?.toString() ?? 'B-102, Ashok Nagar, Near District Hospital, Varanasi, Uttar Pradesh - 221001';
    }

    final requestedOn = booking['createdAt'] != null ? DateTime.tryParse(booking['createdAt']) : DateTime.now();
    final String displayDate = requestedOn != null ? DateFormat('dd MMM yyyy').format(requestedOn) : '30 Jun 2026';
    
    String displayTime = '10:00 AM';
    if (booking['scheduledTime'] != null) {
      try {
        final dt = DateTime.parse(booking['scheduledTime']);
        displayTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final price = booking['price'] ?? booking['totalAmount'] ?? booking['fees'] ?? 499;
    final phone = patientData['phone']?.toString() ?? '+91 98765 43210';

    List<String> tests = ['Complete Blood Count (CBC)', 'Vitamin D (25-Hydroxy)'];
    if (booking['tests'] != null && booking['tests'] is List && booking['tests'].isNotEmpty) {
      tests = (booking['tests'] as List).map((t) => (t['name'] ?? 'Test').toString()).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textDark),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Color(0xFF1D4ED8),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text(
              'Connected', 
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1D4ED8))
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDetails,
        child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Patient Details Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
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
                                    Row(
                                      children: [
                                        Text(
                                          patientName,
                                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFBFDBFE)),
                                          ),
                                          child: Row(
                                            children: const [
                                              Icon(Icons.verified, color: Color(0xFF1D4ED8), size: 12),
                                              SizedBox(width: 4),
                                              Text('Verified', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF1D4ED8), fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 8),
                                        const SizedBox(width: 60, child: Text('Age', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)))),
                                        Text('$age Years', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.person_outline, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 8),
                                        const SizedBox(width: 60, child: Text('Gender', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)))),
                                        Text(gender, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                                        const SizedBox(width: 8),
                                        const SizedBox(width: 60, child: Text('Mobile', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)))),
                                        Text(phone, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Location', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 6),
                              Text(address, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF475569))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Sample Collection Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sample Collection',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: const Icon(Icons.calendar_today_outlined, color: Color(0xFF1D4ED8), size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Sample Collection Date',
                                            style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Color(0xFF1D4ED8)),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '$displayDate\n(Monday)',
                                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(width: 1, height: 40, color: const Color(0xFFE2E8F0)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFE2E8F0)),
                                      ),
                                      child: const Icon(Icons.home_outlined, color: Color(0xFF1D4ED8), size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: const [
                                          Text(
                                            'Collection Type',
                                            style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Color(0xFF1D4ED8)),
                                          ),
                                          SizedBox(height: 2),
                                          Text(
                                            'Home Sample Collection\n(At Your Doorstep)',
                                            style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lab Tests Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Lab Tests',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: tests.asMap().entries.map((entry) {
                              int idx = entry.key;
                              String test = entry.value;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Row(
                                      children: [
                                        Text('${idx + 1}. ', style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF334155))),
                                        const SizedBox(width: 8),
                                        Expanded(child: Text(test, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600))),
                                      ],
                                    ),
                                  ),
                                  if (idx < tests.length - 1)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 12),
                                      child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Booking Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Booking Details',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                        ),
                        const SizedBox(height: 12),
                        _buildConnectedDetailRow('Service Type', 'Pathology Test'),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                        _buildConnectedDetailRow('Offered Amount', '₹$price'),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: Color(0xFFF1F5F9))),
                        _buildConnectedDetailRow('Booking Date & Time', '25 May 2025, 10:15 AM'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Payment Details Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment Details',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: const [
                                  Text(
                                    'Payment Mode:   ',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
                                  ),
                                  Text(
                                    'Direct to Vendor',
                                    style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Customer will pay after service completion.',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF16A34A), width: 2),
                          ),
                          child: const Icon(Icons.check, color: Color(0xFF16A34A), size: 24),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Action Buttons Row (Call Patient & WhatsApp)
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final Uri telUri = Uri(scheme: 'tel', path: phone);
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
                              backgroundColor: const Color(0xFF1D4ED8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                              final url = "https://wa.me/${phone.replaceAll(RegExp(r'[^\d]'), '')}";
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
                              backgroundColor: const Color(0xFF16A34A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Need Assistance Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Need Assistance?',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'If you have any issue with your booking\nor patient, contact ONMINT Support.',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () async {
                            final Uri supportUri = Uri(scheme: 'tel', path: '+919999999999');
                            if (await canLaunchUrl(supportUri)) {
                              await launchUrl(supportUri);
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1D4ED8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          child: const Text('Contact Support', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Green Safety Priority Bar
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 12),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Your safety is our priority',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Do not share your personal details with the patient.\nContact support if you face any issue.',
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildPatientInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF64748B)),
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF0F172A), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildConnectedDetailRow(String label, String value) {
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

  Widget _buildPatientCard(Map<String, dynamic> bookingData) {
    final patientData = bookingData['patient'] ?? {};
    String patientName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    if (patientName.isEmpty) patientName = 'Umeya Khan';
    
    final String patientImage = patientData['profilePicture']?.toString() ?? '';
    final String gender = patientData['gender']?.toString().capitalize() ?? 'Female';
    final String age = patientData['age']?.toString() ?? '27';
    final rawAddr = bookingData['location']?['address'];
    String address;
    if (rawAddr is Map) {
      address = rawAddr['address']?.toString() ?? 
          [rawAddr['street'], rawAddr['city'], rawAddr['state']].where((p) => p != null && p.toString().isNotEmpty).join(', ');
    } else {
      address = rawAddr?.toString() ?? 'H-101, Shanti Nagar, Govindpuram, Ghaziabad, Uttar Pradesh - 201013';
    }

    final requestedOn = bookingData['createdAt'] != null ? DateTime.tryParse(bookingData['createdAt']) : DateTime.now();
    final String displayDate = requestedOn != null ? DateFormat('dd MMM yyyy').format(requestedOn) : '13 May 2025';
    
    String displayTime = '10:00 AM';
    if (bookingData['scheduledTime'] != null) {
      try {
        final dt = DateTime.parse(bookingData['scheduledTime']);
        displayTime = DateFormat('hh:mm a').format(dt);
      } catch (_) {}
    }

    final price = bookingData['price'] ?? bookingData['totalAmount'] ?? bookingData['fees'] ?? 300;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade200,
              image: DecorationImage(
                image: patientImage.isNotEmpty
                    ? NetworkImage(patientImage) as ImageProvider
                    : AssetImage(gender.toLowerCase() == 'female'
                        ? 'assets/images/female_profile.png'
                        : 'assets/images/male_profile.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Middle Column: Name, Gender/Age, Address
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(gender.toLowerCase() == 'female' ? Icons.female : Icons.male, size: 12, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text('$gender • $age Years', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade800, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right Column: Date, Time, Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(displayDate, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: textDark)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.access_time_outlined, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(displayTime, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: textDark)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '₹$price',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: greenSuccess),
              ),
              Text(
                'Service Fee',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTestDetailsCard(Map<String, dynamic> booking) {
    List<String> tests = ['CBC Test', 'Thyroid Profile'];
    if (booking['tests'] != null && booking['tests'] is List && booking['tests'].isNotEmpty) {
      tests = (booking['tests'] as List).map((t) => (t['name'] ?? 'Test').toString()).toList();
    }
    final notes = booking['notes'] ?? 'Patient has mild fever. Please handle carefully.';

    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Test Details',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: textDark),
          ),
          const SizedBox(height: 8),
          Text('Test Name / Package', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: textDark)),
          const SizedBox(height: 4),
          ...tests.map((test) => Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Row(
              children: [
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Text(test, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade800)),
              ],
            ),
          )),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sample Type', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: textDark)),
              const SizedBox(height: 2),
              Text('Blood', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade800)),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Additional Notes', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w700, color: textDark)),
              const SizedBox(height: 2),
              Text(notes, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade800)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline(int currentStep) {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: 10,
            left: 35,
            right: 35,
            child: Row(
              children: [
                Expanded(child: Container(height: 2, color: currentStep >= 1 ? greenSuccess : Colors.grey.shade300)),
                Expanded(child: Container(height: 2, color: currentStep >= 2 ? greenSuccess : Colors.grey.shade300)),
                Expanded(child: Container(height: 2, color: currentStep >= 3 ? greenSuccess : Colors.grey.shade300)),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimelineNodeWithLabel('Accepted', 0, currentStep),
              _buildTimelineNodeWithLabel('On The Way', 1, currentStep),
              _buildTimelineNodeWithLabel('Sample\nCollected', 2, currentStep),
              _buildTimelineNodeWithLabel('Completed', 3, currentStep),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineNodeWithLabel(String title, int nodeIndex, int currentStep) {
    bool isCompleted = currentStep >= nodeIndex;
    if (nodeIndex == 3 && currentStep >= 3) isCompleted = true;

    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? greenSuccess : Colors.white,
              border: Border.all(color: isCompleted ? greenSuccess : Colors.grey.shade400, width: 2),
            ),
            child: isCompleted ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
          ),
          const SizedBox(height: 6),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 9, fontWeight: FontWeight.w600, color: isCompleted ? greenSuccess : Colors.grey.shade500, height: 1.1)),
        ],
      ),
    );
  }

  Widget _buildActionButtonsRow() {
    return Container(
      decoration: _cardDecoration(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(Icons.phone, 'Call Patient'),
          _buildActionButton(Icons.chat_bubble, 'Chat'),
          _buildActionButton(Icons.map, 'Open Map'),
          _buildActionButton(Icons.assignment, 'Test Details'),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD), // Light blue
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF0D47A1), size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
      ],
    );
  }

  Widget _buildBottomAction(int currentStep) {
    String label = '';
    IconData? icon;
    VoidCallback? onPressed;
    bool showPrimaryButton = true;

    if (currentStep == 0) {
      label = 'On The Way';
      icon = Icons.two_wheeler;
      onPressed = () => _updateStatus('on_the_way');
    } else if (currentStep == 1) {
      label = 'Collect Blood Sample';
      icon = Icons.water_drop;
      onPressed = () => _updateStatus('sample_collected');
    } else if (currentStep == 2) {
      label = 'Upload Report';
      icon = Icons.cloud_upload;
      onPressed = _uploadReport;
    } else {
      showPrimaryButton = false;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showPrimaryButton) ...[
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: _isActing ? null : onPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1), // Deep Blue
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) Icon(icon, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_bookingDetails?['report'] != null && _bookingDetails!['report'].toString().isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final url = _bookingDetails!['report'].toString();
                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 16),
                  label: const Text('View Report', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade400,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              width: double.infinity,
              height: 36,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context, true),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1),
                  side: const BorderSide(color: Color(0xFF0D47A1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.arrow_back, size: 14),
                    const SizedBox(width: 4),
                    const Text('Back', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
}

// Helper Extension
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
