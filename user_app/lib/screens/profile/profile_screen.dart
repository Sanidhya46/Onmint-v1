import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import '../../config/app_colors.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';
import 'addresses_screen.dart';
import 'help_support_screen.dart';
import 'personal_details_view_screen.dart';
import 'address_view_screen.dart';
import 'not_found_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingOrders = true;
  int _totalOrders = 0;

  @override
  void initState() {
    super.initState();
    _fetchTotalOrders();
  }

  Future<void> _fetchTotalOrders() async {
    try {
      final client = OnMintApiClient();
      client.initialize(); // Uses existing token
      // Fetch bookings count (limit 1 just to get total count if paginated, or limit 100 to count)
      final response = await client.patient.getUserBookings(limit: 1);

      if (mounted) {
        setState(() {
          _totalOrders = response['total'] ?? 0;
          _isLoadingOrders = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOrders = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    String memberSince = 'Unknown';
    if (user.createdAt != null) {
      memberSince = DateFormat('MMM yyyy').format(user.createdAt!);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Profile Header Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.blue[100],
                              child: user.profilePictureUrl != null &&
                                      user.profilePictureUrl!.isNotEmpty
                                  ? ClipOval(
                                      child: Image.network(
                                        user.profilePictureUrl!,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Icon(Icons.person,
                                                    size: 40,
                                                    color: Colors.blue[300]),
                                      ),
                                    )
                                  : Icon(Icons.person,
                                      size: 40, color: Colors.blue[300]),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 14, color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // User Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    user.fullName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right,
                                      color: Colors.grey),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified,
                                        size: 12, color: Colors.blue[700]),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Verified',
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.mail_outline,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.phone_outlined,
                                      size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 6),
                                  Text(
                                    user.phone,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    const SizedBox(height: 10),
                    // Stats
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F8FF), // Ice blue
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatItem(
                            icon: Icons.water_drop_outlined,
                            iconColor: Colors.red[400]!,
                            label: 'Blood Group',
                            value: user.bloodGroup?.isNotEmpty == true
                                ? user.bloodGroup!
                                : 'N/A',
                          ),
                          Container(
                              width: 1,
                              height: 24,
                              color: const Color(0xFFD6E4F0)),
                          _buildStatItem(
                            icon: Icons.calendar_today_outlined,
                            iconColor: Colors.blue[400]!,
                            label: 'Member Since',
                            value: memberSince,
                          ),
                          Container(
                              width: 1,
                              height: 24,
                              color: const Color(0xFFD6E4F0)),
                          _buildStatItem(
                            icon: Icons.receipt_long_outlined,
                            iconColor: Colors.green[400]!,
                            label: 'Total Orders',
                            value: _isLoadingOrders ? '...' : '$_totalOrders',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // My Account Section
              const Padding(
                padding: EdgeInsets.only(left: 6.0),
                child: Text(
                  'My Account',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.person_outline,
                      title: 'Personal Details',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const PersonalDetailsViewScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.favorite_border,
                      title: 'Health Records',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotFoundScreen(title: 'Health Records')),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.location_on_outlined,
                      title: 'Addresses',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const AddressViewScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.credit_card_outlined,
                      title: 'Payment Methods',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotFoundScreen(title: 'Payment Methods')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // More Section
              const Padding(
                padding: EdgeInsets.only(left: 6.0),
                child: Text(
                  'More',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildListTile(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotFoundScreen(title: 'Notifications')),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.lock_outline,
                      title: 'Change Password',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ChangePasswordScreen()),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotFoundScreen(title: 'Privacy Policy')),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.help_outline,
                      title: 'Help & Support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen()),
                        );
                      },
                    _buildDivider(),
                    _buildListTile(
                      icon: Icons.logout,
                      title: 'Logout',
                      iconColor: Colors.red,
                      titleColor: Colors.red,
                      hideArrow: true,
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await authProvider.logout();
                        if (mounted) {
                          navigator.pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool hideArrow = false,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.black87, size: 18),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: hideArrow
          ? null
          : const Icon(Icons.chevron_right, color: Colors.grey, size: 16),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      visualDensity: const VisualDensity(vertical: -2),
      dense: true,
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF5F5F5),
      indent: 16,
      endIndent: 16,
    );
  }
}
