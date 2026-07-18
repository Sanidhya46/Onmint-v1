import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import 'doctor_detail_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final _apiClient = OnMintApiClient();
  List<User> _doctors = [];
  bool _isLoading = true;
  String? _selectedSpecialization;

  final List<String> _specializations = [
    'All',
    'Cardiologist',
    'Dermatologist',
    'Pediatrician',
    'Orthopedic',
    'Neurologist',
    'Gynecologist',
    'Psychiatrist',
    'General Physician',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);

    try {
      await _apiClient.initialize();
      final result = await _apiClient.patient.searchDoctors(
        specialization:
            _selectedSpecialization == 'All' ? null : _selectedSpecialization,
      );

      setState(() {
        _doctors =
            (result['data'] as List?)?.map((e) => User.fromJson(e)).toList() ??
                [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('Failed to load doctors');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Find Doctors'),
        backgroundColor: AppColors.doctor,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          // Specialization Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _specializations.length,
              itemBuilder: (context, index) {
                final spec = _specializations[index];
                final isSelected = _selectedSpecialization == spec ||
                    (_selectedSpecialization == null && spec == 'All');

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(spec),
                    onSelected: (selected) {
                      setState(() {
                        _selectedSpecialization = spec == 'All' ? null : spec;
                      });
                      _loadDoctors();
                    },
                    selectedColor: AppColors.doctor.withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? AppColors.doctor
                          : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Doctors List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadDoctors,
              child: _isLoading
                  ? const LoadingWidget(message: 'Loading doctors...')
                  : _doctors.isEmpty
                      ? const EmptyStateWidget(
                          icon: Icons.medical_services,
                          title: 'No Doctors Found',
                          message: 'Try changing the specialization filter',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _doctors.length,
                          itemBuilder: (context, index) {
                            final doctor = _doctors[index];
                            return _buildDoctorCard(doctor);
                          },
                        ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildDoctorCard(User doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorDetailScreen(doctor: doctor),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: AppColors.doctor.withOpacity(0.1),
                    child: Text(
                      doctor.firstName?[0].toUpperCase() ?? 'D',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.doctor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${doctor.fullName}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (doctor.specialization != null)
                          Text(
                            doctor.specialization!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (doctor.experience != null) ...[
                              const Icon(Icons.work,
                                  size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 4),
                              Text(
                                '${doctor.experience} yrs',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 12),
                            ],
                            if (doctor.rating != null) ...[
                              const Icon(Icons.star,
                                  size: 14, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                doctor.rating!.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (doctor.consultationFee != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '₹${doctor.consultationFee!.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.doctor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: AppColors.textSecondary),
                ],
              ),
            ),
            // Distance Badge (NEW)
            if (doctor.distance != null)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.doctor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        '${doctor.distance!.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
