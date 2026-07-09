import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import '../booking/order_request_screen.dart';

/// Instant Booking Screen - Quick emergency service booking
/// Supports: doctor, ambulance, and nurse services
class InstantBookingScreen extends StatefulWidget {
  final String serviceType; // 'doctor', 'ambulance', or 'nurse'

  const InstantBookingScreen({
    super.key,
    required this.serviceType,
  });

  @override
  State<InstantBookingScreen> createState() => _InstantBookingScreenState();
}

class _InstantBookingScreenState extends State<InstantBookingScreen> {
  final _apiClient = OnMintApiClient();

  bool _isGettingLocation = false;
  bool _isBooking = false;
  Position? _currentPosition;
  String _locationStatus = 'Detecting your location...';
  String _currentAddress = '';
  String? _selectedNurseService;
  int _nurseDuration = 1; // days
  String? _selectedBloodGroup;
  int _bloodUnits = 1;
  final Set<String> _selectedLabTests = {}; // Multiple tests
  String _userCity = '';
  String _userState = '';

  @override
  void initState() {
    super.initState();
    _initializeAndGetLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadUserCityState());
  }

  void _loadUserCityState() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null) {
      setState(() {
        _userCity = user.city;
        _userState = user.state;
      });
    }
  }

  Future<void> _initializeAndGetLocation() async {
    // Initialize API client first to load auth token
    await _apiClient.initialize();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationStatus = 'Detecting your location...';
    });

    try {
      // Request location permission
      final permission = await Permission.location.request();
      if (!permission.isGranted) {
        setState(() {
          _locationStatus = 'Location permission denied';
          _isGettingLocation = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          _currentAddress = [
            place.street,
            place.subLocality,
            place.locality,
            place.administrativeArea,
            place.postalCode,
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        }
      } catch (e) {
        _currentAddress = 'Address not available';
      }

      setState(() {
        _currentPosition = position;
        _locationStatus =
            'Location detected: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        _isGettingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationStatus = 'Failed to get location: ${e.toString()}';
        _isGettingLocation = false;
      });
    }
  }

  Future<void> _bookInstantService() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for location detection'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate nurse service selection
    if (widget.serviceType == 'nurse' && _selectedNurseService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a nurse service'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate blood group selection
    if (widget.serviceType == 'bloodbank' && _selectedBloodGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a blood group'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Validate lab test selection
    if (widget.serviceType == 'pathology' && _selectedLabTests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one lab test'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isBooking = true);

    try {
      String newBookingId = '';
      Map<String, dynamic> createdData = {};

      if (widget.serviceType == 'nurse') {
        // Create realtime nurse booking to notify all nearby nurses
        final bookingData = {
          'serviceType': 'nurse',
          'description':
              'Home nursing service required - $_selectedNurseService for $_nurseDuration day(s)',
          'urgency': 'medium',
          'preferredTime':
              DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          'specialRequirements':
              '$_selectedNurseService required for $_nurseDuration day(s)',
          'address': _currentAddress.isNotEmpty
              ? _currentAddress
              : 'Address not available',
          'coordinates': [
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          ],
          'isEmergency': false,
          'notes':
              'Instant nurse booking - $_selectedNurseService for $_nurseDuration day(s)',
          'totalAmount': 500.0 * _nurseDuration,
          'nurseService': _selectedNurseService,
          'duration': _nurseDuration,
          'city': _userCity,
          'state': _userState,
        };

        final resp = await _apiClient.patient.createRealtimeBooking(bookingData);
        newBookingId = resp['_id']?.toString() ?? resp['id']?.toString() ?? '';
        createdData = resp;
      } else if (widget.serviceType == 'bloodbank') {
        // Create blood bank booking
        final bookingData = {
          'serviceType': 'bloodbank',
          'scheduledTime':
              DateTime.now().add(const Duration(hours: 1)).toIso8601String(),
          'location': {
            'address': _currentAddress.isNotEmpty
                ? _currentAddress
                : 'Address not available',
            'coordinates': [
              _currentPosition!.longitude,
              _currentPosition!.latitude,
            ],
          },
          'bloodGroup': _selectedBloodGroup,
          'unitsRequired': _bloodUnits,
          'notes':
              'Emergency blood request - $_selectedBloodGroup, $_bloodUnits unit(s)',
          'price': 500.0 * _bloodUnits,
          'city': _userCity,
          'state': _userState,
        };

        final resp = await _apiClient.patient.createBooking(bookingData);
        newBookingId = resp['_id']?.toString() ?? resp['id']?.toString() ?? '';
        createdData = resp;
      } else if (widget.serviceType == 'pathology') {
        // Create realtime pathology booking to notify all nearby labs
        final testsList = _selectedLabTests.map((testName) {
          // Extract price from test name (e.g., "CBC - ₹500" -> 500)
          final priceMatch = RegExp(r'₹(\d+)').firstMatch(testName);
          final price =
              priceMatch != null ? int.parse(priceMatch.group(1)!) : 500;
          return {'name': testName.split(' - ')[0], 'price': price};
        }).toList();

        final totalPrice = testsList.fold<double>(
            0, (sum, test) => sum + (test['price'] as int).toDouble());

        final bookingData = {
          'serviceType': 'pathology',
          'description':
              'Lab test booking - ${_selectedLabTests.length} test(s) required. Home collection preferred.',
          'urgency': 'medium',
          'preferredTime':
              DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
          'specialRequirements':
              'Home collection required for ${_selectedLabTests.join(", ")}',
          'address': _currentAddress.isNotEmpty
              ? _currentAddress
              : 'Address not available',
          'coordinates': [
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          ],
          'isEmergency': false,
          'notes':
              'Instant lab test booking - ${_selectedLabTests.length} test(s)',
          'totalAmount': totalPrice,
          'tests': testsList,
          'homeCollection': true,
          'city': _userCity,
          'state': _userState,
        };

        final resp = await _apiClient.patient.createRealtimeBooking(bookingData);
        newBookingId = resp['_id']?.toString() ?? resp['id']?.toString() ?? '';
        createdData = resp;
      } else {
        // Create realtime booking for doctor/ambulance
        final bookingData = {
          'serviceType': widget.serviceType,
          'description': widget.serviceType == 'doctor'
              ? 'Emergency doctor consultation needed. Immediate medical attention required.'
              : 'Emergency ambulance needed. Immediate assistance required.',
          'urgency': 'emergency',
          'preferredTime':
              DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
          'specialRequirements': widget.serviceType == 'doctor'
              ? 'Video consultation required immediately'
              : 'Emergency medical transport needed',
          'address': _currentAddress.isNotEmpty
              ? _currentAddress
              : 'Address not available',
          'coordinates': [
            _currentPosition!.longitude,
            _currentPosition!.latitude,
          ],
          'isEmergency': true,
          'notes': widget.serviceType == 'doctor'
              ? 'Emergency video consultation request'
              : 'Emergency ambulance request',
          if (widget.serviceType != 'doctor') ...{
            'city': _userCity,
            'state': _userState,
          },
        };

        // Add consultationType for doctor
        if (widget.serviceType == 'doctor') {
          bookingData['consultationType'] = 'video-call';
        }

        final resp = await _apiClient.patient.createRealtimeBooking(bookingData);
        newBookingId = resp['_id']?.toString() ?? resp['id']?.toString() ?? '';
        createdData = resp;
      }

      if (mounted) {
        String message;
        switch (widget.serviceType) {
          case 'doctor':
            message =
                'Emergency doctor request sent! Nearby doctors will be notified.';
            break;
          case 'ambulance':
            message =
                'Emergency ambulance request sent! Nearby ambulances will be notified.';
            break;
          case 'nurse':
            message =
                'Nurse booking request sent! A nurse will be assigned shortly.';
            break;
          case 'bloodbank':
            message =
                'Blood request sent! Nearby blood banks will be notified.';
            break;
          case 'pathology':
            message =
                'Lab test booking sent! A technician will visit for sample collection.';
            break;
          default:
            message = 'Booking request sent successfully!';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OrderRequestScreen(
              bookingId: newBookingId,
              bookingData: createdData.isNotEmpty ? createdData : {},
              serviceType: widget.serviceType,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDoctor = widget.serviceType == 'doctor';
    final isAmbulance = widget.serviceType == 'ambulance';
    final isNurse = widget.serviceType == 'nurse';
    final isBloodBank = widget.serviceType == 'bloodbank';
    final isPathology = widget.serviceType == 'pathology';

    Color color;
    IconData icon;
    String title;
    String description;

    if (isDoctor) {
      color = Colors.blue;
      icon = Icons.video_call;
      title = 'Instant Doctor Consultation';
      description = 'Get instant video consultation with an available doctor';
    } else if (isAmbulance) {
      color = Colors.red;
      icon = Icons.local_shipping;
      title = 'Emergency Ambulance';
      description = 'Request emergency ambulance service to your location';
    } else if (isNurse) {
      color = Colors.pink;
      icon = Icons.local_hospital;
      title = 'Instant Nurse Booking';
      description = 'Book a nurse for home care service';
    } else if (isBloodBank) {
      color = const Color(0xFFFF416C);
      icon = Icons.bloodtype;
      title = 'Emergency Blood Request';
      description = 'Request blood from nearby blood banks';
    } else {
      color = const Color(0xFFFF6B6B);
      icon = Icons.science;
      title = 'Instant Lab Test';
      description = 'Book lab test with home sample collection';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Service Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 80,
                color: color,
              ),
            ),

            const SizedBox(height: 32),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Location Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(
                    _currentPosition != null
                        ? Icons.location_on
                        : Icons.location_searching,
                    color:
                        _currentPosition != null ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Location',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _locationStatus,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isGettingLocation)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nurse-specific options
            if (isNurse) ...[
              // Service Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Service',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedNurseService,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Choose service type'),
                      items: const [
                        DropdownMenuItem(
                            value: 'General Care',
                            child: Text('General Care - ₹500/day')),
                        DropdownMenuItem(
                            value: 'Post-Surgery Care',
                            child: Text('Post-Surgery Care - ₹800/day')),
                        DropdownMenuItem(
                            value: 'Elderly Care',
                            child: Text('Elderly Care - ₹600/day')),
                        DropdownMenuItem(
                            value: 'Wound Dressing',
                            child: Text('Wound Dressing - ₹400/day')),
                        DropdownMenuItem(
                            value: 'Injection Administration',
                            child: Text('Injection - ₹300/day')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedNurseService = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Duration Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Duration',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _nurseDuration > 1
                              ? () => setState(() => _nurseDuration--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: color,
                        ),
                        Text(
                          '$_nurseDuration ${_nurseDuration == 1 ? 'day' : 'days'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _nurseDuration++),
                          icon: const Icon(Icons.add_circle_outline),
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price Summary for Nurse
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.5), width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Service:', style: TextStyle(fontSize: 14)),
                        Text(_selectedNurseService ?? 'Not selected',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Duration:', style: TextStyle(fontSize: 14)),
                        Text(
                            '$_nurseDuration ${_nurseDuration == 1 ? 'day' : 'days'}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Cost:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '₹${500 * _nurseDuration}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Blood Bank specific options
            if (isBloodBank) ...[
              // Blood Group Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Blood Group',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedBloodGroup,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      hint: const Text('Choose blood group'),
                      items: const [
                        DropdownMenuItem(value: 'A+', child: Text('A+')),
                        DropdownMenuItem(value: 'A-', child: Text('A-')),
                        DropdownMenuItem(value: 'B+', child: Text('B+')),
                        DropdownMenuItem(value: 'B-', child: Text('B-')),
                        DropdownMenuItem(value: 'AB+', child: Text('AB+')),
                        DropdownMenuItem(value: 'AB-', child: Text('AB-')),
                        DropdownMenuItem(value: 'O+', child: Text('O+')),
                        DropdownMenuItem(value: 'O-', child: Text('O-')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedBloodGroup = value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Units Selection
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Units Required',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          onPressed: _bloodUnits > 1
                              ? () => setState(() => _bloodUnits--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: color,
                        ),
                        Text(
                          '$_bloodUnits ${_bloodUnits == 1 ? 'unit' : 'units'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _bloodUnits++),
                          icon: const Icon(Icons.add_circle_outline),
                          color: color,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price Summary for Blood Bank
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.5), width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Blood Group:',
                            style: TextStyle(fontSize: 14)),
                        Text(_selectedBloodGroup ?? 'Not selected',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Units:', style: TextStyle(fontSize: 14)),
                        Text(
                            '$_bloodUnits ${_bloodUnits == 1 ? 'unit' : 'units'}',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Estimated Cost:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '₹${500 * _bloodUnits}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Pathology specific options
            if (isPathology) ...[
              // Lab Test Selection (Multiple)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Lab Tests (Multiple)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...[
                      'Complete Blood Count (CBC) - ₹500',
                      'Lipid Profile - ₹600',
                      'Liver Function Test - ₹700',
                      'Kidney Function Test - ₹700',
                      'Thyroid Profile - ₹800',
                      'Diabetes Test - ₹400',
                    ].map((test) {
                      final isSelected = _selectedLabTests.contains(test);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedLabTests.add(test);
                            } else {
                              _selectedLabTests.remove(test);
                            }
                          });
                        },
                        title: Text(test, style: const TextStyle(fontSize: 14)),
                        activeColor: color,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Price Summary for Pathology
              if (_selectedLabTests.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.5), width: 2),
                  ),
                  child: Column(
                    children: [
                      ..._selectedLabTests.map((test) {
                        final priceMatch = RegExp(r'₹(\d+)').firstMatch(test);
                        final price =
                            priceMatch != null ? priceMatch.group(1) : '500';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  test.split(' - ')[0],
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Text(
                                '₹$price',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Home Collection:',
                              style: TextStyle(fontSize: 13)),
                          Text('Included',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green)),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Cost:',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(
                            '₹${_selectedLabTests.fold<int>(0, (sum, test) {
                              final priceMatch =
                                  RegExp(r'₹(\d+)').firstMatch(test);
                              return sum +
                                  (priceMatch != null
                                      ? int.parse(priceMatch.group(1)!)
                                      : 500);
                            })}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],

            // Info Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDoctor
                          ? 'A doctor will connect with you via video call within 5 minutes'
                          : isAmbulance
                              ? 'An ambulance will be dispatched to your location immediately'
                              : isNurse
                                  ? 'A qualified nurse will be assigned and will arrive within 1-2 hours'
                                  : isBloodBank
                                      ? 'Blood banks will be notified and will respond to your request'
                                      : 'A technician will visit your location for sample collection',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Request Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: (_isBooking ||
                        _isGettingLocation ||
                        _currentPosition == null)
                    ? null
                    : _bookInstantService,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isBooking
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        isDoctor
                            ? 'Request Doctor Now'
                            : isAmbulance
                                ? 'Request Ambulance Now'
                                : isNurse
                                    ? 'Book Nurse Now'
                                    : isBloodBank
                                        ? 'Request Blood Now'
                                        : 'Book Lab Test Now',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Retry Location Button
            if (_currentPosition == null && !_isGettingLocation)
              TextButton.icon(
                onPressed: _getCurrentLocation,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry Location Detection'),
              ),
              
            const SizedBox(height: 100), // Added to prevent bottom nav bar overlap
          ],
        ),
      ),
    );
  }
}
