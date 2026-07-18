import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../booking/ambulance_booking_screen.dart';

class AmbulanceScreen extends StatefulWidget {
  const AmbulanceScreen({super.key});

  @override
  State<AmbulanceScreen> createState() => _AmbulanceScreenState();
}

class _AmbulanceScreenState extends State<AmbulanceScreen> {
  late final PatientService _patientService;

  List<Map<String, dynamic>> _ambulances = [];
  String _selectedType = '';
  bool _isLoading = true;
  Position? _currentPosition;
  String _currentAddress = 'Fetching location...';

  final List<Map<String, dynamic>> _ambulanceTypes = [
    {'id': '', 'name': 'All Types', 'icon': Icons.local_shipping},
    {
      'id': 'basic',
      'name': 'Basic Life Support',
      'icon': Icons.medical_services
    },
    {
      'id': 'advanced',
      'name': 'Advanced Life Support',
      'icon': Icons.emergency
    },
    {
      'id': 'patient_transport',
      'name': 'Patient Transport',
      'icon': Icons.accessible
    },
    {'id': 'cardiac', 'name': 'Cardiac Ambulance', 'icon': Icons.favorite},
    {'id': 'neonatal', 'name': 'Neonatal', 'icon': Icons.child_care},
    {'id': 'air', 'name': 'Air Ambulance', 'icon': Icons.flight},
    {'id': 'mortuary', 'name': 'Mortuary Van', 'icon': Icons.local_shipping},
  ];

  @override
  void initState() {
    super.initState();
    _patientService = PatientService();
    _getCurrentLocation();
    _loadAmbulances();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      final permission = await Permission.location.request();

      if (permission.isGranted) {
        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _currentAddress =
                '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
          });
        }

        // You can add reverse geocoding here to get actual address
        // For now, we'll use coordinates
      } else {
        if (mounted) {
          setState(() {
            _currentAddress = 'Location permission denied';
          });
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      if (mounted) {
        setState(() {
          _currentAddress = 'Unable to get location';
        });
      }
    }
  }

  Future<void> _loadAmbulances() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Use searchAmbulances API to get ambulance providers
      final response = await _patientService.searchAmbulances(
        limit: 50,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      // Backend returns ambulances directly in 'data' array
      final ambulances =
          (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (mounted) {
        setState(() {
          _ambulances = ambulances;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading ambulances: $e');
      if (mounted) {
        setState(() {
          _ambulances = [];
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Ambulance'),
        backgroundColor: const Color(0xFFFF9A9E),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          _buildEmergencySection(),
          _buildTypesSection(),
          Expanded(child: _buildAmbulancesList()),
        ],
      )),
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.emergency, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Ambulance',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Immediate assistance',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _callEmergency(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Call 108', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Ambulance Types',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _ambulanceTypes.length,
            itemBuilder: (context, index) {
              final type = _ambulanceTypes[index];
              final isSelected = _selectedType == type['id'];

              return GestureDetector(
                onTap: () => setState(() => _selectedType = type['id']),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF9A9E)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          type['icon'],
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type['name'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFFF9A9E)
                              : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildAmbulancesList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF9A9E)));
    }

    if (_ambulances.isEmpty) {
      return const Center(
        child: Text('No ambulances available', style: TextStyle(fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _ambulances.length,
      itemBuilder: (context, index) {
        final ambulance = _ambulances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9A9E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_shipping,
                        color: Color(0xFFFF9A9E),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ambulance['driverName'] ?? 'Ambulance Service',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            ambulance['vehicleType'] ?? 'Basic Life Support',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey[600]),
                          ),
                          Text(
                            'Vehicle: ${ambulance['vehicleNumber'] ?? 'N/A'}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Available',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (ambulance['equipmentAvailable'] != null) ...[
                  Text(
                    'Equipment Available:',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: (ambulance['equipmentAvailable'] as List)
                        .map((equipment) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          equipment.toString(),
                          style:
                              const TextStyle(fontSize: 10, color: Colors.blue),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Response Time',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          const Text(
                            '5-10 mins',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _bookAmbulance(ambulance),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF9A9E)),
                      child: const Text('Book Now',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _callEmergency() async {
    if (_currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting your location... Please wait.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      await _getCurrentLocation();
      if (_currentPosition == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Unable to get location. Please enable location services.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    try {
      // Use emergency API endpoint
      final response = await _patientService.triggerEmergency(
        location: {
          'type': 'Point',
          'coordinates': [
            _currentPosition!.longitude,
            _currentPosition!.latitude
          ],
        },
        address: _currentAddress,
        notes: 'Emergency call - 108. Immediate medical assistance required.',
        type: 'ambulance',
      );

      debugPrint('Emergency response: $response');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('🚑 Emergency ambulance requested! Help is on the way.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Fetch and show nearby ambulances
        _fetchAndShowNearbyAmbulances();
      }
    } catch (e) {
      debugPrint('Emergency call error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Emergency request failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _fetchAndShowNearbyAmbulances() async {
    if (_currentPosition == null) return;

    try {
      // Fetch ambulances within 50km radius using the search API
      final response = await _patientService.searchAmbulances(
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        maxDistance: 50, // 50km radius
      );

      debugPrint('Nearby ambulances response: $response');

      // Backend returns ambulances directly in 'data' array, not nested in 'data.ambulances'
      final ambulances =
          (response['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      if (mounted) {
        _showAmbulancesDialog(ambulances);
      }
    } catch (e) {
      debugPrint('Error fetching nearby ambulances: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not fetch nearby ambulances: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showAmbulancesDialog(List<Map<String, dynamic>> ambulances) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_shipping, color: Color(0xFFFF9A9E)),
            const SizedBox(width: 8),
            const Text('Available Ambulances'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ambulances.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No ambulances found within 50km radius',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Emergency services have been notified and will dispatch the nearest available ambulance.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: ambulances.length,
                  itemBuilder: (context, index) {
                    final ambulance = ambulances[index];
                    final distance =
                        ambulance['distance']?.toStringAsFixed(2) ?? 'N/A';
                    final isAssigned = ambulance['isAssigned'] == true;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: isAssigned ? Colors.green.withOpacity(0.1) : null,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isAssigned
                                        ? Colors.green.withOpacity(0.2)
                                        : const Color(0xFFFF9A9E)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.local_shipping,
                                    color: isAssigned
                                        ? Colors.green
                                        : const Color(0xFFFF9A9E),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ambulance['driverName'] ??
                                            'Ambulance Service',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Vehicle: ${ambulance['vehicleNumber'] ?? 'N/A'}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isAssigned)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'ASSIGNED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.location_on,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'Distance: $distance km',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                                const SizedBox(width: 16),
                                Icon(Icons.access_time,
                                    size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'ETA: ${_calculateETA(distance)} mins',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            if (ambulance['vehicleType'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${ambulance['vehicleType']}',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[500]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _calculateETA(String distance) {
    try {
      final distanceKm = double.parse(distance);
      // Assume average speed of 40 km/h in city
      final timeInHours = distanceKm / 40;
      final timeInMinutes = (timeInHours * 60).round();
      return timeInMinutes.toString();
    } catch (e) {
      return 'N/A';
    }
  }

  void _bookAmbulance(Map<String, dynamic> ambulance) {
    // Navigate to ambulance booking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AmbulanceBookingScreen(),
      ),
    );
  }
}
