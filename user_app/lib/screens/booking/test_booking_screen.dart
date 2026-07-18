import '../home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class TestBookingScreen extends StatefulWidget {
  final Map<String, dynamic> lab;
  final Map<String, dynamic> test;

  const TestBookingScreen({
    super.key,
    required this.lab,
    required this.test,
  });

  @override
  State<TestBookingScreen> createState() => _TestBookingScreenState();
}

class _TestBookingScreenState extends State<TestBookingScreen> {
  final _apiClient = OnMintApiClient();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedTimeSlot;
  bool _homeCollection = false;
  bool _isLoading = false;

  final List<String> _timeSlots = [
    '08:00 AM - 09:00 AM',
    '09:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '12:00 PM - 01:00 PM',
    '02:00 PM - 03:00 PM',
    '03:00 PM - 04:00 PM',
    '04:00 PM - 05:00 PM',
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _bookTest() async {
    if (_selectedDate == null) {
      ToastUtils.showError('Please select a date');
      return;
    }

    if (_selectedTimeSlot == null) {
      ToastUtils.showError('Please select a time slot');
      return;
    }

    if (_homeCollection && _addressController.text.isEmpty) {
      ToastUtils.showError('Please enter your address for home collection');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final bookingData = {
        'lab': widget.lab['_id'],
        'test': widget.test['name'],
        'scheduledDate': _selectedDate!.toIso8601String(),
        'timeSlot': _selectedTimeSlot,
        'homeCollection': _homeCollection,
        'address': _homeCollection ? _addressController.text : null,
        'notes': _notesController.text,
        'price': widget.test['price'],
      };

      final booking = await _apiClient.patient.createTestBooking(bookingData);

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
            Text(
              _homeCollection
                  ? 'Sample collection team will visit your address at the scheduled time.'
                  : 'Please visit the lab at the scheduled time.',
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
    final homeCollectionAvailable = widget.lab['homeCollection'] ?? false;
    final preparationRequired = widget.test['preparationRequired'] ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Test'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(padding: const EdgeInsets.only(bottom: 100),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lab & Test Info Card
            Card(
              color: Colors.purple.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.science,
                            color: Colors.purple, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.lab['name'] ?? 'Unknown Lab',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.test['name'] ?? 'Unknown Test',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${widget.test['price']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    if (preparationRequired) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.warning_amber,
                                color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Preparation required for this test. Please consult with the lab.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Select Date
            const Text(
              'Select Date',
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

            // Select Time Slot
            const Text(
              'Select Time Slot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _timeSlots.map((slot) {
                final isSelected = _selectedTimeSlot == slot;
                return InkWell(
                  onTap: () => setState(() => _selectedTimeSlot = slot),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.purple : Colors.white,
                      border: Border.all(
                        color:
                            isSelected ? Colors.purple : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      slot,
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Home Collection Option
            if (homeCollectionAvailable) ...[
              Card(
                child: CheckboxListTile(
                  value: _homeCollection,
                  onChanged: (value) {
                    setState(() => _homeCollection = value ?? false);
                  },
                  title: const Text('Home Sample Collection'),
                  subtitle:
                      const Text('Sample will be collected from your address'),
                  secondary: const Icon(Icons.home, color: AppColors.primary),
                  activeColor: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Address (if home collection)
            if (_homeCollection) ...[
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
            ],

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
              hint: 'Any special instructions',
              prefixIcon: Icons.note,
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Book Button
            CustomButton(
              text: 'Confirm Booking',
              onPressed: _isLoading ? null : _bookTest,
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
