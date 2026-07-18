import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:intl/intl.dart';
import 'edit_profile_screen.dart';

class PersonalDetailsViewScreen extends StatelessWidget {
  const PersonalDetailsViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return const Scaffold(
        body: SafeArea(top: false, bottom: true, child: Center(child: CircularProgressIndicator())),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
          'Personal Details',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.black87),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EditProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Container(
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
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: user.fullName,
              ),
              _buildDivider(),
              _buildDetailRow(
                icon: Icons.mail_outline,
                label: 'Email',
                value: user.email,
              ),
              _buildDivider(),
              _buildDetailRow(
                icon: Icons.phone_android_outlined,
                label: 'Mobile Number',
                value: user.phone,
              ),
              _buildDivider(),
              _buildDetailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date of Birth',
                value: user.dateOfBirth != null
                    ? DateFormat('dd MMM yyyy').format(user.dateOfBirth!)
                    : 'Not Specified',
              ),
              _buildDivider(),
              _buildDetailRow(
                icon: Icons.person_outline,
                label: 'Gender',
                value: user.gender ?? 'Not Specified',
              ),
              _buildDivider(),
              _buildDetailRow(
                icon: Icons.water_drop_outlined,
                label: 'Blood Group',
                value: user.bloodGroup ?? 'Not Specified',
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.black87, size: 24),
          const SizedBox(width: 16),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F0F0),
    );
  }
}
