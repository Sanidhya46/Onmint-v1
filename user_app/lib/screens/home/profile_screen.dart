import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/change_password_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfile(user),
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: user == null
          ? const Center(child: Text('No user data'))
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white,
                          child: Text(
                            user.firstName?.isNotEmpty == true
                                ? user.firstName![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          user.email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        Text(
                          user.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Personal Information
                  _buildSection(
                    title: 'Personal Information',
                    children: [
                      _buildInfoTile(
                        icon: Icons.person,
                        label: 'Full Name',
                        value: user.fullName,
                      ),
                      _buildInfoTile(
                        icon: Icons.email,
                        label: 'Email',
                        value: user.email,
                      ),
                      _buildInfoTile(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: user.phone,
                      ),
                      if (user.dateOfBirth != null)
                        _buildInfoTile(
                          icon: Icons.cake,
                          label: 'Date of Birth',
                          value: _formatDate(user.dateOfBirth!),
                        ),
                      if (user.gender != null)
                        _buildInfoTile(
                          icon: Icons.wc,
                          label: 'Gender',
                          value: user.gender!,
                        ),
                      if (user.bloodGroup != null)
                        _buildInfoTile(
                          icon: Icons.bloodtype,
                          label: 'Blood Group',
                          value: user.bloodGroup!,
                        ),
                    ],
                  ),

                  // Address Information
                  if (user.address != null)
                    _buildSection(
                      title: 'Address',
                      children: [
                        _buildInfoTile(
                          icon: Icons.location_on,
                          label: 'Address',
                          value: user.address!.fullAddress,
                        ),
                      ],
                    ),

                  // Emergency Contact
                  if (user.emergencyContact != null)
                    _buildSection(
                      title: 'Emergency Contact',
                      children: [
                        _buildInfoTile(
                          icon: Icons.person,
                          label: 'Name',
                          value: user.emergencyContact!['name'] ?? 'N/A',
                        ),
                        _buildInfoTile(
                          icon: Icons.phone,
                          label: 'Phone',
                          value: user.emergencyContact!['phone'] ?? 'N/A',
                        ),
                        _buildInfoTile(
                          icon: Icons.family_restroom,
                          label: 'Relationship',
                          value: user.emergencyContact!['relation'] ?? 'N/A',
                        ),
                      ],
                    ),

                  // Actions
                  _buildSection(
                    title: 'Settings',
                    children: [
                      _buildActionTile(
                        icon: Icons.lock,
                        label: 'Change Password',
                        onTap: () => _showChangePassword(),
                      ),
                      _buildActionTile(
                        icon: Icons.notifications,
                        label: 'Notifications',
                        onTap: () {
                          ToastUtils.showInfo('Coming soon');
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.help,
                        label: 'Help & Support',
                        onTap: () {
                          ToastUtils.showInfo('Coming soon');
                        },
                      ),
                      _buildActionTile(
                        icon: Icons.info,
                        label: 'About',
                        onTap: () => _showAbout(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  if (user != null)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _logout(authProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )),
    );
  }

  Widget _buildSection(
      {required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios,
          size: 16, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  String _formatDate(DateTime date) {
    final months = [
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
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  void _showEditProfile(user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EditProfileScreen(),
      ),
    );
  }

  void _showChangePassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ChangePasswordScreen(),
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About OnMint'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OnMint Healthcare Platform',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Version 1.0.0'),
            SizedBox(height: 16),
            Text(
              'Your trusted healthcare companion for booking doctors, nurses, ambulances, and more.',
            ),
          ],
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

  void _logout(AuthProvider authProvider) {
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
              Navigator.pop(context);
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
