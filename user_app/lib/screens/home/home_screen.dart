import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'dashboard_screen_simple.dart';
import '../booking/blood_request_screen.dart';
import '../profile/profile_screen.dart';
import '../bookings/bookings_screen.dart';
import '../booking/active_service_tracking_screen.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../utils/app_colors.dart'; 
import '../medicines/widgets/cart_floating_bar.dart';
import '../medicines/prescription_camera_screen.dart';
import '../bookings/booking_details_screen.dart';
import '../booking/order_detail_file.dart';
import '../booking/user_unified_tracking_screen.dart';
import '../bookings/pharmacist_order_tracking_screen.dart';
import '../booking/order_request_screen.dart';
import '../booking/user_active_consultation_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;
  const HomeScreen({super.key, this.initialIndex = 0});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const BloodRequestScreen(),
    const BookingsScreen(),
    const ProfileScreen(),
  ];

  late AnimationController _rotationController;

  final PatientService _patientService = PatientService();
  bool _hasActiveBooking = false;
  Map<String, dynamic>? _activeBookingDetails;
  String _activeServiceType = '';
  int _activeBookingCount = 0;
  int _inProgressCount = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _fetchActiveBooking();
  }

  Future<void> _fetchActiveBooking() async {
    try {
      final bookingsData = await _patientService.getBookings(page: 1, limit: 10);
      
      int activeCount = 0;
      int inProgressCount = 0;
      Map<String, dynamic>? mostRecentRequested;
      Map<String, dynamic>? mostRecentInProgress;

      for (var b in bookingsData) {
        final status = b['status']?.toString().toLowerCase() ?? '';
        
        if (status != 'completed' && status != 'cancelled' && status != 'rejected' && status != 'declined') {
          activeCount++;
        }
        
        final type = b['serviceType']?.toString().toLowerCase() ?? '';
        if (type == 'pharmacist' || type == 'medicine') {
          // Allowed
        }

        
        if (['requested', 'pending', 'waiting for pharmacist'].contains(status)) {
          if (mostRecentRequested == null) mostRecentRequested = b;
        } else if (['accepted', 'confirmed', 'in_progress', 'processing', 'on_the_way'].contains(status)) {
          inProgressCount++;
          if (mostRecentInProgress == null) mostRecentInProgress = b;
        }
      }

      final targetBooking = mostRecentInProgress ?? mostRecentRequested;

      if (mounted) {
        setState(() {
          _activeBookingCount = activeCount;
          _inProgressCount = inProgressCount;
          if (targetBooking != null && activeCount > 0) {
            _hasActiveBooking = true;
            _activeBookingDetails = targetBooking;
            _activeServiceType = targetBooking['serviceType']?.toString().toLowerCase() ?? '';
          } else {
            _hasActiveBooking = false;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching active bookings: $e");
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Color get _activeThemeColor {
    switch (_activeServiceType) {
      case 'ambulance':
        return Colors.red;
      case 'doctor':
      case 'consultation':
        return Colors.blue;
      case 'nurse':
        return Colors.blue;
      case 'lab_test':
      case 'pathology':
        return Colors.teal;
      case 'blood bank':
        return Colors.red;
      case 'pharmacist':
      case 'medicine':
      case 'prescription':
        return Colors.green;
      default:
        return const Color(0xFF0D47A1);
    }
  }

  Widget get _activeImage {
    switch (_activeServiceType) {
      case 'ambulance':
        return Image.asset('assets/images/ambulance.png', width: 36, height: 36, errorBuilder: (_,__,___) => const Icon(Icons.local_shipping, color: Colors.red));
      case 'doctor':
      case 'consultation':
        return Image.asset('assets/images/doctor_icon.png', width: 36, height: 36, errorBuilder: (_,__,___) => const Icon(Icons.person, color: Colors.blue));
      case 'nurse':
        return Image.asset('assets/images/nurse.png', width: 36, height: 36, errorBuilder: (_,__,___) => const Icon(Icons.local_hospital, color: Colors.blue));
      case 'lab_test':
      case 'pathology':
        return Image.asset('assets/images/lab_test121.png', width: 36, height: 36, errorBuilder: (_,__,___) => const Icon(Icons.science, color: Colors.teal));
      case 'blood bank':
      case 'bloodbank':
        return Image.asset('assets/images/bloodbank/bloodbank.png', width: 36, height: 36, errorBuilder: (_,__,___) => const Icon(Icons.bloodtype, color: Colors.red, size: 30));
      case 'pharmacist':
      case 'medicine':
      case 'prescription':
        return const Icon(Icons.local_pharmacy, color: Colors.green, size: 30);
      default:
        return const Icon(Icons.medical_services, color: Colors.blue, size: 30);
    }
  }

  void _openTrackingScreen() {
    if (_inProgressCount > 1 || (_inProgressCount == 0 && _activeBookingCount > 1)) {
      setState(() => _selectedIndex = 2);
      return;
    }

    if (_activeBookingDetails == null) return;
    final status = _activeBookingDetails!['status']?.toString().toLowerCase() ?? '';
    final bookingId = _activeBookingDetails!['_id'] ?? _activeBookingDetails!['id'] ?? '';
    
    if (['requested', 'pending', 'waiting for pharmacist'].contains(status)) {
      if (_activeServiceType == 'pharmacist' || _activeServiceType == 'medicine' || _activeServiceType == 'prescription') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacistOrderTrackingScreen(
              bookingId: bookingId,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailFile(
              bookingId: bookingId,
              bookingData: _activeBookingDetails!,
            ),
          ),
        );
      }
    } else {
      if ((_activeServiceType == 'doctor' || _activeServiceType == 'consultation') && status == 'in_progress') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserActiveConsultationScreen(
              bookingId: bookingId,
            ),
          ),
        );
      } else if (_activeServiceType == 'bloodbank' || _activeServiceType == 'blood bank') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserUnifiedTrackingScreen(
              bookingId: bookingId,
              serviceType: _activeServiceType,
            ),
          ),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderDetailFile(
              bookingId: bookingId,
              bookingData: _activeBookingDetails!,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return false;
        }
        return false; // Prevent popping back to splash screen
      },
      child: Stack(
        children: [
          Scaffold(
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: [
                _screens[_selectedIndex],
                if (_hasActiveBooking && _selectedIndex == 0 && MediaQuery.of(context).viewInsets.bottom == 0)
                  Positioned(
                    right: 20,
                    bottom: 20, // Floating above the bottom nav bar
                    child: GestureDetector(
                      onTap: _openTrackingScreen,
                      child: AnimatedBuilder(
                        animation: _rotationController,
                        builder: (context, child) {
                          return Container(
                            width: 65,
                            height: 65,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Rotating Border
                                Transform.rotate(
                                  angle: _rotationController.value *
                                      2 *
                                      3.141592653589793,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.transparent,
                                        width: 3,
                                      ),
                                      gradient: SweepGradient(
                                        colors: [
                                          _activeThemeColor.withOpacity(0.1),
                                          _activeThemeColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Inner white circle to hide the middle of gradient
                                Container(
                                  width: 59,
                                  height: 59,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                                // Icon
                                _activeImage,
                                // Green dot if in progress
                                if (_activeBookingDetails?['status']?.toString().toLowerCase() == 'in_progress')
                                  Positioned(
                                    top: 2,
                                    right: 2,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  
                // Sticky Bottom Cart Bar
                const Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: CartFloatingBar(),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4), // Reduced padding
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.home_rounded,
                          label: 'Home',
                          index: 0,
                          isSelected: _selectedIndex == 0,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.bloodtype_rounded,
                          label: 'Blood',
                          index: 1,
                          isSelected: _selectedIndex == 1,
                        ),
                      ),
                      const SizedBox(width: 56), // Exact space for FAB in center
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.calendar_month_rounded,
                          label: 'Bookings',
                          index: 2,
                          isSelected: _selectedIndex == 2,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.person_rounded,
                          label: 'Profile',
                          index: 3,
                          isSelected: _selectedIndex == 3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (MediaQuery.of(context).viewInsets.bottom == 0)
            Positioned(
              bottom: 25 + MediaQuery.of(context).padding.bottom, // Adjusted to match the centerDocked position and account for system nav bar
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    _showUploadBottomSheet(context);
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      'assets/images/circular_camera_icon.png',
                      width: 56,
                      height: 56,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
    bool isEmergency = false,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
            horizontal: 4, vertical: 2), // Reduced padding
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF0E2038)
                  : isEmergency
                      ? const Color(0xFFFF6B6B)
                      : Colors.grey[600],
              size: 22, // Reduced from 26
            ),
            const SizedBox(height: 2), // Reduced from 4
            Text(
              label,
              style: TextStyle(
                fontSize: 10, // Reduced from 11
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xFF0E2038)
                    : isEmergency
                        ? const Color(0xFFFF6B6B)
                        : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUploadBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              const Text(
                'Upload prescription',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0E2038)),
              ),
              const SizedBox(height: 2),
              const Text(
                "Upload a clear image of your prescription and we'll take it from there.",
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              _buildUploadOption(
                icon: Icons.camera_alt_outlined,
                title: 'Take a photo',
                subtitle: 'Use your camera to capture your prescription',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrescriptionCameraScreen(source: 'camera'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildUploadOption(
                icon: Icons.photo_library_outlined,
                title: 'Choose from gallery',
                subtitle: 'Select an existing image from your device',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrescriptionCameraScreen(source: 'gallery'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              _buildUploadOption(
                icon: Icons.description_outlined,
                title: 'Your prescriptions',
                subtitle: 'View and upload from your saved prescriptions',
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to saved prescriptions
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }



  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.blue[800], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
