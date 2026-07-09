import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:user_app/screens/booking/order_detail_file.dart';

class ConfirmDoctorBookingScreenNew extends StatefulWidget {
  final String categoryTitle;
  final String symptomName;

  const ConfirmDoctorBookingScreenNew({
    Key? key,
    required this.categoryTitle,
    required this.symptomName,
  }) : super(key: key);

  @override
  State<ConfirmDoctorBookingScreenNew> createState() =>
      _ConfirmDoctorBookingScreenNewState();
}

class _ConfirmDoctorBookingScreenNewState
    extends State<ConfirmDoctorBookingScreenNew> {
  bool _isBooking = false;
  final OnMintApiClient _apiClient = OnMintApiClient();
  final double consultationFee = 499.0;

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
  }

  Future<void> _handlePayAndConfirm() async {
    setState(() => _isBooking = true);
    try {
      final bookingData = {
        'serviceType': 'doctor',
        'category': widget.categoryTitle,
        'specialization': widget.categoryTitle,
        'description':
            'Online consultation for ${widget.categoryTitle} - ${widget.symptomName}',
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor consultation request sent successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OrderDetailFile(
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
      backgroundColor: const Color(0xFFF8F9FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _handlePayAndConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF283593), // Doctor App Color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isBooking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Confirm Consultation Request',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user_outlined,
                    color: Colors.grey[500], size: 14),
                const SizedBox(width: 6),
                Text(
                  'By proceeding, you agree to our ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                Text(
                  'Terms & Conditions',
                  style: TextStyle(
                      color: const Color(0xFF283593),
                      fontSize: 11,
                      decoration: TextDecoration.underline),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 6),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top section with image
            Stack(
              children: [
                Image.asset(
                  'assets/images/Appointment_image.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.indigo[100],
                    alignment: Alignment.center,
                    child: const Text('Banner Image Missing',
                        style: TextStyle(color: Colors.indigo)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Booking Summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.receipt_long_outlined,
                          color: const Color(0xFF283593), size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Consultation Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  _buildDetailRow(Icons.local_hospital,
                      'Specialization', widget.categoryTitle),
                  _buildDetailRow(
                      Icons.sick, 'Symptoms', widget.symptomName),
                  _buildDetailRow(
                      Icons.videocam, 'Consultation Mode', 'Online Video Call', isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nearest Doctor
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.local_hospital, color: Colors.blue[700], size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Nearest Doctor',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text('View All', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F7FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Icon(Icons.health_and_safety, color: Colors.blue[700], size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('City Care Clinic', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_outlined, color: Colors.blue[700], size: 8),
                                        const SizedBox(width: 2),
                                        Text('1.5 km away', style: TextStyle(color: Colors.blue[700], fontSize: 8, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Available: General Physician,\nCardiologist, Dentist',
                                    style: TextStyle(color: Colors.grey[800], fontSize: 9, height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Icon(Icons.phone, color: Colors.blue[700], size: 20),
                                ),
                                const SizedBox(height: 4),
                                Text('Call Now', style: TextStyle(color: Colors.blue[700], fontSize: 8, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
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
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF283593), size: 16),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 11),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.normal,
                    fontSize: 11),
              ),
            ),
          ],
        ),
        if (!isLast) const Divider(height: 22),
        if (isLast) const SizedBox(height: 4),
      ],
    );
  }
}
