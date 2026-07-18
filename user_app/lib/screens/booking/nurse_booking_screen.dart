import '../home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class NurseBookingScreen extends StatefulWidget {
  final Map<String, dynamic> nurse;

  const NurseBookingScreen({
    super.key,
    required this.nurse,
  });

  @override
  State<NurseBookingScreen> createState() => _NurseBookingScreenState();
}

class _NurseBookingScreenState extends State<NurseBookingScreen> {
  final _apiClient = OnMintApiClient();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedService;
  double _selectedPrice = 0;
  int _selectedDuration = 1; // in days
  bool _isLoading = false;
  String _userCity = '';
  String _userState = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;
      if (user != null) {
        setState(() {
          _userCity = user.city;
          _userState = user.state;
        });
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bookNurse() async {
    if (_selectedDate == null) {
      ToastUtils.showError('Please select a date');
      return;
    }

    if (_selectedService == null) {
      ToastUtils.showError('Please select a service');
      return;
    }

    if (_addressController.text.isEmpty) {
      ToastUtils.showError('Please enter your address');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final bookingData = {
        'provider': widget.nurse['_id'],
        'serviceType': 'nurse',
        'scheduledTime': _selectedDate!.toIso8601String(),
        'location': {
          'address': _addressController.text,
          'coordinates': [0.0, 0.0],
        },
        'notes': _notesController.text,
        'price': _selectedPrice * _selectedDuration,
        'city': _userCity,
        'state': _userState,
      };

      final booking = await _apiClient.patient.createBooking(bookingData);

      if (mounted) {
        _showSuccessDialog(booking);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog(dynamic booking) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Booking Confirmed!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking ID: ${booking['_id']}'),
            const SizedBox(height: 8),
            const Text(
              'Your nurse booking has been confirmed. The nurse will contact you shortly.',
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handle both 'services' and 'servicesOffered' keys from backend
    final services = (widget.nurse['servicesOffered'] as List? ??
        widget.nurse['services'] as List? ??
        []);

    return Scaffold(
      appBar: AppBar(

        title: const Text('Book Nurse'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: false, child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Nurse Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: const Icon(
                        Icons.local_hospital,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.nurse['firstName']} ${widget.nurse['lastName']}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.nurse['experience']} years experience',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Select Service
            const Text(
              'Select Service',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (services.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No services available for this nurse. Please contact support.',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...services.map<Widget>((service) {
                // Handle both object and string formats
                final serviceName = service is Map
                    ? (service['name'] ?? service.toString())
                    : service.toString();
                final price = service is Map
                    ? (service['pricePerHour']?.toDouble() ??
                        service['price']?.toDouble() ??
                        service['hourlyRate']?.toDouble() ??
                        0.0)
                    : 0.0;
                final isSelected = _selectedService == serviceName;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
                  child: RadioListTile<String>(
                    value: serviceName,
                    groupValue: _selectedService,
                    onChanged: (value) {
                      setState(() {
                        _selectedService = value;
                        _selectedPrice = price;
                      });
                    },
                    title: Text(serviceName),
                    subtitle: Text(
                      '₹$price per day',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    activeColor: AppColors.primary,
                  ),
                );
              }),
            const SizedBox(height: 24),

            // Select Date
            const Text(
              'Select Start Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading:
                    const Icon(Icons.calendar_today, color: AppColors.primary),
                title: Text(
                  _selectedDate == null
                      ? 'Choose a date'
                      : _formatDate(_selectedDate!),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),

            // Duration
            const Text(
              'Duration (Days)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: _selectedDuration > 1
                          ? () => setState(() => _selectedDuration--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.primary,
                    ),
                    Text(
                      '$_selectedDuration ${_selectedDuration == 1 ? 'day' : 'days'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedDuration++),
                      icon: const Icon(Icons.add_circle_outline),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Address
            const Text(
              'Your Address',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Address',
              controller: _addressController,
              hint: 'Enter your complete address',
              prefixIcon: Icons.location_on,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Additional Notes
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'Notes',
              controller: _notesController,
              hint: 'Any special requirements or instructions',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Price Summary
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Service Charge:'),
                        Text('₹${_selectedPrice.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration:'),
                        Text(
                            '$_selectedDuration ${_selectedDuration == 1 ? 'day' : 'days'}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${(_selectedPrice * _selectedDuration).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Book Button
            CustomButton(
              text: 'Confirm Booking',
              onPressed: _isLoading ? null : _bookNurse,
              isLoading: _isLoading,
            ),
          ],
        ),
      )),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }
}
