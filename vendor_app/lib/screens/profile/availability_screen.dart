import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';

class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  late final HealthcareProviderService _providerService;
  late final String _providerType;
  
  Map<String, List<Map<String, dynamic>>> _availability = {};
  bool _isLoading = false;

  final List<String> _daysOfWeek = [
    'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'
  ];

  @override
  void initState() {
    super.initState();
    // Initialize service based on user role
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _providerType = authProvider.currentUser?.role ?? 'doctor';
    _providerService = HealthcareProviderService(_providerType);
    
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);

    try {
      final response = await _providerService.getAvailability();
      if (response.success && response.data != null) {
        final availabilityData = response.data!['availability'] ?? [];
        
        // Convert to our format
        final Map<String, List<Map<String, dynamic>>> availability = {};
        
        for (final dayData in availabilityData) {
          final day = dayData['day']?.toString() ?? '';
          final slots = List<Map<String, dynamic>>.from(dayData['slots'] ?? []);
          availability[day] = slots;
        }
        
        setState(() {
          _availability = availability;
        });
      }
    } catch (e) {
      print('Error loading availability: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isLoading = true);

    try {
      // Convert to API format based on provider type
      final List<Map<String, dynamic>> availabilityData = [];
      
      _availability.forEach((day, slots) {
        if (slots.isNotEmpty) {
          if (_providerType == 'nurse') {
            // Nurse format: {"availability": [{"day": "Monday","slots": [{"start": "08:00", "end": "20:00"}]}]}
            availabilityData.add({
              'day': day,
              'slots': slots.map((slot) => {
                'start': slot['startTime'] ?? '09:00',
                'end': slot['endTime'] ?? '17:00',
              }).toList(),
            });
          } else {
            // Doctor format: {"availability": [{"day": "MONDAY","slots": [{"startTime": "09:00","endTime": "12:00"}]}]}
            availabilityData.add({
              'day': day,
              'slots': slots,
            });
          }
        }
      });

      final response = await _providerService.setAvailability({
        'availability': availabilityData,
      });

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.error?.message ?? 'Failed to update availability'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating availability: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addTimeSlot(String day) {
    setState(() {
      if (_availability[day] == null) {
        _availability[day] = [];
      }
      _availability[day]!.add({
        'startTime': '09:00',
        'endTime': '17:00',
        'isAvailable': true,
      });
    });
  }

  void _removeTimeSlot(String day, int index) {
    setState(() {
      _availability[day]?.removeAt(index);
      if (_availability[day]?.isEmpty == true) {
        _availability.remove(day);
      }
    });
  }

  void _updateTimeSlot(String day, int index, String field, String value) {
    setState(() {
      if (_availability[day] != null && index < _availability[day]!.length) {
        _availability[day]![index][field] = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Availability'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveAvailability,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Set your weekly availability',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add time slots for each day when you are available for consultations.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  ..._daysOfWeek.map((day) => _buildDaySection(day)),
                ],
              ),
            ),
    );
  }

  Widget _buildDaySection(String day) {
    final slots = _availability[day] ?? [];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _formatDayName(day),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _addTimeSlot(day),
                  icon: const Icon(Icons.add_circle, color: AppColors.primary),
                  tooltip: 'Add time slot',
                ),
              ],
            ),
            
            if (slots.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No availability set for this day',
                  style: TextStyle(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...slots.asMap().entries.map((entry) {
                final index = entry.key;
                final slot = entry.value;
                return _buildTimeSlot(day, index, slot);
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String day, int index, Map<String, dynamic> slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          // Start time
          Expanded(
            child: GestureDetector(
              onTap: () => _selectTime(day, index, 'startTime', slot['startTime']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  slot['startTime'] ?? '09:00',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('to'),
          ),
          
          // End time
          Expanded(
            child: GestureDetector(
              onTap: () => _selectTime(day, index, 'endTime', slot['endTime']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  slot['endTime'] ?? '17:00',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Remove button
          IconButton(
            onPressed: () => _removeTimeSlot(day, index),
            icon: const Icon(Icons.delete, color: Colors.red),
            tooltip: 'Remove slot',
          ),
        ],
      ),
    );
  }

  Future<void> _selectTime(String day, int index, String field, String currentTime) async {
    final timeParts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(timeParts[0]) ?? 9,
      minute: int.tryParse(timeParts[1]) ?? 0,
    );

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      _updateTimeSlot(day, index, field, formattedTime);
    }
  }

  String _formatDayName(String day) {
    switch (day) {
      case 'MONDAY': return 'Monday';
      case 'TUESDAY': return 'Tuesday';
      case 'WEDNESDAY': return 'Wednesday';
      case 'THURSDAY': return 'Thursday';
      case 'FRIDAY': return 'Friday';
      case 'SATURDAY': return 'Saturday';
      case 'SUNDAY': return 'Sunday';
      default: return day;
    }
  }
}