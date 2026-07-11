import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import '../services/doctor_detail_screen.dart';
import '../booking/confirm_doctor_booking_screen.dart';
import '../booking/confirm_doctor_booking_screen_new.dart';
import '../booking/doctor_request_sent_screen.dart';
import 'package:user_app/config/app_config.dart';

class DoctorSummaryScreen extends StatefulWidget {
  final String categoryTitle;
  final String symptomName;

  const DoctorSummaryScreen({
    Key? key,
    required this.categoryTitle,
    required this.symptomName,
  }) : super(key: key);

  @override
  State<DoctorSummaryScreen> createState() => _DoctorSummaryScreenState();
}

class _DoctorSummaryScreenState extends State<DoctorSummaryScreen> {
  final OnMintApiClient _apiClient = OnMintApiClient();
  bool _isLoadingDoctors = true;
  bool _isBooking = false;
  List<Map<String, dynamic>> _doctors = [];
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _initApiAndFetchDoctors();
  }

  Future<void> _initApiAndFetchDoctors() async {
    await _apiClient.initialize();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoadingDoctors = true);
    try {
      final response = await _apiClient.patient.searchDoctors(
        limit: 5,
        specialization: widget.categoryTitle,
      );

      final doctorsData = response['data'] ?? [];
      setState(() {
        _doctors = List<Map<String, dynamic>>.from(doctorsData);
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() => _isLoadingDoctors = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctors: $e')),
      );
    }
  }

  Future<void> _handlePayAndConsult() async {
    setState(() => _isBooking = true);
    try {
      final double consultationFee = 499.0; // Dynamic if available
      final bookingData = {
        'serviceType': 'doctor',
        'category': widget.categoryTitle,
        'specialization': widget.categoryTitle,
        'description': 'Online consultation for ${widget.categoryTitle} - ${widget.symptomName}',
        'urgency': 'medium',
        'address': 'Online',
        'isEmergency': false,
        'consultationType': 'video-call',
        'paymentMethod': 'direct_to_vendor',
        'totalAmount': consultationFee,
      };

      final resp = await _apiClient.patient.createRealtimeBooking(bookingData);
      final newBookingId = resp['_id']?.toString() ?? resp['id']?.toString() ?? '';

      if (mounted) {
        setState(() => _isBooking = false);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => DoctorRequestSentScreen(
              bookingId: newBookingId,
              bookingData: resp,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request consultation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Summary', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF283593),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Consultation for ${widget.categoryTitle}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(Icons.medical_services,
                          color: Colors.red[300], size: 30),
                    ),
                  )
                ],
              ),
            ),

            // Doctors Section
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'WE WILL ASSIGN YOU A TOP DOCTOR FROM BELOW',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      'View our doctors currently online',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_isLoadingDoctors)
                    const Center(child: CircularProgressIndicator())
                  else if (_doctors.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                          'No doctors found for this category currently online.'),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _doctors.length,
                        itemBuilder: (context, index) {
                          return _buildDoctorCard(_doctors[index]);
                        },
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Language Section
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Choose your preferred language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'We will try to find doctors who can speak the language.',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildLanguageChip('English'),
                      const SizedBox(width: 12),
                      _buildLanguageChip('हिंदी'),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Consultation info
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.blue, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Single online consultation',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Chat, audio, video consultation and free 7 day follow-up',
                              style: TextStyle(
                                  fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'You will also get a FREE follow-up for 7 days with every consultation',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Apply Coupon
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  Icon(Icons.local_offer, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'APPLY COUPON CODE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Privacy Section
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline,
                          color: Colors.grey[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Data and Privacy',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'The contents of your consultations are private and confidential. Practo\'s medical team may carry out routine anonymised audits to improve service quality. Know more',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'By proceeding to avail a consultation, you agree to Practo\'s Terms of use.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),

            // Footer Text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(
                    'Practo Guarantee: 100% Money back if no response',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  Text(
                    'Not for emergency use',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24), // padding for bottom bar
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Pay Using',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(width: 12),
                // Icons for payment
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.purple),
                  child: const Center(
                      child: Text('pe',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold))),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                const Text(
                  'More Payment Options >',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.w500),
                )
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _handlePayAndConsult,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF03A9F4),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: _isBooking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white))
                    : const Text(
                        '₹934.15 | Pay & Consult',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageChip(String label) {
    bool isSelected = _selectedLanguage == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLanguage = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[400]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return GestureDetector(
      onTap: () {
        try {
          final doctorUser = User.fromJson(doctor);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailScreen(doctor: doctorUser),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading doctor details: $e')),
          );
        }
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.blue[100],
              child: Text(
                doctor['firstName']?.substring(0, 1) ?? 'D',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Dr. ${doctor['firstName']} ${doctor['lastName']}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    doctor['specialization'] ?? 'Doctor',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${doctor['experience'] ?? 0} years experience',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  Text(
                    '${doctor['totalConsultations'] ?? 0} consultations',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
