import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import '../booking/nurse_booking_screen.dart';

class NurseDetailScreen extends StatefulWidget {
  final String nurseId;

  const NurseDetailScreen({
    super.key,
    required this.nurseId,
  });

  @override
  State<NurseDetailScreen> createState() => _NurseDetailScreenState();
}

class _NurseDetailScreenState extends State<NurseDetailScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _nurse;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNurseDetails();
  }

  Future<void> _loadNurseDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.patient.getNurseDetails(widget.nurseId);

      setState(() {
        _nurse = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nurse Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _loadNurseDetails,
                )
              : _nurse == null
                  ? const EmptyStateWidget(
                      title: 'Not Found',
                      message: 'Nurse not found',
                      icon: Icons.local_hospital,
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          _buildInfoSection(),
                          _buildServicesSection(),
                          _buildAvailabilitySection(),
                          _buildReviewsSection(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    )),
      bottomNavigationBar: _nurse != null ? _buildBookButton() : null,
    );
  }

  Widget _buildHeader() {
    final rating = _nurse!['rating']?.toDouble() ?? 0.0;
    final reviewCount = _nurse!['reviewCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: _nurse!['profileImage'] != null
                ? ClipOval(
                    child: Image.network(
                      _nurse!['profileImage'],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.local_hospital,
                          size: 50,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  )
                : const Icon(
                    Icons.local_hospital,
                    size: 50,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_nurse!['firstName']} ${_nurse!['lastName']}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                ' ($reviewCount reviews)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    final experience = _nurse!['experience'] ?? 0;
    final qualification = _nurse!['qualification'] ?? 'Not specified';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow(
                    Icons.work_outline,
                    'Experience',
                    '$experience years',
                  ),
                  const Divider(),
                  _buildInfoRow(
                    Icons.school_outlined,
                    'Qualification',
                    qualification,
                  ),
                  if (_nurse!['phone'] != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      Icons.phone_outlined,
                      'Phone',
                      _nurse!['phone'],
                    ),
                  ],
                  if (_nurse!['email'] != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      Icons.email_outlined,
                      'Email',
                      _nurse!['email'],
                    ),
                  ],
                  if (_nurse!['address'] != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      'Location',
                      '${_nurse!['address']['city']}, ${_nurse!['address']['state']}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = _nurse!['servicesOffered'] as List? ??
        _nurse!['services'] as List? ??
        [];
    final specializations = _nurse!['specializations'] as List? ?? [];
    final tasks = _nurse!['tasks'] as List? ?? [];

    // Combine all service-related information
    final allServices = <Map<String, dynamic>>[];

    // Add services
    for (var service in services) {
      if (service is Map<String, dynamic>) {
        allServices.add(service);
      } else {
        allServices.add({'name': service.toString(), 'type': 'service'});
      }
    }

    // Add specializations
    for (var spec in specializations) {
      if (spec is Map<String, dynamic>) {
        allServices.add({...spec, 'type': 'specialization'});
      } else {
        allServices.add({'name': spec.toString(), 'type': 'specialization'});
      }
    }

    // Add tasks
    for (var task in tasks) {
      if (task is Map<String, dynamic>) {
        allServices.add({...task, 'type': 'task'});
      } else {
        allServices.add({'name': task.toString(), 'type': 'task'});
      }
    }

    if (allServices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services & Hourly Rates',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: allServices.map<Widget>((service) {
                  final type = service['type'] ?? 'service';
                  IconData icon;
                  Color color;

                  switch (type) {
                    case 'specialization':
                      icon = Icons.star;
                      color = Colors.orange;
                      break;
                    case 'task':
                      icon = Icons.task_alt;
                      color = Colors.blue;
                      break;
                    default:
                      icon = Icons.medical_services;
                      color = AppColors.primary;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      service['name'] ?? service.toString(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (type != 'service')
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        type.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (service['price'] != null ||
                                  service['pricePerHour'] != null ||
                                  service['hourlyRate'] != null)
                                Text(
                                  '₹${service['price'] ?? service['pricePerHour'] ?? service['hourlyRate']}/hour',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (service['description'] != null)
                                Text(
                                  service['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Show general hourly rate if no service-specific rates
          if (_nurse!['hourlyRate'] != null &&
              allServices.every((s) =>
                  s['price'] == null &&
                  s['pricePerHour'] == null &&
                  s['hourlyRate'] == null))
            Card(
              color: AppColors.primary.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.attach_money,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Standard Hourly Rate',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₹${_nurse!['hourlyRate']}/hour',
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    final availability = _nurse!['availability'] as List? ?? [];

    if (availability.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Availability',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availability.map<Widget>((date) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _formatDate(DateTime.parse(date)),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    final reviews = _nurse!['reviews'] as List? ?? [];

    if (reviews.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reviews',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...reviews.take(5).map<Widget>((review) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(
                            review['patientName']?[0]?.toUpperCase() ?? 'P',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                review['patientName'] ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < (review['rating'] ?? 0)
                                        ? Icons.star
                                        : Icons.star_border,
                                    size: 16,
                                    color: Colors.amber,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (review['comment'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        review['comment'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBookButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: CustomButton(
        text: 'Book Nurse',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NurseBookingScreen(nurse: _nurse!),
            ),
          );
        },
      ),
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
    return '${date.day} ${months[date.month - 1]}';
  }
}
