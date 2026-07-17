import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components/ui_components.dart';
import 'package:intl/intl.dart';
import '../booking/waiting_for_patient_screen.dart';
class FillPriceBloodBankScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const FillPriceBloodBankScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<FillPriceBloodBankScreen> createState() => _FillPriceBloodBankScreenState();
}

class _FillPriceBloodBankScreenState extends State<FillPriceBloodBankScreen> {
  final _apiClient = OnMintApiClient();
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isSubmitting = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
    _noteController.addListener(() {
      setState(() {
        _charCount = _noteController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final double price = double.parse(_priceController.text.trim());
      final String note = _noteController.text.trim();

      await _apiClient.post(
        '/realtime-bookings/${widget.bookingId}/offer',
        data: {
          'amount': price,
          'note': note,
          'deliveryTime': 'Immediate',
        },
      );

      if (mounted) {
        ToastUtils.showSuccess('Offer submitted successfully');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => WaitingForPatientScreen(
              bookingId: widget.bookingId,
              bookingData: widget.bookingData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('no longer accepting offers') || errorMsg.contains('not found')) {
          ToastUtils.showError('This request is no longer available.');
          Navigator.pop(context, true);
        } else {
          ToastUtils.showError('Failed to submit offer: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientData = widget.bookingData['patient'] ?? widget.bookingData['patientDetails'] ?? {};
    String pName = '';
    if (patientData is Map) {
      pName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    }
    if (pName.isEmpty || pName == 'Patient') {
      pName = widget.bookingData['patientName'] ?? 'Patient';
    }
    
    final bloodGroup = widget.bookingData['bloodGroup']?.toString() ?? 'A-';
    final unitsRequired = widget.bookingData['unitsRequired']?.toString() ?? '1';
    final hospitalName = widget.bookingData['hospitalName']?.toString() ?? 'Not specified';
    
    var loc = widget.bookingData['location'];
    String address = 'Not specified';
    if (loc is Map) {
      address = loc['address'] ?? 'Not specified';
    } else if (loc is String) {
      address = loc;
    }
    if (address == 'Not specified' || address.isEmpty) {
      address = widget.bookingData['address'] ?? 'Not specified';
    }
    
    final emergencyNote = widget.bookingData['notes'] ?? widget.bookingData['requirements']?['description'] ?? 'Need ASAP';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF152238),
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0056D2)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Column(
          children: [
            Text(
              'Fill Your Price',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF152238),
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Set your price based on availability & service',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card 1: Patient details container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Name Row (Red themed)
                    _buildRowItem(
                      icon: Icons.person,
                      iconColor: const Color(0xFFE53935),
                      bgColor: const Color(0xFFFFEBEE),
                      label: 'Patient Name',
                      value: pName,
                    ),
                    const SizedBox(height: 14),

                    // Blood Group & Units Required split row
                    Row(
                      children: [
                        Expanded(
                          child: _buildRowItem(
                            icon: Icons.bloodtype,
                            iconColor: const Color(0xFFE53935),
                            bgColor: const Color(0xFFFFEBEE),
                            label: 'Blood Group',
                            value: bloodGroup,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildRowItem(
                            icon: Icons.local_hospital_outlined,
                            iconColor: const Color(0xFFE53935),
                            bgColor: const Color(0xFFFFEBEE),
                            label: 'Units Required',
                            value: '$unitsRequired Units',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Hospital Name
                    _buildRowItem(
                      icon: Icons.business,
                      iconColor: Colors.blue,
                      bgColor: const Color(0xFFE8F1FF),
                      label: 'Hospital Name',
                      value: hospitalName,
                    ),
                    const SizedBox(height: 14),

                    // Address / Location
                    _buildRowItem(
                      icon: Icons.location_on,
                      iconColor: Colors.green,
                      bgColor: const Color(0xFFE8F8F0),
                      label: 'Address / Location',
                      value: address,
                    ),
                    const SizedBox(height: 14),

                    // Emergency Note
                    _buildRowItem(
                      icon: Icons.assignment_late,
                      iconColor: Colors.orange,
                      bgColor: const Color(0xFFFFF3E0),
                      label: 'Emergency Note',
                      value: emergencyNote,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Set Your Price container
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Rupee Icon in Green Circle
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAFBEA),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.currency_rupee, color: Color(0xFF2E7D32), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Set Your Price',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Enter your total price for this blood request',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10.5,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Price Form input
                    const Text(
                      'Total Price (₹)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        color: Color(0xFF152238),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter amount',
                        hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade400),
                        prefixIcon: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border(right: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: const Icon(Icons.currency_rupee, color: Color(0xFF2E7D32), size: 18),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your price';
                        }
                        if (double.tryParse(value) == null || double.parse(value) <= 0) {
                          return 'Please enter a valid positive number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter the total price for this request.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Additional Note Form
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Additional Note (Optional)',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            color: Color(0xFF152238),
                          ),
                        ),
                        Text(
                          '$_charCount/120',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10.5,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      maxLength: 120,
                      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
                      decoration: InputDecoration(
                        hintText: 'Add a note for the user (optional)',
                        hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.all(12),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade500, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Red Alert block (since it's blood bank emergency themed)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFFCDD2)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline, color: Color(0xFFD32F2F), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Set your price based on blood availability, blood group, urgency, and delivery distance.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                color: Color(0xFFD32F2F),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Green Lightbulb Block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFBEF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tip: Competitive pricing and quick response increase your chances of getting selected.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                color: Color(0xFF2E7D32),
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button (Red themed)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitOffer,
                        icon: _isSubmitting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.send, color: Colors.white, size: 16),
                        label: _isSubmitting
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Submit Price & Contact User',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD32F2F),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lock center label
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock, color: Colors.grey.shade400, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'The user will compare all offers and choose one.\nYou will be notified if your offer is accepted.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10.5,
                              color: Colors.grey.shade500,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRowItem({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF152238),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
