import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../services/error_handler_service.dart';

import 'package:user_app/screens/booking/order_detail_file.dart';

class BookAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const BookAppointmentScreen({super.key, required this.doctor});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  late final PatientService _patientService;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  String _consultationType = 'in-person'; // Default to in-person
  Position? _currentPosition;

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

  Future<void> _useCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      // Request location permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get current position using geolocator directly
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Store position for later use
      _currentPosition = position;

      // Use a simple address format with coordinates
      final address =
          'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';

      setState(() {
        _addressController.text = address;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Current location set successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: ${e.toString()}'),
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

  Future<void> _selectDate() async {
    // Get available days from doctor's availability
    final availability = widget.doctor['availability'] as List?;

    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      selectableDayPredicate: (DateTime date) {
        // If no availability data, allow all days
        if (availability == null || availability.isEmpty) {
          return true;
        }

        // Check if the day is in doctor's availability
        final dayName = _getDayName(date.weekday);
        return availability.any((avail) =>
            avail['day']?.toString().toUpperCase() == dayName.toUpperCase());
      },
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
        _selectedTime = null; // Reset time when date changes
      });
    }
  }

  String _getDayName(int weekday) {
    const days = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY'
    ];
    return days[weekday - 1];
  }

  Future<void> _selectTime() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a date first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Get available time slots for the selected date
    final availability = widget.doctor['availability'] as List?;
    final dayName = _getDayName(_selectedDate!.weekday);

    List<Map<String, dynamic>> availableSlots = [];

    if (availability != null) {
      final dayAvailability = availability.firstWhere(
        (avail) =>
            avail['day']?.toString().toUpperCase() == dayName.toUpperCase(),
        orElse: () => null,
      );

      if (dayAvailability != null && dayAvailability['slots'] != null) {
        final slots = dayAvailability['slots'] as List;
        availableSlots = slots
            .where((slot) => slot['isAvailable'] == true)
            .map((slot) => {
                  'startTime': slot['startTime'],
                  'endTime': slot['endTime'],
                })
            .toList()
            .cast<Map<String, dynamic>>();
      }
    }

    if (availableSlots.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No available slots for this date'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Show dialog with available time slots
    final selectedSlot = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Time Slot'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableSlots.length,
            itemBuilder: (context, index) {
              final slot = availableSlots[index];
              return ListTile(
                title: Text('${slot['startTime']} - ${slot['endTime']}'),
                trailing: const Icon(Icons.access_time, color: Colors.green),
                onTap: () => Navigator.pop(context, slot),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedSlot != null) {
      // Parse the start time
      final startTime = selectedSlot['startTime'] as String;
      final parts = startTime.split(':');
      if (parts.length >= 2) {
        setState(() {
          _selectedTime = TimeOfDay(
            hour: int.parse(parts[0]),
            minute: int.parse(parts[1]),
          );
        });
      }
    }
  }

  Future<void> _bookAppointment() async {
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

      // Calculate price based on consultation type
      final basePrice = widget.doctor['consultationFee'] ?? 0;
      final consultationPrice = _consultationType == 'video-call'
          ? (basePrice * 0.8).round() // 20% discount for video calls
          : basePrice;

      final bookingData = {
        'serviceType': 'doctor',
        'provider': widget.doctor['_id'] ?? widget.doctor['id'] ?? '',
        'scheduledTime': scheduledDateTime.toIso8601String(),
        'consultationType': _consultationType,
        'symptoms': _symptomsController.text.trim(),
        'price': consultationPrice,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      // Only add location for in-person consultations
      if (_consultationType == 'in-person') {
        // Use current position if available, otherwise use user's stored location
        final latitude =
            _currentPosition?.latitude ?? user.location?.latitude ?? 0.0;
        final longitude =
            _currentPosition?.longitude ?? user.location?.longitude ?? 0.0;

        bookingData['location'] = {
          'address': _addressController.text.trim().isNotEmpty
              ? _addressController.text.trim()
              : 'Patient Location',
          'coordinates': [longitude, latitude],
        };
      }

      final bookingResponse = await _patientService.createBooking(bookingData);
      final bookingId = bookingResponse['_id'] ?? '';

      if (mounted) {
        ErrorHandlerService.showSuccess(
            context, 'Appointment booked successfully!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailFile(
              bookingId: bookingId,
              bookingData: bookingData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandlerService.showError(context, e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctorName =
        '${widget.doctor['firstName'] ?? ''} ${widget.doctor['lastName'] ?? ''}'
            .trim();
    final specialization =
        widget.doctor['specialization']?.toString() ?? 'Doctor';
    final consultationFee = widget.doctor['consultationFee']?.toString() ?? '0';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Doctor Info Card
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
                            backgroundColor: Colors.blue,
                            child: Text(
                              doctorName.isNotEmpty
                                  ? doctorName.substring(0, 1).toUpperCase()
                                  : 'D',
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
                                  doctorName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  specialization,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Consultation Fee: ₹$consultationFee',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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

              // Consultation Type Selection
              const Text(
                'Consultation Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          const Icon(Icons.person, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('In-Person Visit'),
                                Text(
                                  '₹$consultationFee',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      value: 'in-person',
                      groupValue: _consultationType,
                      onChanged: (value) {
                        setState(() => _consultationType = value!);
                      },
                    ),
                    const Divider(height: 1),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          const Icon(Icons.video_call, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Video Consultation'),
                                Text(
                                  '₹${(double.parse(consultationFee) * 0.8).round()} (20% off)',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      value: 'video-call',
                      groupValue: _consultationType,
                      onChanged: (value) {
                        setState(() => _consultationType = value!);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Symptoms
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your symptoms';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

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

              // Location (only for in-person consultations)
              if (_consultationType == 'in-person') ...[
                const Text(
                  'Location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _addressController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your address or clinic location',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                        validator: (value) {
                          if (_consultationType == 'in-person' &&
                              (value == null || value.trim().isEmpty)) {
                            return 'Please enter location for in-person visit';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _useCurrentLocation,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Current'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // Video call info
              if (_consultationType == 'video-call') ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'You will receive a video call link before your appointment time.',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const SizedBox(height: 32),

              // Book Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _bookAppointment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
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
                          'Book Appointment',
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
