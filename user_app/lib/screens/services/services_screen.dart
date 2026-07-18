import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import '../../utils/app_colors.dart';
import 'booking_screen.dart';

class ServicesScreen extends StatefulWidget {
  final String? initialServiceType;

  const ServicesScreen({super.key, this.initialServiceType});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  late final PatientService _patientService;

  String _selectedServiceType = 'doctor';
  String _selectedSpecialization = '';
  List<Map<String, dynamic>> _services = [];
  List<String> _specializations = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = false;

  final List<Map<String, dynamic>> _serviceTypes = [
    {'type': 'doctor', 'label': 'Doctors', 'icon': Icons.medical_services},
    {'type': 'nurse', 'label': 'Nurses', 'icon': Icons.health_and_safety},
    {
      'type': 'pharmacist',
      'label': 'Pharmacists',
      'icon': Icons.local_pharmacy
    },
    {'type': 'pathology', 'label': 'Pathology', 'icon': Icons.science},
    {'type': 'ambulance', 'label': 'Ambulance', 'icon': Icons.emergency},
    {'type': 'bloodbank', 'label': 'Blood Bank', 'icon': Icons.bloodtype},
  ];

  @override
  void initState() {
    super.initState();
    _patientService = PatientService();
    _selectedServiceType = widget.initialServiceType ?? 'doctor';
    _loadServices();
  }

  Future<void> _loadServices({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _services.clear();
      _specializations.clear();
      _selectedSpecialization = '';
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Use searchDoctors for doctors, for other services we'll use mock data for now
      List<Map<String, dynamic>> newServices = [];

      if (_selectedServiceType == 'doctor') {
        final response = await _patientService.searchDoctors(
          page: _currentPage,
          limit: 10,
        );
        newServices = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _extractSpecializations(newServices);
      } else {
        // For other service types, show empty state for now
        // TODO: Implement other service type APIs
        newServices = [];
      }

      if (mounted) {
        setState(() {
          if (refresh) {
            _services = newServices;
          } else {
            _services.addAll(newServices);
          }
          _hasMore = newServices.length >= 10;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading services: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _extractSpecializations(List<Map<String, dynamic>> doctors) {
    final specs = <String>{};
    for (final doctor in doctors) {
      final spec = doctor['specialization']?.toString();
      if (spec != null && spec.isNotEmpty) {
        specs.add(spec);
      }
    }
    setState(() {
      _specializations = specs.toList()..sort();
    });
  }

  List<Map<String, dynamic>> _getFilteredServices() {
    if (_selectedSpecialization.isEmpty) {
      return _services;
    }
    return _services
        .where((service) =>
            service['specialization']?.toString() == _selectedSpecialization)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Healthcare Services'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Type Selector
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(12),
                itemCount: _serviceTypes.length,
                itemBuilder: (context, index) {
                  final serviceType = _serviceTypes[index];
                  final isSelected =
                      _selectedServiceType == serviceType['type'];

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedServiceType = serviceType['type'];
                      });
                      _loadServices(refresh: true);
                    },
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? AppColors.primary : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[300]!,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            serviceType['icon'],
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            serviceType['label'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Specialization Filter (for doctors)
            if (_selectedServiceType == 'doctor' &&
                _specializations.isNotEmpty) ...[
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter by Specialization',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: _selectedSpecialization.isEmpty,
                          onSelected: (selected) {
                            setState(() {
                              _selectedSpecialization = '';
                            });
                          },
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                        ),
                        ..._specializations.map((spec) {
                          final isSelected = _selectedSpecialization == spec;
                          return FilterChip(
                            label: Text(spec),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedSpecialization = selected ? spec : '';
                              });
                            },
                            selectedColor: AppColors.primary.withOpacity(0.2),
                            checkmarkColor: AppColors.primary,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Services List
            Padding(
              padding: const EdgeInsets.all(16),
              child: _isLoading && _services.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null && _services.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error,
                                  size: 48, color: AppColors.error),
                              const SizedBox(height: 16),
                              Text(_error!,
                                  style:
                                      const TextStyle(color: AppColors.error)),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _loadServices(refresh: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : _getFilteredServices().isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('No services found'),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your filters',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                ..._getFilteredServices().map((service) {
                                  return _buildServiceCard(service);
                                }),
                                if (_hasMore && _services.length >= 10)
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        _currentPage++;
                                        _loadServices();
                                      },
                                      child: const Text('Load More'),
                                    ),
                                  ),
                              ],
                            ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final name =
        '${service['firstName'] ?? ''} ${service['lastName'] ?? ''}'.trim();
    final specialization =
        service['specialization']?.toString() ?? 'Service Provider';
    final experience = service['experience']?.toString() ?? '0';
    final consultationFee = service['consultationFee']?.toString() ?? '0';
    final rating = service['rating']?['average']?.toStringAsFixed(1) ?? '0.0';
    final distance = service['distance']?.toString() ?? 'N/A';
    const distanceUnit = 'km';
    final availability = service['availability'] as List?;
    final hasAvailability = availability != null && availability.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and rating
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'S',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        specialization,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.star,
                            color: AppColors.warning, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          rating,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    Text(
                      '$distance $distanceUnit',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Details
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Experience',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$experience years',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Consultation Fee',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '₹$consultationFee',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Availability',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        hasAvailability ? 'Available' : 'Not Available',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: hasAvailability
                              ? AppColors.success
                              : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // About
            if (service['about'] != null &&
                (service['about'] as String).isNotEmpty) ...[
              Text(
                service['about'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Book Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingScreen(
                        provider: service,
                        serviceType: _selectedServiceType,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Book Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
