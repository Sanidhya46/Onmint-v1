import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import '../../utils/app_colors.dart';

class BookingScreen extends StatefulWidget {
  final Map<String, dynamic> provider;
  final String serviceType;

  const BookingScreen({
    super.key,
    required this.provider,
    required this.serviceType,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  late final PatientService _patientService;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isEmergency = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _patientService = PatientService();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  Future<void> _createBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final scheduledDateTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );

      final bookingData = {
        'serviceType': widget.serviceType,
        'provider': widget.provider['_id'] ?? widget.provider['id'],
        'location': {
          'address': _addressController.text.trim(),
          'coordinates': [
            user.location?.longitude ?? 0.0,
            user.location?.latitude ?? 0.0,
          ],
        },
        'price': widget.provider['consultationFee'] ?? 0,
        'scheduledTime': scheduledDateTime.toIso8601String(),
        if (_symptomsController.text.trim().isNotEmpty)
          'symptoms': _symptomsController.text.trim(),
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
        'isEmergency': _isEmergency,
      };

      final response = await _patientService.createBooking(bookingData);

      // Response is a Map<String, dynamic>
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final providerName =
        '${widget.provider['firstName'] ?? ''} ${widget.provider['lastName'] ?? ''}'
            .trim();
    final specialization =
        widget.provider['specialization']?.toString() ?? 'Service Provider';
    final consultationFee =
        widget.provider['consultationFee']?.toString() ?? '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Provider Info Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            child: Text(
                              providerName.isNotEmpty
                                  ? providerName.substring(0, 1).toUpperCase()
                                  : 'S',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  providerName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  specialization,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Consultation Fee',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '₹$consultationFee',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Experience',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${widget.provider['experience'] ?? 0} years',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Date and Time Selection
              const Text(
                'Select Date & Time',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _selectedDate != null
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Select Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(
                        _selectedTime != null
                            ? _selectedTime!.format(context)
                            : 'Select Time',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Location
              const Text(
                'Location',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  hintText: 'Enter your address or clinic location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Symptoms (for doctors)
              if (widget.serviceType == 'doctor') ...[
                const Text(
                  'Symptoms',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _symptomsController,
                  decoration: const InputDecoration(
                    hintText: 'Describe your symptoms...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
              ],

              // Notes
              const Text(
                'Additional Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  hintText: 'Any additional information...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 24),

              // Emergency Checkbox
              CheckboxListTile(
                value: _isEmergency,
                onChanged: (value) {
                  setState(() => _isEmergency = value ?? false);
                },
                title: const Text('Mark as Emergency'),
                subtitle: const Text('This will prioritize your booking'),
                contentPadding: EdgeInsets.zero,
              ),

              const SizedBox(height: 32),

              // Book Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Confirm Booking',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
