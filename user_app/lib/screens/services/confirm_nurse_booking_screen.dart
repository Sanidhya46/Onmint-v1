import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:user_app/screens/booking/nursing_care_selection_screen.dart';
import 'package:user_app/screens/booking/order_request_screen.dart';
import 'package:intl/intl.dart';

class ConfirmNurseBookingScreen extends StatefulWidget {
  final String address;
  final String name;
  final String phone;
  final int age;
  final String gender;
  final String notes;
  final String city;
  final String state;
  final List<NursingCareModel> selectedCares;
  final DateTime? preferredDate;
  final DateTime? preferredTime;

  const ConfirmNurseBookingScreen({
    Key? key,
    required this.address,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    required this.notes,
    required this.city,
    required this.state,
    required this.selectedCares,
    this.preferredDate,
    this.preferredTime,
  }) : super(key: key);

  @override
  State<ConfirmNurseBookingScreen> createState() =>
      _ConfirmNurseBookingScreenState();
}

class _ConfirmNurseBookingScreenState extends State<ConfirmNurseBookingScreen> {
  String _selectedPayment = 'upi';
  bool _isBooking = false;
  final OnMintApiClient _apiClient = OnMintApiClient();

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
  }

  Future<void> _handlePayAndConfirm() async {
    setState(() => _isBooking = true);
    try {
      final bookingData = {
        'serviceType': 'nurse',
        'address': widget.address,
        'name': widget.name,
        'phone': widget.phone,
        'patientAge': widget.age,
        'patientGender': widget.gender,
        'notes': widget.notes,
        'nursingCares':
            widget.selectedCares.map((c) => {'name': c.name}).toList(),
        if (widget.preferredDate != null)
          'preferredDate': widget.preferredDate!.toIso8601String(),
        if (widget.preferredTime != null)
          'preferredTime': widget.preferredTime!.toIso8601String(),
        'urgency': 'medium',
        'isEmergency': false,
        'city': widget.city,
        'state': widget.state,
        'paymentMethod': _selectedPayment,
        'totalAmount': 499, // From UI
      };

      await _apiClient.patient.createRealtimeBooking(bookingData);

      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nurse request sent successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OrderRequestScreen(
              bookingId: '',
              bookingData: bookingData,
              serviceType: 'nurse',
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request nurse: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FB),
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
              height: 44, // decreased button height
              child: ElevatedButton(
                onPressed: _isBooking ? null : _handlePayAndConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900], // Dark Blue button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isBooking
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Pay Rs. 499 & Confirm Booking',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline,
                    color: Colors.grey[500], size: 14),
                const SizedBox(width: 6),
                Text(
                  'By proceeding, you agree to our ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const Text(
                  'Terms & Conditions',
                  style: TextStyle(
                      color: Colors.blue,
                      fontSize: 11,
                      decoration: TextDecoration.underline),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 4),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Section
            Stack(
              children: [
                Image.asset(
                  'assets/images/nurse/Confirm_nurse_booking.jpeg',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                ),
                // Positioned removed
              ],
            ),
            Column(
              children: [
                // Booking Summary Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                color: Colors.blue[900], size: 18),
                            const SizedBox(width: 6),
                            const Text(
                              'Booking Summary',
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
                        const SizedBox(height: 10),
                        _buildSummaryRow(
                            Icons.person_outline, 'Contact Name', widget.name),
                        _buildSummaryRow(
                            Icons.phone_outlined, 'Phone Number', widget.phone),
                        _buildSummaryRow(Icons.calendar_today_outlined, 'Age',
                            widget.age.toString()),
                        _buildSummaryRow(
                            Icons.person_outline, 'Gender', widget.gender),
                        _buildSummaryRow(
                            Icons.medical_services_outlined,
                            'Nursing Cares',
                            widget.selectedCares.map((c) => c.name).join('\n')),
                        if (widget.city.isNotEmpty)
                          _buildSummaryRow(Icons.location_city, 'City', widget.city),
                        if (widget.state.isNotEmpty)
                          _buildSummaryRow(Icons.map_outlined, 'State', widget.state),
                        if (widget.preferredDate != null)
                          _buildSummaryRow(
                              Icons.calendar_today_outlined,
                              'Preferred Date',
                              DateFormat('dd MMM yyyy')
                                  .format(widget.preferredDate!)),
                        if (widget.preferredTime != null)
                          _buildSummaryRow(
                              Icons.access_time_outlined,
                              'Preferred Time',
                              DateFormat('hh:mm a')
                                  .format(widget.preferredTime!)),
                        _buildSummaryRow(Icons.note_alt_outlined, 'Notes',
                            widget.notes.isEmpty ? 'None' : widget.notes,
                            isLast: true),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue[900], size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'You will be contacted by an available nurse once your request is accepted.',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Payment Details Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.credit_card,
                                color: Colors.blue[900], size: 18),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue[200]!),
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11),
                                  ),
                                  Text(
                                    'Service Fee (Non-Refundable)',
                                    style: TextStyle(
                                        color: Colors.grey[600], fontSize: 9),
                                  ),
                                ],
                              ),
                              const Text(
                                'Rs. 499',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Select Payment Method',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildPaymentOption(
                          id: 'upi',
                          title: 'UPI',
                          icon: Icons.account_balance_wallet,
                        ),
                        _buildPaymentOption(
                          id: 'card',
                          title: 'Debit / Credit Card',
                          icon: Icons.credit_card,
                          trailingIcon: true,
                        ),
                        _buildPaymentOption(
                          id: 'bank',
                          title: 'Bank Transfer',
                          icon: Icons.account_balance,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_user,
                                  color: Colors.green[600], size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '100% Secure Payment',
                                      style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10),
                                    ),
                                    Text(
                                      'Your payment information is safe and encrypted',
                                      style: TextStyle(
                                          color: Colors.green[700],
                                          fontSize: 9),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.lock_outline,
                                  color: Colors.green[600], size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value,
      {bool isLast = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blue[900], size: 16), // Now dark blue
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

  Widget _buildPaymentOption({
    required String id,
    required String title,
    required IconData icon,
    bool trailingIcon = false,
  }) {
    final isSelected = _selectedPayment == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border:
              Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue[50] : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                  width: isSelected ? 4 : 1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(icon, color: Colors.blue[900], size: 16), // Dark Blue Icon
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
