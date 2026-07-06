import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';

class BloodRequestDetailsScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? initialData;

  const BloodRequestDetailsScreen({
    super.key,
    required this.bookingId,
    this.initialData,
  });

  @override
  State<BloodRequestDetailsScreen> createState() =>
      _BloodRequestDetailsScreenState();
}

class _BloodRequestDetailsScreenState
    extends State<BloodRequestDetailsScreen> {
  bool _isSubmitting = false;
  bool _isLoadingData = false;
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _noteController = TextEditingController();
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
    if (widget.initialData != null) {
      _booking = widget.initialData;
    } else {
      _fetchBooking();
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _fetchBooking() async {
    setState(() => _isLoadingData = true);
    try {
      final res = await _apiClient.get('/realtime/${widget.bookingId}');
      if (mounted) {
        setState(() {
          _booking = res.data['data'] ?? {};
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  String _safeAddress(dynamic loc, [String fallback = 'Not specified']) {
    if (loc == null) return fallback;
    if (loc is String) return loc.isEmpty ? fallback : loc;
    if (loc is Map) {
      final addr = loc['address'];
      if (addr is Map) {
        return addr['address']?.toString() ??
            addr['street']?.toString() ??
            fallback;
      }
      if (addr != null) return addr.toString();
      return loc['street']?.toString() ??
          loc['city']?.toString() ??
          fallback;
    }
    return loc.toString();
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
        Navigator.pop(context, true);
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
    if (_isLoadingData) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFC62828))));
    }
    if (_booking == null) {
      return const Scaffold(body: Center(child: Text('Request not found')));
    }

    final b = _booking!;
    final patient = b['patientDetails'] ?? b['patient'] ?? {};
    final patientName = (patient is Map)
        ? (patient['fullName'] ??
            '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim())
        : (b['patientName'] ?? 'Patient');
    
    final bloodGroup = b['bloodGroup'] ?? 'N/A';
    final units = b['unitsRequired']?.toString() ?? b['units']?.toString() ?? '1';
    final hospitalName = b['hospitalName'] ?? 'Not specified';
    final address = _safeAddress(b['location'] ?? b['address']);
    final emergencyNote = b['description'] ?? b['notes'] ?? b['emergencyNote'] ?? 'No notes';

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF152238),
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
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
        padding: const EdgeInsets.all(16),
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
                      iconColor: const Color(0xFFD32F2F),
                      bgColor: const Color(0xFFFDECEA),
                      label: 'Patient Name',
                      value: patientName.isNotEmpty ? patientName : 'N/A',
                    ),
                    Divider(color: Colors.grey.shade100, height: 24, thickness: 1),

                    // Blood Group / Units split row
                    Row(
                      children: [
                        Expanded(
                          child: _buildRowItem(
                            icon: Icons.water_drop,
                            iconColor: const Color(0xFFD32F2F),
                            bgColor: const Color(0xFFFDECEA),
                            label: 'Blood Group',
                            value: bloodGroup,
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade100),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildRowItem(
                            icon: Icons.medical_information,
                            iconColor: const Color(0xFFD32F2F),
                            bgColor: const Color(0xFFFDECEA),
                            label: 'Units Required',
                            value: '$units Units',
                          ),
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey.shade100, height: 24, thickness: 1),

                    // Hospital Name
                    _buildRowItem(
                      icon: Icons.local_hospital,
                      iconColor: const Color(0xFF0056D2),
                      bgColor: const Color(0xFFF0F5FF),
                      label: 'Hospital Name',
                      value: hospitalName,
                    ),
                    Divider(color: Colors.grey.shade100, height: 24, thickness: 1),

                    // Address / Location
                    _buildRowItem(
                      icon: Icons.location_on,
                      iconColor: const Color(0xFF2E7D32),
                      bgColor: const Color(0xFFEAFBEA),
                      label: 'Address / Location',
                      value: address,
                    ),
                    Divider(color: Colors.grey.shade100, height: 24, thickness: 1),

                    // Emergency Note
                    _buildRowItem(
                      icon: Icons.note_alt,
                      iconColor: Colors.orange.shade700,
                      bgColor: Colors.orange.shade50,
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
                            color: const Color(0xFFFDECEA),
                            border: Border(right: BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: const Icon(Icons.currency_rupee, color: Color(0xFF152238), size: 18),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.red),
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
                    const SizedBox(height: 6),
                    Text(
                      'Enter the total price for this request.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10.5,
                        color: Colors.grey.shade500,
                      ),
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
                              hintText: 'Add a note for the user (optional)',
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

                    // Red Info Block
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDECEA),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info, color: Color(0xFFD32F2F), size: 18),
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
                          Icon(Icons.lightbulb_outline, color: Color(0xFF2E7D32), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tip: Competitive pricing and quick response increase your chances of getting selected.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10.5,
                                color: Color(0xFF2E7D32),
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
