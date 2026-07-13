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
        'paymentMethod': 'direct_to_vendor',
        'totalAmount': 499, // From UI
      };

      final resp = await _apiClient.patient.createRealtimeBooking(bookingData);
      final newBookingId = resp['_id']?.toString() ?? resp['id']?.toString() ?? '';

      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nurse request sent successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OrderRequestScreen(
              bookingId: newBookingId,
              bookingData: resp,
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
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
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
                            'Confirm Booking',
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

                // Nearest Nurse
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
                                child: Icon(Icons.person, color: Colors.blue[700], size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Nearest Nurse',
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
                                  child: Icon(Icons.medical_services, color: Colors.blue[700], size: 20),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Care & Comfort Nursing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
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
                                            Text('2.0 km away', style: TextStyle(color: Colors.blue[700], fontSize: 8, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Available: General Care,\nPost-surgery Care, Eldercare',
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
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    ));
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

}
