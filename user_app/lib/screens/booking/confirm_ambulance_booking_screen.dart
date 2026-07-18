import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:user_app/screens/booking/order_request_screen.dart';

class ConfirmAmbulanceBookingScreen extends StatefulWidget {
  final String pickupLocation;
  final String dropoffLocation;
  final String name;
  final String phone;
  final int age;
  final String gender;
  final String notes;
  final List<double> coordinates;
  final String city;
  final String state;

  const ConfirmAmbulanceBookingScreen({
    Key? key,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.name,
    required this.phone,
    required this.age,
    required this.gender,
    required this.notes,
    required this.coordinates,
    required this.city,
    required this.state,
  }) : super(key: key);

  @override
  State<ConfirmAmbulanceBookingScreen> createState() =>
      _ConfirmAmbulanceBookingScreenState();
}

class _ConfirmAmbulanceBookingScreenState
    extends State<ConfirmAmbulanceBookingScreen> {
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
        'serviceType': 'ambulance',
        'address': widget.pickupLocation,
        'dropOffLocation': widget.dropoffLocation,
        'name': widget.name,
        'phone': widget.phone,
        'patientAge': widget.age,
        'patientGender': widget.gender,
        'notes': widget.notes,
        'urgency': 'high',
        'isEmergency': true,
        'paymentMethod': _selectedPayment,
        'totalAmount': 799,
        'coordinates': widget.coordinates,
        'city': widget.city,
        'state': widget.state,
      };

      final resp = await _apiClient.patient.createRealtimeBooking(bookingData);
      final newBookingId = resp['_id']?.toString() ?? resp['id']?.toString() ?? '';

      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ambulance request sent successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
              builder: (context) => OrderRequestScreen(
                bookingId: newBookingId,
                bookingData: resp,
                serviceType: 'ambulance',
              ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to request ambulance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF5F5), // Ice Red background
      bottomNavigationBar: SafeArea(
child: Container(
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
              height: 48,
              child: ElevatedButton(
                onPressed: _isBooking ? null : _handlePayAndConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935), // Red button
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isBooking
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
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
                                'Pay Rs. 799 & Confirm Booking',
                                style: TextStyle(
                                    fontSize: 15,
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
            const SizedBox(height: 10),
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
                      color: Colors.red,
                      fontSize: 11,
                      decoration: TextDecoration.underline),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom > 0 ? 0 : 6),
          ],
        ),
      )
),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            // Top Section
            Stack(
              children: [
                Image.asset(
                  'assets/images/ambulance/ambulance_confirm_booking_image.jpeg',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.red[50],
                    child: const Center(
                        child:
                            Icon(Icons.image_not_supported, color: Colors.red)),
                  ),
                ),

              ],
            ),
            Column(
              children: [
                // Booking Summary Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                color: Colors.red[700], size: 20),
                            const SizedBox(width: 8),
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
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        _buildSummaryRow(Icons.location_on_outlined,
                            'Pickup Location', widget.pickupLocation),
                        _buildSummaryRow(
                            Icons.location_on_outlined,
                            'Drop-off Location',
                            widget.dropoffLocation.isEmpty
                                ? 'Not specified'
                                : widget.dropoffLocation,
                            iconColor: Colors.red[600],
                            valueColor: Colors.red[700]),
                        _buildSummaryRow(
                            Icons.person_outline, 'Contact Name', widget.name),
                        _buildSummaryRow(
                            Icons.phone_outlined, 'Phone Number', widget.phone),
                        _buildSummaryRow(Icons.calendar_today_outlined, 'Age',
                            widget.age.toString()),
                        _buildSummaryRow(
                            Icons.person_outline, 'Gender', widget.gender),
                        _buildSummaryRow(
                            Icons.location_city, 'City', widget.city),
                        _buildSummaryRow(
                            Icons.map_outlined, 'State', widget.state),
                        _buildSummaryRow(
                            Icons.note_alt_outlined,
                            'Additional Details',
                            widget.notes.isEmpty ? 'None' : widget.notes,
                            isLast: true),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.red[400], size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'You will be contacted by the nearest ambulance team shortly.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[800],
                                    height: 1.3,
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

                const SizedBox(height: 12),

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
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      )),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value,
      {bool isLast = false, Color? iconColor, Color? valueColor}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor ?? Colors.red[600], size: 18),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 11),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                    color: valueColor ?? Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 11),
              ),
            ),
          ],
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Divider(height: 1),
          ),
      ],
    );
  }


}
