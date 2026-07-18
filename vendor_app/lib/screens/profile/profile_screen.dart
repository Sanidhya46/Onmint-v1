import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import '../../config/app_config.dart';
import 'personal_info_screen.dart';
import 'professional_info_screen.dart';
import 'certificates_screen.dart';
import 'change_password_screen.dart';
import 'contact_support_screen.dart';
import 'privacy_policy_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'My Profile',
          style: TextStyle(
            color: Color(0xFF152238),
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.red),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            // Profile Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade50, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100, width: 1),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundImage: user?.profilePicture != null
                              ? NetworkImage(user!.profilePicture!)
                              : null,
                          backgroundColor: Colors.grey[300],
                          child: user?.profilePicture == null
                              ? const Icon(Icons.person, size: 46, color: Colors.grey)
                              : null,
                        ),
                        // Red circle badge for unapproved/uncertified vendors
                        if (user?.status != null && user!.status != 'approved')
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 16, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Vendor',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF152238),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user?.role.toLowerCase() == 'nurse'
                                ? (user?.specializations?.isNotEmpty == true
                                    ? user!.specializations!.first
                                    : 'B.Sc Nursing')
                                : user?.role.toLowerCase() == 'doctor'
                                    ? '${user?.qualifications?.join(", ") ?? "MBBS, MD"} - ${user?.specialization ?? "General Physician"}'
                                    : user?.role.toLowerCase() == 'ambulance'
                                        ? '${user?.vehicleType ?? "Basic Life Support"} Ambulance'
                                        : AppConfig.getRoleDisplayName(user?.role ?? ''),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (user?.licenseNumber != null)
                            Text(
                              'Reg. No. ${user!.licenseNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            )
                          else if (user?.role.toLowerCase() == 'ambulance' && user?.vehicleNumber != null)
                            Text(
                              'Vehicle: ${user!.vehicleNumber}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.workspace_premium, color: Colors.blue, size: 14),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Exp. ${user?.experience ?? 0} Years',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Menu Items
            _buildMenuItem(
              context,
              Icons.person_outline,
              'Personal Information',
              'Update your personal details',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalInfoScreen())),
            ),
            _buildMenuItem(
              context,
              Icons.work_outline,
              'Professional Information',
              'Update your professional details',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfessionalInfoScreen())),
            ),
            _buildMenuItem(
              context,
              Icons.verified_user_outlined,
              'Certificates',
              'Manage your professional documents',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CertificatesScreen())),
            ),
            _buildMenuItem(
              context,
              Icons.lock_outline,
              'Change Password',
              'Update your account password',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            _buildMenuItem(
              context,
              Icons.headset_mic_outlined,
              'Contact Support',
              'Get help from our support team',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactSupportScreen())),
            ),
            _buildMenuItem(
              context,
              Icons.privacy_tip_outlined,
              'Privacy Policy',
              'Read our privacy policy',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
            ),
            const SizedBox(height: 8),
          ],
        ),
      )),
      // Logout Button
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () async {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
              label: const Text(
                'Logout',
                style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ),
    ],
    ),
    );
  }

  Widget _buildMenuItem(BuildContext context, IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF152238),
            fontSize: 13,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
        onTap: onTap,
      ),
    );
  }
}
