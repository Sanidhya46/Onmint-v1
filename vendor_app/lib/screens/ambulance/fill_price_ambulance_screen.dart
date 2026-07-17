import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:intl/intl.dart';
import '../booking/waiting_for_patient_screen.dart';

class FillPriceAmbulanceScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const FillPriceAmbulanceScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<FillPriceAmbulanceScreen> createState() => _FillPriceAmbulanceScreenState();
}

class _FillPriceAmbulanceScreenState extends State<FillPriceAmbulanceScreen> {
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
    
    String age = widget.bookingData['patientAge']?.toString() ?? '';
    if (age.isEmpty && patientData is Map) {
      age = patientData['age']?.toString() ?? '';
    }
    if (age.isEmpty) age = '--';

    String gender = widget.bookingData['patientGender']?.toString() ?? '';
    if (gender.isEmpty && patientData is Map) {
      gender = patientData['gender']?.toString() ?? '';
    }
    if (gender.isEmpty) gender = '--';
    
    var loc = widget.bookingData['location'];
    String pickup = 'Not specified';
    if (loc is Map) {
      pickup = loc['address'] ?? 'Not specified';
    } else if (loc is String) {
      pickup = loc;
    }
    if (pickup == 'Not specified' || pickup.isEmpty) {
      pickup = widget.bookingData['address'] ?? 'Not specified';
    }
    
    final dropoff = widget.bookingData['dropOffLocation'] ?? widget.bookingData['destination'] ?? 'Not specified';
    
    String reqTimeStr = 'Today, 09:30 AM';
    if (widget.bookingData['preferredDate'] != null) {
      final dt = DateTime.tryParse(widget.bookingData['preferredDate'].toString());
      if (dt != null) {
        final timeStr = widget.bookingData['requirements']?['preferredTime'] ?? widget.bookingData['preferredTime'] ?? '';
        if (timeStr.isNotEmpty) {
          reqTimeStr = '${DateFormat('dd MMM yyyy').format(dt)}, $timeStr';
        } else {
          reqTimeStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
        }
      }
    } else if (widget.bookingData['createdAt'] != null) {
      final dt = DateTime.tryParse(widget.bookingData['createdAt'].toString());
      if (dt != null) {
        reqTimeStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      }
    }

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
              'Set your price for this request',
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
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Patient Name Row
                    _buildRowItem(
                      icon: Icons.person,
                      iconColor: const Color(0xFF0056D2),
                      bgColor: const Color(0xFFF0F5FF),
                      label: 'Patient Name',
                      value: pName,
                    ),
                    Divider(color: Colors.grey.shade100, height: 24, thickness: 1),

                    // Age / Gender split row
                    Row(
                      children: [
                        Expanded(
                          child: _buildRowItem(
                            icon: Icons.calendar_month,
                            iconColor: const Color(0xFF0056D2),
                            bgColor: const Color(0xFFF0F5FF),
                            label: 'Age',
                            value: '$age Years',
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade100),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildRowItem(
                            icon: Icons.female,
                            iconColor: const Color(0xFF0056D2),
                            bgColor: const Color(0xFFF0F5FF),
                            label: 'Gender',
                            value: gender,
                          ),
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey.shade100, height: 24, thickness: 1),

                    // Pickup Location
                    _buildRowItem(
                      icon: Icons.location_on,
                      iconColor: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFEAFBEA),
                      label: 'Pickup Location',
                      value: pickup,
                    ),
                    Divider(color: Colors.grey.shade100, height: 24, thickness: 1),

                    // Drop-off Location
                    _buildRowItem(
                      icon: Icons.location_on,
                      iconColor: const Color(0xFFD32F2F),
                      bgColor: const Color(0xFFFDECEA),
                      label: 'Drop-off Location',
                      value: dropoff,
                    ),
                    Divider(color: Colors.grey.shade100, height: 24, thickness: 1),

                    // Request Time
                    _buildRowItem(
                      icon: Icons.access_time,
                      iconColor: const Color(0xFF0056D2),
                      bgColor: const Color(0xFFF0F5FF),
                      label: 'Request Time',
                      value: reqTimeStr,
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
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row: Rupee Icon in Green Circle
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Color(0xFF2E7D32),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.currency_rupee, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your Price',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                'Enter the total price for this trip',
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
                      'Enter Your Price (₹)',
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
                            color: const Color(0xFFEFFBEF),
                            border: Border(right: BorderSide(color: const Color(0xFF2E7D32).withOpacity(0.3))),
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
                    const SizedBox(height: 16),

                    // Additional Note Form
                    const Text(
                      'Additional Note (Optional)',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 11.5,
                        color: Color(0xFF152238),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextFormField(
                            controller: _noteController,
                            maxLines: 3,
                            maxLength: 120,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => const SizedBox.shrink(),
                            decoration: InputDecoration(
                              hintText: 'Add any note for the user...',
                              hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.all(12),
                              border: InputBorder.none,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0, bottom: 8.0),
                            child: Text(
                              '$_charCount/120',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Green Info Block
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
                          Icon(Icons.info, color: Color(0xFF2E7D32), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Set a fair price. Quick response increases your chances.',
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
                    const SizedBox(height: 10),

                    // Blue Info Block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF5FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: Color(0xFF0056D2), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'How it works\n• User will see all vendor prices and choose the best option.\n• You will be notified once the user selects you.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                color: Color(0xFF0056D2),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Submit Button
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
                                'Submit Price & Approach User',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0056D2),
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
                            'Your price will be visible to the user after submission.',
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
