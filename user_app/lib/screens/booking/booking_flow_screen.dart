import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import '../../utils/app_colors.dart';

// Import UserTimeSlot specifically from user_model to avoid conflicts
import 'package:api_client/src/models/user_model.dart' show UserTimeSlot;
import 'package:user_app/screens/booking/order_request_screen.dart';

class BookingFlowScreen extends StatefulWidget {
  final User provider;
  final String serviceType;

  const BookingFlowScreen({
    super.key,
    required this.provider,
    required this.serviceType,
  });

  @override
  State<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends State<BookingFlowScreen> {
  final _apiClient = OnMintApiClient();
  final _notesController = TextEditingController();
  final _addressController = TextEditingController();

  DateTime? _selectedDate;
  UserTimeSlot? _selectedTimeSlot;
  bool _isLoading = false;
  bool _isLoadingAvailability = false;
  Map<String, dynamic>? _providerAvailability;

  @override
  void initState() {
    super.initState();
    _fetchProviderAvailability();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _fetchProviderAvailability() async {
    if (widget.serviceType != 'doctor' && widget.serviceType != 'nurse') {
      return; // Only fetch for doctors and nurses
    }

    setState(() => _isLoadingAvailability = true);

    try {
      await _apiClient.initialize();

      // Fetch provider availability
      final response =
          await _apiClient.patient.getDoctorAvailability(widget.provider.id);

      if (mounted) {
        setState(() {
          _providerAvailability = response;
          _isLoadingAvailability = false;
        });
      }
    } catch (e) {
      print('Error fetching availability: $e');
      if (mounted) {
        setState(() {
          _isLoadingAvailability = false;
          // Set empty availability so we show default slots
          _providerAvailability = {'availability': []};
        });
      }
    }
  }

  List<String> _getAvailableDays() {
    if (_providerAvailability == null ||
        _providerAvailability!['availability'] == null ||
        (_providerAvailability!['availability'] as List).isEmpty) {
      return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']; // Default weekdays
    }

    final availability = _providerAvailability!['availability'] as List;
    const dayMap = {
      'MONDAY': 'Mon',
      'TUESDAY': 'Tue',
      'WEDNESDAY': 'Wed',
      'THURSDAY': 'Thu',
      'FRIDAY': 'Fri',
      'SATURDAY': 'Sat',
      'SUNDAY': 'Sun',
    };

    return availability
        .where((a) {
          final slots = a['slots'] as List?;
          return slots != null && slots.any((s) => s['isAvailable'] != false);
        })
        .map((a) => dayMap[a['day']?.toString().toUpperCase()] ?? '')
        .where((day) => day.isNotEmpty)
        .toList();
  }

  List<UserTimeSlot> _getAvailableSlotsForDate(DateTime date) {
    // If no availability data or empty, use default slots
    if (_providerAvailability == null ||
        _providerAvailability!['availability'] == null ||
        (_providerAvailability!['availability'] as List).isEmpty) {
      return _generateDefaultTimeSlots(); // Fallback to default slots
    }

    final availability = _providerAvailability!['availability'] as List;

    // Get day of week (SUNDAY, MONDAY, etc.)
    const daysOfWeek = [
      'SUNDAY',
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY'
    ];
    final dayOfWeek = daysOfWeek[date.weekday % 7];

    // Find availability for this day
    final dayAvailability = availability.firstWhere(
      (a) => a['day']?.toString().toUpperCase() == dayOfWeek,
      orElse: () => null,
    );

    if (dayAvailability == null) {
      // No specific availability for this day, use default
      return _generateDefaultTimeSlots();
    }

    final slots = dayAvailability['slots'] as List?;
    if (slots == null || slots.isEmpty) {
      return _generateDefaultTimeSlots();
    }

    // Convert to UserTimeSlot objects
    return slots.where((slot) {
      return slot['isAvailable'] != false; // Only show available slots
    }).map<UserTimeSlot>((slot) {
      return UserTimeSlot(
        startTime: slot['startTime'] ?? '',
        endTime: slot['endTime'] ?? '',
        isAvailable: slot['isAvailable'] != false,
      );
    }).toList();
  }

  List<UserTimeSlot> _generateDefaultTimeSlots() {
    // Fallback: Generate time slots from 9 AM to 5 PM
    final slots = <UserTimeSlot>[];
    for (int hour = 9; hour <= 17; hour++) {
      final startTime = '${hour.toString().padLeft(2, '0')}:00';
      final endTime = '${(hour + 1).toString().padLeft(2, '0')}:00';
      slots.add(UserTimeSlot(
        startTime: startTime,
        endTime: endTime,
        isAvailable: hour != 13, // Lunch break at 1 PM
      ));
    }
    return slots;
  }

  Color get _serviceColor {
    switch (widget.serviceType.toLowerCase()) {
      case 'doctor':
        return AppColors.doctor;
      case 'nurse':
        return AppColors.nurse;
      case 'ambulance':
        return AppColors.ambulance;
      case 'pharmacy':
        return AppColors.pharmacy;
      case 'bloodbank':
        return AppColors.bloodBank;
      case 'pathology':
        return AppColors.pathology;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: _serviceColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _serviceColor.withOpacity(0.1),
                      child: Text(
                        widget.provider.firstName?[0].toUpperCase() ?? 'P',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _serviceColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.serviceType == 'doctor'
                                ? 'Dr. ${widget.provider.fullName}'
                                : widget.provider.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (widget.provider.specialization != null)
                            Text(
                              widget.provider.specialization!,
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
              ),
            ),

            const SizedBox(height: 24),

            // Date Selection
            const Text(
              'Select Date',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            // Available Days Indicator
            if (!_isLoadingAvailability &&
                (widget.serviceType == 'doctor' ||
                    widget.serviceType == 'nurse'))
              _buildAvailableDaysIndicator(),

            const SizedBox(height: 12),
            _buildDateSelector(),

            const SizedBox(height: 24),

            // Time Slot Selection
            if (_selectedDate != null) ...[
              const Text(
                'Select Time Slot',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeSlotSelector(),
              const SizedBox(height: 24),
            ],

            // Address
            const Text(
              'Address',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                hintText: 'Enter your address',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.location_on),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Notes
            const Text(
              'Additional Notes (Optional)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Any specific requirements or symptoms',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.note),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 24),

            // Price Summary
            if (widget.provider.consultationFee != null)
              Card(
                color: _serviceColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '₹${widget.provider.consultationFee!.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _serviceColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _serviceColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Confirm Booking',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableDaysIndicator() {
    final availableDays = _getAvailableDays();

    if (availableDays.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _serviceColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _serviceColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today,
            size: 16,
            color: _serviceColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Available: ${availableDays.join(", ")}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _serviceColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7, // Next 7 days
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected = _selectedDate?.day == date.day &&
              _selectedDate?.month == date.month &&
              _selectedDate?.year == date.year;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _selectedTimeSlot = null; // Reset time slot
              });
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? _serviceColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _serviceColor : Colors.grey[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getDayName(date.weekday),
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _getMonthName(date.month),
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimeSlotSelector() {
    if (_isLoadingAvailability) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Get available slots for selected date
    final timeSlots =
        _selectedDate != null ? _getAvailableSlotsForDate(_selectedDate!) : [];

    if (timeSlots.isEmpty) {
      return Card(
        color: Colors.blue[50],
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Using default time slots (9 AM - 5 PM). Provider availability not set.',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: timeSlots.map((slot) {
        final isSelected = _selectedTimeSlot?.startTime == slot.startTime;

        return GestureDetector(
          onTap: slot.isAvailable
              ? () {
                  setState(() => _selectedTimeSlot = slot);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: !slot.isAvailable
                  ? Colors.grey[200]
                  : isSelected
                      ? _serviceColor
                      : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: !slot.isAvailable
                    ? Colors.grey[300]!
                    : isSelected
                        ? _serviceColor
                        : Colors.grey[300]!,
              ),
            ),
            child: Text(
              slot.startTime,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: !slot.isAvailable
                    ? Colors.grey[400]
                    : isSelected
                        ? Colors.white
                        : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<UserTimeSlot> _generateTimeSlots() {
    // This method is now replaced by _getAvailableSlotsForDate
    // Kept for backward compatibility
    return _generateDefaultTimeSlots();
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _getMonthName(int month) {
    const months = [
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
    return months[month - 1];
  }

  Future<void> _confirmBooking() async {
    // Validation
    if (_selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a date'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (_selectedTimeSlot == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please select a time slot'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (_addressController.text.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter your address'),
              backgroundColor: Colors.red),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _apiClient.initialize();

      // Create booking
      final scheduledTime = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        int.parse(_selectedTimeSlot!.startTime.split(':')[0]),
        int.parse(_selectedTimeSlot!.startTime.split(':')[1]),
      );

      final bookingData = {
        'provider': widget.provider.id,
        'serviceType': widget.serviceType,
        'scheduledTime': scheduledTime.toIso8601String(),
        'location': {
          'address': _addressController.text.trim(),
        },
        'timeSlot': _selectedTimeSlot!.toJson(),
        'price': widget.provider.consultationFee ?? 0,
        'paymentMethod': 'cash', // Changed from COD to cash
      };

      // Add consultationType for doctor bookings (required by backend)
      if (widget.serviceType == 'doctor') {
        bookingData['consultationType'] =
            'in-person'; // Default to in-person for scheduled bookings
      }

      // Only add notes if not empty
      if (_notesController.text.trim().isNotEmpty) {
        bookingData['notes'] = _notesController.text.trim();
      }

      final booking = await _apiClient.patient.createBooking(bookingData);

      setState(() => _isLoading = false);

      if (mounted) {
        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: AppColors.success, size: 32),
                SizedBox(width: 12),
                Text('Booking Confirmed!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your booking has been confirmed successfully.'),
                const SizedBox(height: 16),
                Text(
                  'Booking ID: ${booking['_id'] ?? booking['id'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => OrderRequestScreen(
                        bookingId: booking['_id'] ?? booking['id'] ?? '',
                        bookingData: bookingData,
                        serviceType: widget.serviceType,
                      ),
                    ),
                    (route) => route.isFirst,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to create booking: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}
