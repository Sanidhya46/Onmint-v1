import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:api_client/api_client.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../doctors/doctor_categories_screen.dart';
import '../doctors/doctors_screen.dart';
import '../services/nurses_screen.dart';
import '../services/nurse_booking_screen.dart';
import '../services/ambulance_screen.dart';
import '../booking/ambulance_booking_screen.dart';
import '../booking/lab_test_booking_screen.dart';
import '../services/pathology_screen.dart';
import '../services/doctor_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import 'package:auth_service/auth_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PatientService _patientService = PatientService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _medicines = [];
  bool _isLoading = true;
  bool _isLocationLoading = false;
  String _currentCity = 'Mumbai';
  String _currentState = 'Maharashtra';

  // Healthcare service categories with images
  final List<Map<String, dynamic>> _serviceCategories = [
    {
      'id': 'doctor',
      'title': 'Doctor',
      'gradient': [const Color(0xFF667EEA), const Color(0xFF764BA2)],
      'imagePath': 'images/doctor_icon.png',
      'icon': Icons.local_hospital,
    },
    {
      'id': 'nurse',
      'title': 'Nurse',
      'gradient': [const Color(0xFF11998E), const Color(0xFF38EF7D)],
      'imagePath': 'images/nurse.png',
      'icon': Icons.healing,
    },
    {
      'id': 'pathology',
      'title': 'Lab Test',
      'gradient': [const Color(0xFF4A90E2), const Color(0xFF50C9FF)],
      'imagePath': 'images/lab_test.png',
      'icon': Icons.science,
    },
    {
      'id': 'ambulance',
      'title': 'Ambulance',
      'gradient': [const Color(0xFFFF9A9E), const Color(0xFFFECFEF)],
      'imagePath': 'images/ambulance.png',
      'icon': Icons.local_shipping,
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadData();
    
    // Fetch cart data to persist floating cart bar
    Future.microtask(() {
      if (mounted) {
        Provider.of<CartService>(context, listen: false).fetchBackendCart();
      }
    });

    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;

    setState(() => _isLocationLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentUser == null) {
        await authProvider.initialize();
      }
      if (authProvider.currentUser == null || authProvider.currentUser!.address == null) {
        await authProvider.refreshProfile();
      }
      final user = authProvider.currentUser;
      if (user != null && user.address != null && user.address!.city != null && user.address!.city!.isNotEmpty) {
        setState(() {
          _currentCity = user.address!.city!;
          _currentState = user.address!.state ?? 'India';
          _isLocationLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("Error fetching registered location: $e");
    }

    try {
      // For web, location services work differently
      // Try to get location without strict permission check
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy:
              LocationAccuracy.low, // Use low accuracy for faster response
          timeLimit: const Duration(seconds: 3), // Shorter timeout
        ).timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            throw TimeoutException('Location timeout');
          },
        );

        // Try OpenStreetMap Nominatim API first
        try {
          final response = await http.get(
            Uri.parse('https://nominatim.openstreetmap.org/reverse?'
                'format=json&lat=${position.latitude}&lon=${position.longitude}&'
                'addressdetails=1'),
            headers: {'User-Agent': 'OnMintHealthcare/1.0'},
          ).timeout(const Duration(seconds: 3));

          if (response.statusCode == 200 && mounted) {
            final data = json.decode(response.body);
            final address = data['address'];

            if (address != null) {
              setState(() {
                _currentCity = address['city'] ??
                    address['town'] ??
                    address['village'] ??
                    address['suburb'] ??
                    _getCityFromCoordinates(
                        position.latitude, position.longitude);
                _currentState = address['state'] ?? 'India';
                _isLocationLoading = false;
              });
              return;
            }
          }
        } catch (e) {
          print('Nominatim API error: $e');
        }

        // Fallback to coordinate-based city detection
        if (mounted) {
          setState(() {
            _currentCity =
                _getCityFromCoordinates(position.latitude, position.longitude);
            _currentState = 'India';
            _isLocationLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Location error: $e');
      }
    } catch (e) {
      print('Location permission error: $e');
    }

    // Fallback to default (always executed if location fails)
    if (mounted) {
      setState(() {
        _currentCity = 'Mumbai';
        _currentState = 'Maharashtra';
        _isLocationLoading = false;
      });
    }
  }

  String _getCityFromCoordinates(double lat, double lon) {
    // Major Indian cities with their approximate coordinate ranges
    final cities = [
      {'name': 'Mumbai', 'lat': 19.0760, 'lon': 72.8777, 'range': 0.5},
      {'name': 'Delhi', 'lat': 28.7041, 'lon': 77.1025, 'range': 0.5},
      {'name': 'Bangalore', 'lat': 12.9716, 'lon': 77.5946, 'range': 0.5},
      {'name': 'Hyderabad', 'lat': 17.3850, 'lon': 78.4867, 'range': 0.5},
      {'name': 'Chennai', 'lat': 13.0827, 'lon': 80.2707, 'range': 0.5},
      {'name': 'Kolkata', 'lat': 22.5726, 'lon': 88.3639, 'range': 0.5},
      {'name': 'Pune', 'lat': 18.5204, 'lon': 73.8567, 'range': 0.5},
      {'name': 'Ahmedabad', 'lat': 23.0225, 'lon': 72.5714, 'range': 0.5},
      {'name': 'Jaipur', 'lat': 26.9124, 'lon': 75.7873, 'range': 0.5},
      {'name': 'Surat', 'lat': 21.1702, 'lon': 72.8311, 'range': 0.5},
      {'name': 'Lucknow', 'lat': 26.8467, 'lon': 80.9462, 'range': 0.5},
      {'name': 'Kanpur', 'lat': 26.4499, 'lon': 80.3319, 'range': 0.5},
      {'name': 'Nagpur', 'lat': 21.1458, 'lon': 79.0882, 'range': 0.5},
      {'name': 'Indore', 'lat': 22.7196, 'lon': 75.8577, 'range': 0.5},
      {'name': 'Thane', 'lat': 19.2183, 'lon': 72.9781, 'range': 0.3},
      {'name': 'Bhopal', 'lat': 23.2599, 'lon': 77.4126, 'range': 0.5},
      {'name': 'Visakhapatnam', 'lat': 17.6868, 'lon': 83.2185, 'range': 0.5},
      {'name': 'Patna', 'lat': 25.5941, 'lon': 85.1376, 'range': 0.5},
      {'name': 'Vadodara', 'lat': 22.3072, 'lon': 73.1812, 'range': 0.5},
      {'name': 'Ghaziabad', 'lat': 28.6692, 'lon': 77.4538, 'range': 0.3},
      {'name': 'Ludhiana', 'lat': 30.9010, 'lon': 75.8573, 'range': 0.5},
      {'name': 'Agra', 'lat': 27.1767, 'lon': 78.0081, 'range': 0.5},
      {'name': 'Nashik', 'lat': 19.9975, 'lon': 73.7898, 'range': 0.5},
      {'name': 'Faridabad', 'lat': 28.4089, 'lon': 77.3178, 'range': 0.3},
      {'name': 'Meerut', 'lat': 28.9845, 'lon': 77.7064, 'range': 0.5},
      {'name': 'Rajkot', 'lat': 22.3039, 'lon': 70.8022, 'range': 0.5},
      {'name': 'Varanasi', 'lat': 25.3176, 'lon': 82.9739, 'range': 0.5},
      {'name': 'Srinagar', 'lat': 34.0837, 'lon': 74.7973, 'range': 0.5},
      {'name': 'Amritsar', 'lat': 31.6340, 'lon': 74.8723, 'range': 0.5},
      {'name': 'Allahabad', 'lat': 25.4358, 'lon': 81.8463, 'range': 0.5},
      {'name': 'Ranchi', 'lat': 23.3441, 'lon': 85.3096, 'range': 0.5},
      {'name': 'Howrah', 'lat': 22.5958, 'lon': 88.2636, 'range': 0.3},
      {'name': 'Coimbatore', 'lat': 11.0168, 'lon': 76.9558, 'range': 0.5},
      {'name': 'Jabalpur', 'lat': 23.1815, 'lon': 79.9864, 'range': 0.5},
      {'name': 'Gwalior', 'lat': 26.2183, 'lon': 78.1828, 'range': 0.5},
      {'name': 'Vijayawada', 'lat': 16.5062, 'lon': 80.6480, 'range': 0.5},
      {'name': 'Jodhpur', 'lat': 26.2389, 'lon': 73.0243, 'range': 0.5},
      {'name': 'Madurai', 'lat': 9.9252, 'lon': 78.1198, 'range': 0.5},
      {'name': 'Raipur', 'lat': 21.2514, 'lon': 81.6296, 'range': 0.5},
      {'name': 'Kota', 'lat': 25.2138, 'lon': 75.8648, 'range': 0.5},
    ];

    // Find closest city
    double minDistance = double.infinity;
    String closestCity = 'Mumbai';

    for (var city in cities) {
      final cityLat = city['lat'] as double;
      final cityLon = city['lon'] as double;
      final range = city['range'] as double;

      final distance = ((lat - cityLat).abs() + (lon - cityLon).abs());

      if (distance < range && distance < minDistance) {
        minDistance = distance;
        closestCity = city['name'] as String;
      }
    }

    return closestCity;
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Load medicines only
      final medicinesResponse =
          await _patientService.searchMedicines(limit: 20);
      final medicines = medicinesResponse['data'] ?? [];

      if (mounted) {
        setState(() {
          _medicines = List<Map<String, dynamic>>.from(medicines);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Pure white background
      resizeToAvoidBottomInset: false, // Prevents keyboard from pushing up content
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Location and Search (now scrollable)
                _buildScrollableHeader(),

                // 4 Service Cards with Images
                _buildQuickServiceCards(),

                const SizedBox(height: 20),

                // Appointment Section with Image
                _buildAppointmentSection(),

                const SizedBox(height: 24),

                // Advertisement Banner with Image
                _buildAdvertisementBanner(),

                const SizedBox(height: 16),

                // Popular Categories Section (16 categories)
                _buildPopularCategoriesSection(),

                const SizedBox(height: 20),

                // 1. Generic Medicines Section
                if (!_isLoading && _medicines.isNotEmpty) ...[
                  _buildMedicineSection('Genric medicines', _medicines),
                  const SizedBox(height: 24),
                ],

                // 2. Pet Care Section
                _buildPetCareSection(),
                const SizedBox(height: 24),

                // 3. Two medicine rows
                if (!_isLoading && _medicines.isNotEmpty) ...[
                  _buildMedicineSection('Top Selling Medicines', _medicines),
                  const SizedBox(height: 24),
                  _buildMedicineSection('Seasonal Health Needs', _medicines),
                  const SizedBox(height: 24),
                ],

                // 4. Advertisement Banner Again
                _buildAdvertisementBanner(),
                const SizedBox(height: 24),

                // 5. Two medicine rows again
                if (!_isLoading && _medicines.isNotEmpty) ...[
                  _buildMedicineSection('Everyday Essentials', _medicines),
                  const SizedBox(height: 24),
                  _buildMedicineSection('Healthcare Devices', _medicines),
                  const SizedBox(height: 24),
                ],

                // 6. Last minute app banner
                _buildLastMinuteBanner(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Location Bar - Top Left
          Container(
            height: 50,
            child: Row(
              children: [
                // Location icon with red pin
                Icon(
                  Icons.location_on,
                  color: const Color(0xFFE74C3C),
                  size: 32,
                ),
                const SizedBox(width: 8),
                // Location text
                Expanded(
                  child: GestureDetector(
                    onTap: _showLocationPicker,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLocationLoading)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF667EEA),
                            ),
                          )
                        else
                          Text(
                            _currentCity,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          _currentState,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Notification icon - top right
                GestureDetector(
                  onTap: () {
                    // Navigate to notifications
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 1),
                    ),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Large Search Bar - Centered
          Container(
            height: 42,
            margin: const EdgeInsets.only(top: 0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, child) {
                    if (value.text.isEmpty && !_searchFocusNode.hasFocus) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 48),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[500],
                            ),
                            children: [
                              const TextSpan(text: 'Search for '),
                              TextSpan(
                                text: "'Medicine'",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF757575),
                      size: 22,
                    ),
                    suffixIcon: IntrinsicHeight(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 20,
                            width: 1,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Voice Search'),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.mic, size: 48, color: Color(0xFF667EEA)),
                                      const SizedBox(height: 16),
                                      const Text('Listening... Please speak now.'),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Icon(
                              Icons.mic,
                              color: Colors.grey[700],
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    // Implement search
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickServiceCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _serviceCategories.map((category) {
          return Expanded(
            child: GestureDetector(
              onTap: () => _navigateToServiceScreen(category['id']),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
                    // Service icon with F5F5F5 background
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF5F5F5),
                        border:
                            Border.all(color: Colors.grey.shade300, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: category['id'] == 'doctor'
                                ? 4.0
                                : category['id'] == 'ambulance'
                                    ? 6.0
                                    : category['id'] == 'pathology'
                                        ? 0.0
                                        : category['id'] == 'nurse'
                                            ? 4.0
                                            : 0.0,
                            bottom: 0,
                            left: 0,
                            right: 0,
                          ),
                          child: Align(
                            alignment: (category['id'] == 'ambulance' ||
                                    category['id'] == 'pathology' ||
                                    category['id'] == 'nurse')
                                ? Alignment.bottomCenter
                                : Alignment.center,
                            child: Image.asset(
                              'assets/${category['imagePath']}',
                              width: category['id'] == 'ambulance'
                                  ? 62
                                  : category['id'] == 'pathology'
                                      ? 60
                                      : category['id'] == 'nurse'
                                          ? 66
                                          : 70,
                              height: category['id'] == 'ambulance'
                                  ? 62
                                  : category['id'] == 'pathology'
                                      ? 60
                                      : category['id'] == 'nurse'
                                          ? 66
                                          : 70,
                              fit: BoxFit
                                  .contain, // Changed from cover to contain to prevent chopped icons
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  category['icon'],
                                  color: (category['gradient'][0] as Color),
                                  size: 32,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Service name
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        category['title'],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    final name =
        'Dr. ${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}'.trim();
    final specialization =
        doctor['specialization']?.toString() ?? 'General Physician';
    final experience = doctor['experience']?.toString() ?? '0';
    final fee = doctor['consultationFee']?.toString() ?? '500';

    return GestureDetector(
      onTap: () {
        // Convert Map to User object for navigation
        try {
          final doctorUser = User.fromJson(doctor);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailScreen(doctor: doctorUser),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading doctor details: $e')),
          );
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF667EEA),
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : 'D',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  specialization,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$experience years exp',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                Text(
                  '₹$fee',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667EEA),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNurseCard(Map<String, dynamic> nurse) {
    final name =
        '${nurse['firstName'] ?? ''} ${nurse['lastName'] ?? ''}'.trim();
    final specialization =
        nurse['specialization']?.toString() ?? 'General Nursing';
    final experience = nurse['experience']?.toString() ?? '0';
    final fee = nurse['consultationFee']?.toString() ?? '300';

    return GestureDetector(
      onTap: () {
        // Navigate to nurse detail screen
        try {
          final nurseUser = User.fromJson(nurse);
          Navigator.pushNamed(
            context,
            '/nurse-detail',
            arguments: nurseUser,
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading nurse details: $e')),
          );
        }
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        child: Card(
          elevation: 2,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF11998E),
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1) : 'N',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  specialization,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$experience years exp',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const Spacer(),
                Text(
                  '₹$fee',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF11998E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToServiceScreen(String serviceId) {
    switch (serviceId) {
      case 'doctor':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const DoctorCategoriesScreen()),
        );
        break;
      case 'nurse':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NurseBookingScreen()),
        );
        break;
      case 'ambulance':
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const AmbulanceBookingScreen()),
        );
        break;
      case 'pathology':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LabTestBookingScreen()),
        );
        break;
    }
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4A90E2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: Color(0xFF4A90E2),
                  size: 20,
                ),
              ),
              title: const Text(
                'Use Current Location',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              subtitle: const Text(
                'Allow location access for better experience',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _getCurrentLocation();
              },
            ),
            const Divider(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Icon(Icons.location_city,
                      color: Color(0xFF4A90E2), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Or Select City & State',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  // Major Indian Cities
                  _buildCityTile('Mumbai', 'Maharashtra'),
                  _buildCityTile('Delhi', 'Delhi'),
                  _buildCityTile('Bangalore', 'Karnataka'),
                  _buildCityTile('Hyderabad', 'Telangana'),
                  _buildCityTile('Chennai', 'Tamil Nadu'),
                  _buildCityTile('Kolkata', 'West Bengal'),
                  _buildCityTile('Pune', 'Maharashtra'),
                  _buildCityTile('Ahmedabad', 'Gujarat'),
                  _buildCityTile('Jaipur', 'Rajasthan'),
                  _buildCityTile('Lucknow', 'Uttar Pradesh'),
                  _buildCityTile('Kanpur', 'Uttar Pradesh'),
                  _buildCityTile('Nagpur', 'Maharashtra'),
                  _buildCityTile('Indore', 'Madhya Pradesh'),
                  _buildCityTile('Thane', 'Maharashtra'),
                  _buildCityTile('Bhopal', 'Madhya Pradesh'),
                  _buildCityTile('Visakhapatnam', 'Andhra Pradesh'),
                  _buildCityTile('Patna', 'Bihar'),
                  _buildCityTile('Vadodara', 'Gujarat'),
                  _buildCityTile('Ghaziabad', 'Uttar Pradesh'),
                  _buildCityTile('Ludhiana', 'Punjab'),
                  _buildCityTile('Agra', 'Uttar Pradesh'),
                  _buildCityTile('Nashik', 'Maharashtra'),
                  _buildCityTile('Faridabad', 'Haryana'),
                  _buildCityTile('Meerut', 'Uttar Pradesh'),
                  _buildCityTile('Rajkot', 'Gujarat'),
                  _buildCityTile('Varanasi', 'Uttar Pradesh'),
                  _buildCityTile('Srinagar', 'Jammu and Kashmir'),
                  _buildCityTile('Aurangabad', 'Maharashtra'),
                  _buildCityTile('Dhanbad', 'Jharkhand'),
                  _buildCityTile('Amritsar', 'Punjab'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCityTile(String city, String state) {
    return ListTile(
      leading: const Icon(Icons.location_on_outlined,
          color: Color(0xFF4A90E2), size: 20),
      title: Text(
        city,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: Color(0xFF1F2937),
        ),
      ),
      subtitle: Text(
        state,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
        ),
      ),
      onTap: () {
        setState(() {
          _currentCity = city;
          _currentState = state;
        });
        Navigator.pop(context);
      },
    );
  }


  Widget _buildAppointmentSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: Image.asset(
        'assets/images/Appointment_image.png',
        fit: BoxFit.contain,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 70,
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF4A90E2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'अपॉइंटमेंट टोकन प्राप्त करें',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('QR स्कैनर'),
                              content: const Text(
                                  'QR स्कैन करने की कार्यक्षमता को यहाँ लागू किया जाएगा।'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('बंद करें'),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF4A90E2),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'QR स्कैन करें',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 50,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvertisementBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/Advertisement_banner.png',
          fit: BoxFit.cover,
          height: 140,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFD4E8D4),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'onmint',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1F2937),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Best-Ever Prices on Healthys Protein',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'THE PROTEIN YOU WANT IT!',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to product page
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1F2937),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 6),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            child: const Text(
                              'Check Now',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            'assets/protein_product.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.shopping_bag_outlined,
                                color: Colors.grey[400],
                                size: 40,
                              );
                            },
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPopularCategoriesSection() {
    // 16 categories with exact names matching your reference image
    final List<Map<String, dynamic>> popularCategories = [
      {
        'name': 'Cold, Cough &\nFever',
        'image': 'images/categories/cold_cough_and_fever.png',
        'color': Color(0xFFEDE7F6),
        'icon': Icons.sick_rounded,
        'iconColor': Color(0xFF673AB7),
      },
      {
        'name': 'Vitamins &\nSupplements',
        'image': 'images/categories/Vitamin_and_supplements.png',
        'color': Color(0xFFFFF3E0),
        'icon': Icons.psychology_rounded,
        'iconColor': Color(0xFFFF9800),
      },
      {
        'name': 'Baby Care',
        'image': 'images/categories/Baby_care.png',
        'color': Color(0xFFE3F2FD),
        'icon': Icons.child_care_rounded,
        'iconColor': Color(0xFF2196F3),
      },
      {
        'name': 'Oral Care',
        'image': 'images/categories/Oral_care.png',
        'color': Color(0xFFE8F5E8),
        'icon': Icons.clean_hands_rounded,
        'iconColor': Color(0xFF4CAF50),
      },
      {
        'name': 'Protein &\nSupplements',
        'image': 'images/categories/Protein_and_supplements.png',
        'color': Color(0xFFE1F5FE),
        'icon': Icons.fitness_center_rounded,
        'iconColor': Color(0xFF03A9F4),
      },
      {
        'name': 'Sexual\nWellness',
        'image': 'images/categories/Sexual_wellness.png',
        'color': Color(0xFFF3E5F5),
        'icon': Icons.favorite_rounded,
        'iconColor': Color(0xFF9C27B0),
      },
      {
        'name': 'Ayurvedic\nWellness',
        'image': 'images/categories/Ayurvedic_wellness.png',
        'color': Color(0xFFF9FBE7),
        'icon': Icons.local_florist_rounded,
        'iconColor': Color(0xFF689F38),
      },
      {
        'name': 'Food &\nNutrition',
        'image': 'images/categories/Food_and_nutrition.png',
        'color': Color(0xFFF1F8E9),
        'icon': Icons.restaurant_rounded,
        'iconColor': Color(0xFF8BC34A),
      },
      {
        'name': 'Hair Care',
        'image': 'images/categories/Hair_care.png',
        'color': Color(0xFFE8E4FF),
        'icon': Icons.content_cut_rounded,
        'iconColor': Color(0xFF9C27B0),
      },
      {
        'name': 'Skin Care',
        'image': 'images/categories/Skin_care.png',
        'color': Color(0xFFFFDADB),
        'icon': Icons.face_rounded,
        'iconColor': Color(0xFFE91E63),
      },
      {
        'name': 'Men Care',
        'image': 'images/categories/Men_care.png',
        'color': Color(0xFFE3F2FD),
        'icon': Icons.man_rounded,
        'iconColor': Color(0xFF2196F3),
      },
      {
        'name': 'Women\nCare',
        'image': 'images/categories/Women_care.png',
        'color': Color(0xFFFCE4EC),
        'icon': Icons.woman_rounded,
        'iconColor': Color(0xFFE91E63),
      },
      {
        'name': 'Pain\nRelief',
        'image': 'images/categories/Pain_relief.png',
        'color': Color(0xFFFFEBEE),
        'icon': Icons.healing_rounded,
        'iconColor': Color(0xFFF44336),
      },
      {
        'name': 'Supports &\nBraces',
        'image': 'images/categories/Supports_and_braces.png',
        'color': Color(0xFFE0F2F1),
        'icon': Icons.accessibility_new_rounded,
        'iconColor': Color(0xFF009688),
      },
      {
        'name': 'Gut Care',
        'image': 'images/categories/Gut_care.png',
        'color': Color(0xFFFFF8E1),
        'icon': Icons.monitor_heart_rounded,
        'iconColor': Color(0xFFFFC107),
      },
      {
        'name': 'Diabetes',
        'image': 'images/categories/Diabetes.png',
        'color': Color(0xFFE8F5E8),
        'icon': Icons.bloodtype_rounded,
        'iconColor': Color(0xFF4CAF50),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popular Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 0.70, // Better fit to prevent overflow
              crossAxisSpacing: 6, // Reduced spacing
              mainAxisSpacing: 8, // Reduced spacing
            ),
            itemCount: popularCategories.length,
            itemBuilder: (context, index) {
              final category = popularCategories[index];
              return GestureDetector(
                onTap: () {
                  print('Selected category: ${category['name']}');
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1), // Creamy background color
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Image Area
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(
                                0.0), // Maximized image size
                            child: Image.asset(
                              'assets/${category['image']}',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  category['icon'],
                                  color: category['iconColor'],
                                  size: 40,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      // Bottom Text Area
                      Container(
                        width: double.infinity,
                        height: 36, // Fixed height for consistent bottom area
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: category[
                              'color'], // Colorful background for names
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              category['icon'],
                              size: 12,
                              color: category['iconColor'],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  category['name'].length > 9
                                      ? category['name']
                                      : category['name'].replaceAll('\n', ' '),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    height: 1.2,
                                  ),
                                  textAlign: TextAlign.start,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineSection(
      String title, List<Map<String, dynamic>> medicines) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1F2937),
                ),
              ),
              Row(
                children: [
                  const Text(
                    'See All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4A90E2),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: const Color(0xFF4A90E2),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280, // Card height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: medicines.length.clamp(0, 5),
            itemBuilder: (context, index) {
              return _buildMedicineCardUI(medicines[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMedicineCardUI(Map<String, dynamic> medicine) {
    final name = medicine['name']?.toString() ?? 'Medicine Name';

    // Parse price properly regardless of whether it's String or num
    double getPrice(dynamic val, double fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? fallback;
      return fallback;
    }

    final price = getPrice(
        medicine['discountedPrice'], getPrice(medicine['price'], 267.0));
    final originalPrice = getPrice(medicine['price'], price + 108.0);
    final discountPercent = originalPrice > price
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 21;

    // Extract image URL from either imageUrl or images array, prioritizing signed URLs
    String? imageUrl = medicine['imageUrlSigned']?.toString();
    if (imageUrl == null || imageUrl.isEmpty) {
      if (medicine['imagesSigned'] != null &&
          medicine['imagesSigned'] is List &&
          medicine['imagesSigned'].isNotEmpty) {
        imageUrl = medicine['imagesSigned'][0]?.toString();
      }
    }
    
    // Fallback to unsigned if signed are not present
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = medicine['imageUrl']?.toString();
      if (imageUrl == null || imageUrl.isEmpty) {
        if (medicine['images'] != null &&
            medicine['images'] is List &&
            medicine['images'].isNotEmpty) {
          imageUrl = medicine['images'][0]?.toString();
        }
      }
    }

    if (imageUrl != null && imageUrl.startsWith('/images/')) {
      imageUrl = 'https://api.onmint.in$imageUrl';
    } else if (imageUrl != null && imageUrl.startsWith('/')) {
      imageUrl = 'https://api.onmint.in$imageUrl';
    }

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: (imageUrl != null && imageUrl.isNotEmpty)
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 4),
                            Text('No Image',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication,
                              size: 40, color: Colors.grey[300]),
                          const SizedBox(height: 4),
                          Text('No Image',
                              style: TextStyle(
                                  fontSize: 10, color: Colors.grey[400])),
                        ],
                      ),
              ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Text(
                    '1 Pack',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹$price',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '₹$originalPrice',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                            decoration: TextDecoration.lineThrough,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$discountPercent% off',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Consumer<CartService>(
                    builder: (context, cart, child) {
                      final medicineId = medicine['_id'] ?? medicine['id'];
                      final cartItem = cart.items[medicineId];
                      final quantity = cartItem?.quantity ?? 0;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 32,
                              child: OutlinedButton(
                                onPressed: () {
                                  print('Medicine ADD button clicked: $name (ID: $medicineId)');
                                  cart.addItem(
                                    medicineId,
                                    name,
                                    price,
                                    imageUrl,
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  side: const BorderSide(color: Color(0xFFE53935)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    color: Color(0xFFE53935),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (quantity > 0) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/cart'),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Icon(
                                    Icons.shopping_cart_outlined,
                                    color: Colors.grey[700],
                                    size: 24,
                                  ),
                                  Positioned(
                                    right: -4,
                                    top: -4,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        '$quantity',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetCareSection() {
    final List<Map<String, dynamic>> petCategories = [
      {
        'name': 'Pet Supplements',
        'color': const Color(0xFFE8F5E9), // Light green
        'image': 'assets/images/categories/Pet_care/Pet_supplements.png',
      },
      {
        'name': 'Prescription Diet',
        'color': const Color(0xFFE3F2FD), // Light blue
        'image': 'assets/images/categories/Pet_care/Prescrption_diet.png',
      },
      {
        'name': 'Dog Food',
        'color': const Color(0xFFFFF3E0), // Light orange
        'image': 'assets/images/categories/Pet_care/Dog_food.png',
      },
      {
        'name': 'Cat Food',
        'color': const Color(0xFFF3E5F5), // Light purple
        'image': 'assets/images/categories/Pet_care/Cat_food.png',
      },
      {
        'name': 'Pet Treats',
        'color': const Color(0xFFFFEBEE), // Light red/pink
        'image': 'assets/images/categories/Pet_care/Pet_treats.png',
      },
      {
        'name': 'Pet Grooming',
        'color': const Color(0xFFE0F2F1), // Light teal
        'image': 'assets/images/categories/Pet_care/Pet_grooming.png',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Pet care',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: petCategories.length,
            itemBuilder: (context, index) {
              final cat = petCategories[index];
              return Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cat['color'],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(
                            cat['image'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.pets, color: Colors.grey[400]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat['name'],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLastMinuteBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF6F8F6),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/images/last_image_home_page.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
