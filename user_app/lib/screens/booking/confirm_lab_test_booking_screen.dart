import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:user_app/screens/booking/lab_test_selection_screen.dart';
import 'package:user_app/screens/booking/order_detail_file.dart';

class ConfirmLabTestBookingScreen extends StatefulWidget {
  final String address;
  final String contactName;
  final String phoneNumber;
  final DateTime preferredDate;
  final String notes;
  final List<LabTestModel> selectedTests;
  final String city;
  final String state;

  const ConfirmLabTestBookingScreen({
    Key? key,
    required this.address,
    required this.contactName,
    required this.phoneNumber,
    required this.preferredDate,
    required this.notes,
    required this.selectedTests,
    required this.city,
    required this.state,
  }) : super(key: key);

  @override
  State<ConfirmLabTestBookingScreen> createState() =>
      _ConfirmLabTestBookingScreenState();
}

class _ConfirmLabTestBookingScreenState
    extends State<ConfirmLabTestBookingScreen> {
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
      final testsArray = widget.selectedTests
          .map((t) => {
                'name': t.name,
                'price': t.price,
              })
          .toList();

      final totalAmount =
          widget.selectedTests.fold(0.0, (sum, item) => sum + item.price);

      final bookingData = {
        'serviceType': 'labtest',
        'address': widget.address,
        'name': widget.contactName,
        'phone': widget.phoneNumber,
        'notes': widget.notes,
        'tests': testsArray,
        'preferredDate': widget.preferredDate.toIso8601String(),
        'paymentMethod': _selectedPayment,
        'totalAmount': totalAmount,
        'coordinates': [0.0, 0.0],
        'city': widget.city,
        'state': widget.state,
      };

      await _apiClient.patient.createRealtimeBooking(bookingData);

      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lab Test request sent successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OrderDetailFile(
              bookingId: '',
              bookingData: bookingData,
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request lab test: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount =
        widget.selectedTests.fold(0.0, (sum, item) => sum + item.price);
    final String formattedDate =
        DateFormat('dd MMM yyyy').format(widget.preferredDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Ice Purple background
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
                  backgroundColor: const Color(0xFF6C2BD9), // Purple button
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
                                'Pay Rs. ${totalAmount.toInt()} & Confirm Booking',
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
                      color: Colors.purple[700],
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
            // Top section with image, title and secure badge
            Stack(
              children: [
                Image.asset(
                  'assets/images/lab_test/confirm_booking_labtest.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.purple[100],
                    alignment: Alignment.center,
                    child: const Text('Banner Image Missing',
                        style: TextStyle(color: Colors.purple)),
                  ),
                ),
              ],
            ),
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
                          color: Colors.purple[700], size: 18),
                      const SizedBox(width: 6),
                      const Text(
                        'Order Summary',
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

                  // Tests details
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple[100]!),
                    ),
                    child: Column(
                      children: [
                        ...widget.selectedTests
                            .map((test) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(test.name,
                                          style: TextStyle(
                                              color: Colors.grey[800],
                                              fontSize: 11)),
                                      Text('Rs. ${test.price.toInt()}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ))
                            .toList(),
                        const Divider(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Lab Tests',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 11)),
                            Text('Rs. ${totalAmount.toInt()}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: Colors.purple)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  _buildDetailRow(Icons.calendar_today,
                      'Sample Collection Date', formattedDate),
                  _buildDetailRow(
                      Icons.location_on, 'Collection Address', widget.address),
                  _buildDetailRow(
                      Icons.person, 'Patient Name', widget.contactName),
                  _buildDetailRow(
                      Icons.phone, 'Mobile Number', widget.phoneNumber),
                  if (widget.city.isNotEmpty)
                    _buildDetailRow(Icons.location_city, 'City', widget.city),
                  if (widget.state.isNotEmpty)
                    _buildDetailRow(Icons.map_outlined, 'State', widget.state, isLast: true),
                  if (widget.city.isEmpty)
                    _buildDetailRow(
                        Icons.phone, 'Mobile Number', widget.phoneNumber,
                        isLast: true),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Details Section
            // Get Help Instantly Card
            GestureDetector(
              onTap: () {
                // Navigate to Help & Support
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.headset_mic_outlined, color: Colors.blue[900], size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Get Help Instantly',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.blue[900],
                            ),
                          ),
                          const Text(
                            "Contact Support: We're here to help you.",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.blue[900], size: 24),
                  ],
                ),
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
            Icon(icon, color: Colors.purple[700], size: 16),
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
