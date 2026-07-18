import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import '../../config/app_colors.dart';
import '../booking/booking_flow_screen.dart';

class DoctorDetailScreen extends StatelessWidget {
  final User doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Details'),
        backgroundColor: AppColors.doctor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.doctor, AppColors.doctor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Text(
                      doctor.firstName?[0].toUpperCase() ?? 'D',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.doctor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Dr. ${doctor.fullName}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (doctor.specialization != null)
                    Text(
                      doctor.specialization!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 16,
                    runSpacing: 4,
                    children: [
                      if (doctor.rating != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${doctor.rating!.toStringAsFixed(1)} (${doctor.totalRatings ?? 0} reviews)',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                      if (doctor.experience != null) ...[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.work, color: Colors.white70, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${doctor.experience} years',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Consultation Fee
            if (doctor.consultationFee != null)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.doctor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.doctor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Consultation Fee',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '₹${doctor.consultationFee!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.doctor,
                      ),
                    ),
                  ],
                ),
              ),

            // About
            if (doctor.about != null)
              _buildSection(
                title: 'About',
                child: Text(
                  doctor.about!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),

            // Qualifications
            if (doctor.qualifications != null &&
                doctor.qualifications!.isNotEmpty)
              _buildSection(
                title: 'Qualifications',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: doctor.qualifications!.map((qual) {
                    return Chip(
                      label: Text(qual),
                      backgroundColor: AppColors.doctor.withOpacity(0.1),
                      labelStyle: const TextStyle(color: AppColors.doctor),
                    );
                  }).toList(),
                ),
              ),

            // Languages
            if (doctor.languages != null && doctor.languages!.isNotEmpty)
              _buildSection(
                title: 'Languages',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: doctor.languages!.map((lang) {
                    return Chip(
                      label: Text(lang),
                      backgroundColor: Colors.grey[200],
                    );
                  }).toList(),
                ),
              ),

            // Address
            if (doctor.address != null)
              _buildSection(
                title: 'Clinic Address',
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.doctor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doctor.address!.fullAddress,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Contact
            _buildSection(
              title: 'Contact',
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.phone, color: AppColors.doctor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          doctor.phone,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.email, color: AppColors.doctor),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            doctor.email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 100), // Space for button
          ],
        ),
      )),
      bottomNavigationBar: SafeArea(
child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookingFlowScreen(
                  provider: doctor,
                  serviceType: 'doctor',
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.doctor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Book Appointment',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      )
),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
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
          child,
        ],
      ),
    );
  }
}
