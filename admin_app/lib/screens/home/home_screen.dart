import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_service/auth_service.dart';
import '../../config/app_colors.dart';
import 'dashboard_screen.dart';
import 'approvals_screen.dart';
import 'users_screen.dart';
import 'medicines_screen.dart';
import 'ambulances_screen.dart';
import 'bloodbanks_screen.dart';
import 'pathology_screen.dart';
import 'statistics_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final _apiClient = OnMintApiClient();
  int _pendingApprovalsCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchPendingApprovalsCount();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchPendingApprovalsCount());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPendingApprovalsCount() async {
    try {
      final approvals = await _apiClient.admin.getPendingApprovals();
      if (mounted) {
        setState(() {
          _pendingApprovalsCount = approvals.length;
        });
      }
    } catch (e) {
      // Ignore errors for background fetch
    }
  }

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ApprovalsScreen(),
    const UsersScreen(),
    const MedicinesScreen(),
    const AmbulancesScreen(),
    const BloodBanksScreen(),
    const PathologyScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OnMint Admin'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          // Notification Icon
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_outlined),
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
          
          // Profile Menu
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: user?.profilePictureUrl != null && 
                              user!.profilePictureUrl!.isNotEmpty
                  ? NetworkImage(user.profilePictureUrl!)
                  : null,
              child: user?.profilePictureUrl == null || user!.profilePictureUrl!.isEmpty
                  ? Text(
                      user?.firstName?.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.of(context).pushNamed('/profile');
              } else if (value == 'settings') {
                setState(() => _selectedIndex = 8);
              } else if (value == 'logout') {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.fullName ?? 'Admin',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Logout', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushNamed('/profile');
                    },
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      backgroundImage: user?.profilePictureUrl != null && 
                                      user!.profilePictureUrl!.isNotEmpty
                          ? NetworkImage(user.profilePictureUrl!)
                          : null,
                      child: user?.profilePictureUrl == null || user!.profilePictureUrl!.isEmpty
                          ? const Icon(
                              Icons.admin_panel_settings,
                              size: 35,
                              color: AppColors.primary,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Admin',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(
              icon: Icons.person_outline,
              title: 'Profile',
              index: -1,
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed('/profile');
              },
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.dashboard_outlined,
              title: 'Dashboard',
              index: 0,
            ),
            _buildDrawerItem(
              icon: Icons.approval_outlined,
              title: 'Approvals',
              index: 1,
              badge: _pendingApprovalsCount > 0 ? '$_pendingApprovalsCount' : null,
            ),
            _buildDrawerItem(
              icon: Icons.people_outline,
              title: 'Users',
              index: 2,
            ),
            _buildDrawerItem(
              icon: Icons.medication_outlined,
              title: 'Medicines',
              index: 3,
            ),
            _buildDrawerItem(
              icon: Icons.local_hospital_outlined,
              title: 'Ambulances',
              index: 4,
            ),
            _buildDrawerItem(
              icon: Icons.bloodtype_outlined,
              title: 'Blood Banks',
              index: 5,
            ),
            _buildDrawerItem(
              icon: Icons.science_outlined,
              title: 'Pathology Labs',
              index: 6,
            ),
            _buildDrawerItem(
              icon: Icons.bar_chart_outlined,
              title: 'Statistics',
              index: 7,
            ),
            const Divider(),
            _buildDrawerItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              index: 8,
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required int index,
    String? badge,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedIndex == index;
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey[700],
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: badge != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: onTap ?? () {
        setState(() => _selectedIndex = index);
        Navigator.pop(context);
      },
    );
  }
}
