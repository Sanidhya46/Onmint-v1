import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import '../../config/app_config.dart';

class EditProfileScreen extends StatelessWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final roleColor = AppColors.getRoleColor(user.role);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: roleColor.withOpacity(0.1),
                  child: Text(
                    user.firstName?[0].toUpperCase() ?? 'V',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: roleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppConfig.getRoleDisplayName(user.role),
                  style: TextStyle(
                    fontSize: 16,
                    color: roleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(user.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(user.status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Personal Information
          _buildSection(
            title: 'Personal Information',
            children: [
              _buildInfoTile(Icons.person, 'Name', user.fullName),
              _buildInfoTile(Icons.email, 'Email', user.email),
              _buildInfoTile(Icons.phone, 'Phone', user.phone),
            ],
          ),

          const SizedBox(height: 24),

          // Address
          if (user.address != null)
            _buildSection(
              title: 'Address',
              children: [
                _buildInfoTile(Icons.location_on, 'Address', user.address!.fullAddress),
              ],
            ),

          const SizedBox(height: 24),

          // Role-specific Information
          _buildRoleSpecificInfo(),

          const SizedBox(height: 24),

          // Actions
          _buildSection(
            title: 'Settings',
            children: [
              _buildActionTile(Icons.edit, 'Edit Profile', () {
                ToastUtils.showInfo('Edit profile coming soon');
              }),
              _buildActionTile(Icons.lock, 'Change Password', () {
                ToastUtils.showInfo('Change password coming soon');
              }),
              _buildActionTile(Icons.help, 'Help & Support', () {
                ToastUtils.showInfo('Help & support coming soon');
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: AppColors.getRoleColor(user.role)),
      title: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      subtitle: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildActionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.getRoleColor(user.role)),
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  Widget _buildRoleSpecificInfo() {
    switch (user.role.toLowerCase()) {
      case 'doctor':
        return _buildSection(
          title: 'Professional Details',
          children: [
            if (user.specialization != null)
              _buildInfoTile(Icons.medical_services, 'Specialization', user.specialization!),
            if (user.experience != null)
              _buildInfoTile(Icons.work, 'Experience', '${user.experience} years'),
            if (user.consultationFee != null)
              _buildInfoTile(Icons.attach_money, 'Consultation Fee', '₹${user.consultationFee!.toStringAsFixed(0)}'),
          ],
        );
      case 'nurse':
        return _buildSection(
          title: 'Professional Details',
          children: [
            if (user.experience != null)
              _buildInfoTile(Icons.work, 'Experience', '${user.experience} years'),
            if (user.licenseNumber != null)
              _buildInfoTile(Icons.badge, 'License Number', user.licenseNumber!),
          ],
        );
      case 'pharmacist':
        return _buildSection(
          title: 'Pharmacy Details',
          children: [
            if (user.pharmacyName != null)
              _buildInfoTile(Icons.store, 'Pharmacy Name', user.pharmacyName!),
            if (user.licenseNumber != null)
              _buildInfoTile(Icons.badge, 'License Number', user.licenseNumber!),
          ],
        );
      case 'ambulance':
        return _buildSection(
          title: 'Vehicle Details',
          children: [
            if (user.vehicleNumber != null)
              _buildInfoTile(Icons.directions_car, 'Vehicle Number', user.vehicleNumber!),
            if (user.vehicleType != null)
              _buildInfoTile(Icons.local_shipping, 'Vehicle Type', user.vehicleType!),
            if (user.driverName != null)
              _buildInfoTile(Icons.person, 'Driver Name', user.driverName!),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'active':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
      case 'blocked':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
