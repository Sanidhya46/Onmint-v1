import 'package:flutter/material.dart';
import '../../config/app_colors.dart';
import '../home/dashboards/doctor_dashboard.dart';
import 'bookings_screen.dart';
import 'earnings_screen.dart';
import '../profile/profile_screen.dart';

class DoctorMainScreen extends StatefulWidget {
  const DoctorMainScreen({super.key});

  @override
  State<DoctorMainScreen> createState() => _DoctorMainScreenState();
}

class _DoctorMainScreenState extends State<DoctorMainScreen> {
  int _selectedIndex = 0;
  final List<int> _refreshCounters = [0, 0, 0, 0];

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DoctorDashboard(key: ValueKey(_refreshCounters[0])),
      BookingsScreen(key: ValueKey(_refreshCounters[1])),
      EarningsScreen(key: ValueKey(_refreshCounters[2])),
      ProfileScreen(key: ValueKey(_refreshCounters[3])),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
            _refreshCounters[index]++;
          });
        },
        selectedItemColor: const Color(0xFF1565C0), // Blue matching screenshot
        unselectedItemColor: Colors.grey,
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
}
