import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:user_app/screens/booking/order_request_screen.dart';

class ConfirmDoctorBookingScreen extends StatefulWidget {
  final String categoryTitle;
  final String symptomName;

  const ConfirmDoctorBookingScreen({
    Key? key,
    required this.categoryTitle,
    required this.symptomName,
  }) : super(key: key);

  @override
  State<ConfirmDoctorBookingScreen> createState() =>
      _ConfirmDoctorBookingScreenState();
}

class _ConfirmDoctorBookingScreenState
    extends State<ConfirmDoctorBookingScreen> {
  String _selectedPayment = 'upi';
  bool _isBooking = false;
  final OnMintApiClient _apiClient = OnMintApiClient();
  final double consultationFee = 499.0; // Standard consultation fee

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
        'paymentMethod': _selectedPayment,
        'totalAmount': consultationFee,
      };

      await _apiClient.patient.createRealtimeBooking(bookingData);

      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Doctor consultation request sent successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OrderRequestScreen(
              bookingId: '',
              bookingData: bookingData,
              serviceType: 'doctor',
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
      backgroundColor: const Color(0xFFF8F9FA), // Ice background
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Pay Rs. ${consultationFee.toInt()} & Confirm Booking',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded,
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

            // Payment Details Section
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
                      Icon(Icons.credit_card,
                          color: const Color(0xFF283593), size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Payment Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.indigo[100]!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            Text(
                              'Service Fee (Non-Refundable)',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 9),
                            ),
                          ],
                        ),
                        Text(
                          'Rs. ${consultationFee.toInt()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF283593),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentOption('UPI', 'upi', Icons.qr_code),
                  _buildPaymentOption(
                      'Debit / Credit Card', 'card', Icons.credit_card,
                      trailingIcon: true),
                  _buildPaymentOption(
                      'Bank Transfer', 'bank', Icons.account_balance),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.verified_user,
                            color: Colors.green[600], size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '100% Secure Payment',
                                style: TextStyle(
                                    color: Colors.green[800],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11),
                              ),
                              Text(
                                'Your payment information is safe and encrypted',
                                style: TextStyle(
                                    color: Colors.green[700], fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.lock_outline,
                            color: Colors.green[600], size: 16),
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

  Widget _buildPaymentOption(String title, String id, IconData icon,
      {bool trailingIcon = false}) {
    final isSelected = _selectedPayment == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? const Color(0xFF283593) : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.indigo[50] : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF283593) : Colors.grey[400]!,
                  width: isSelected ? 4 : 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: const Color(0xFF283593), size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
              ),
            ),
            if (trailingIcon)
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 14,
                    color: Colors.blue[800],
                    alignment: Alignment.center,
                    child: const Text('VISA',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 6,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 24,
                    height: 14,
                    decoration: BoxDecoration(
                        color: Colors.orange[200],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
