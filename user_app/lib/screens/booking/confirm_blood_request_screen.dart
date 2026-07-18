import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'order_request_screen.dart';

class ConfirmBloodRequestScreen extends StatefulWidget {
  final String patientName;
  final String bloodGroup;
  final String unitsRequired;
  final String hospitalName;
  final String contactNumber;
  final String address;
  final String emergencyNote;
  final String city;
  final String state;

  const ConfirmBloodRequestScreen({
    Key? key,
    required this.patientName,
    required this.bloodGroup,
    required this.unitsRequired,
    required this.hospitalName,
    required this.contactNumber,
    required this.address,
    required this.emergencyNote,
    required this.city,
    required this.state,
  }) : super(key: key);

  @override
  State<ConfirmBloodRequestScreen> createState() => _ConfirmBloodRequestScreenState();
}

class _ConfirmBloodRequestScreenState extends State<ConfirmBloodRequestScreen> {
  bool _isLoading = false;
  final _apiClient = OnMintApiClient();

  Future<void> _submitRequest() async {
    setState(() => _isLoading = true);
    try {
      final requestData = {
        'serviceType': 'bloodbank',
        'title': 'Blood Request - ${widget.bloodGroup}',
        'description': widget.emergencyNote.isEmpty ? 'Need ${widget.unitsRequired} units of ${widget.bloodGroup} blood' : widget.emergencyNote,
        'patientName': widget.patientName,
        'patientPhone': widget.contactNumber,
        'hospitalName': widget.hospitalName,
        'bloodGroup': widget.bloodGroup,
        'unitsRequired': int.tryParse(widget.unitsRequired) ?? 1,
        'isEmergency': true,
        'address': widget.address,
        'coordinates': [0, 0],
        'city': widget.city,
        'state': widget.state,
      };

      final resp = await _apiClient.patient.createRealtimeBooking(requestData);
      final newBookingId = resp['_id']?.toString() ?? resp['id']?.toString() ?? '';

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Blood request sent successfully!')),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => OrderRequestScreen(
              bookingId: newBookingId,
              bookingData: resp,
              serviceType: 'blood_request',
            ),
          ),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
        backgroundColor: Colors.white,
      bottomNavigationBar: SafeArea(
child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828), // Dark Red matching UI
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Stack(
                    alignment: Alignment.center,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.lock_outline, color: Colors.white, size: 18),
                      ),
                      const Align(
                        alignment: Alignment.center,
                        child: Text(
                          'Confirm Request & Contact',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_forward, color: Color(0xFFC62828), size: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, color: Colors.grey[500], size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'By proceeding, you agree to our ',
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                  const Text(
                    'Terms & Conditions',
                    style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      )
),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section
            Stack(
              children: [
                Image.asset(
                  'assets/images/bloodbank/bloodbank_confirm_booking.png',
                  width: double.infinity,
                  fit: BoxFit.fitWidth,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: double.infinity,
                    height: 150,
                    color: Colors.red[50],
                    alignment: Alignment.center,
                    child: const Text('Banner Missing', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Request Summary
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.red[700],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Request Summary',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSummaryRow(Icons.person_outline, 'Patient Name', widget.patientName),
                  _buildSummaryRow(Icons.water_drop_outlined, 'Blood Group', widget.bloodGroup),
                  _buildSummaryRow(Icons.water_drop_outlined, 'Units Required', '${widget.unitsRequired} Units'),
                  _buildSummaryRow(Icons.local_hospital_outlined, 'Hospital Name', widget.hospitalName),
                  _buildSummaryRow(Icons.phone_outlined, 'Contact Number', widget.contactNumber),
                  _buildSummaryRow(Icons.location_on_outlined, 'Address / Location', widget.address),
                  if (widget.city.isNotEmpty)
                    _buildSummaryRow(Icons.location_city, 'City', widget.city),
                  if (widget.state.isNotEmpty)
                    _buildSummaryRow(Icons.map_outlined, 'State', widget.state),
                  _buildSummaryRow(Icons.note_alt_outlined, 'Emergency Note', widget.emergencyNote.isEmpty ? 'Need ASAP' : widget.emergencyNote, showDivider: false),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nearest Blood Bank
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
                              color: Colors.red[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.water_drop, color: Colors.red[700], size: 16),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Nearest Blood Bank',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      Text('View All', style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2F2),
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
                              child: Icon(Icons.volunteer_activism, color: Colors.red[700], size: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('LifeCare Blood Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.location_on_outlined, color: Colors.red[700], size: 8),
                                        const SizedBox(width: 2),
                                        Text('2.5 km away', style: TextStyle(color: Colors.red[700], fontSize: 8, fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Available: O+ (10), A+ (5),\nB+ (3), AB+ (2)',
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
                                  child: Icon(Icons.phone, color: Colors.red[700], size: 20),
                                ),
                                const SizedBox(height: 4),
                                Text('Call', style: TextStyle(fontSize: 10, color: Colors.grey[800], fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                  child: Image.asset('assets/images/whatsap_icon.png', width: 24, height: 24),
                                ),
                                const SizedBox(height: 4),
                                Text('WhatsApp', style: TextStyle(fontSize: 10, color: Colors.grey[800], fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.red[700], size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Contact the blood bank directly to confirm availability.',
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
            const SizedBox(height: 30),
          ],
        ),
      )),
    ));
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, {bool showDivider = true}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.grey[500], size: 16),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 11),
              ),
            ),
          ],
        ),
        if (showDivider) ...[
          const SizedBox(height: 8),
          Divider(color: Colors.grey[200], thickness: 1, height: 1),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
