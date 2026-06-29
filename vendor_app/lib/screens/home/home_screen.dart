import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import 'dashboards/doctor_dashboard.dart';
import 'dashboards/nurse_dashboard.dart';
import 'dashboards/pharmacist_dashboard.dart';
import 'dashboards/ambulance_dashboard.dart';
import 'dashboards/bloodbank_dashboard.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/profile_screen.dart';
import '../ambulance/ride_requests_screen.dart';
import '../doctor/bookings_screen.dart';
import '../doctor/appointments_screen.dart';
import '../doctor/doctor_main_screen.dart';
import '../pharmacist/order_management_screen.dart';
import '../nurse/bookings_screen.dart' as nurse_bookings;
import '../pathology/pathology_bookings_screen.dart';
import '../pathology/pathology_home_screen.dart';
import '../blood_bank/blood_bank_bookings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final List<int> _refreshCounters = [0, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('No user data')),
      );
    }

    final role = user.role.toLowerCase();
    final roleColor = AppColors.getRoleColor(role);

    if (role == 'doctor') {
      return const DoctorMainScreen();
    }

    // Get role-specific dashboard
    final dashboardWidget = _getDashboardForRole(role);

    final screens = [
      KeyedSubtree(key: ValueKey(_refreshCounters[0]), child: dashboardWidget),
      KeyedSubtree(key: ValueKey(_refreshCounters[1]), child: _getBookingsScreenForRole(role)),
      KeyedSubtree(key: ValueKey(_refreshCounters[2]), child: const Center(child: Text('Earnings', style: TextStyle(fontSize: 18)))),
      KeyedSubtree(key: ValueKey(_refreshCounters[3]), child: const ProfileScreen()),
    ];

    bool hideAppBar = _selectedIndex == 3 || 
        (_selectedIndex == 0 && (role == 'ambulance' || role == 'nurse' || role == 'pathology' || role == 'bloodbank' || role == 'pharmacist')) || 
        (_selectedIndex == 1 && (role == 'ambulance' || role == 'nurse' || role == 'pathology' || role == 'bloodbank' || role == 'pharmacist'));

    return Scaffold(
      appBar: hideAppBar ? null : AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppConfig.getRoleDisplayName(role),
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: roleColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: AppColors.error),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _refreshCounters[index]++;
          });
        },
        selectedItemColor: roleColor,
        unselectedItemColor: AppColors.textSecondary,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _getDashboardForRole(String role) {
    switch (role) {
      case 'doctor':
        return const DoctorDashboard();
      case 'nurse':
        return const NurseDashboard();
      case 'pharmacist':
        return const PharmacistDashboard();
      case 'ambulance':
        return const AmbulanceDashboard();
      case 'bloodbank':
        return const BloodBankDashboard();
      case 'pathology':
        return const PathologyHomeScreen();
      default:
        return const Center(child: Text('Unknown role'));
    }
  }

  Widget _getBookingsScreenForRole(String role) {
    switch (role) {
      case 'doctor':
        return const BookingsScreen();
      case 'ambulance':
        return const RideRequestsScreen();
      case 'pharmacist':
        return const OrderManagementScreen();
      case 'nurse':
        return const nurse_bookings.BookingsScreen();
      case 'pathology':
        return const PathologyBookingsScreen();
      case 'bloodbank':
        return const BloodBankBookingsScreen();
      default:
        return const Center(child: Text('Bookings screen not available'));
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
