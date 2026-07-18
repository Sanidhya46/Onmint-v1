import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import '../booking/booking_flow_screen.dart';
import '../services/instant_booking_screen.dart';

class DoctorsScreen extends StatefulWidget {
  const DoctorsScreen({super.key});

  @override
  State<DoctorsScreen> createState() => _DoctorsScreenState();
}

class _DoctorsScreenState extends State<DoctorsScreen> {
  final PatientService _patientService = PatientService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _doctors = [];
  List<Map<String, dynamic>> _filteredDoctors = [];
  bool _isLoading = false;
  String? _selectedSpecialization;
  String? _selectedCity;
  String? _selectedConsultationType; // NEW: Consultation type filter

  final List<String> _specializations = [
    'General Physician',
    'Cardiology',
    'Dermatology',
    'Pediatrics',
    'Orthopedics',
    'Gynecology',
    'Neurology',
    'Psychiatry',
    'ENT',
    'Ophthalmology',
  ];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
    _searchController.addListener(_filterDoctors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    if (!mounted) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final response = await _patientService.searchDoctors(
        limit: 100,
        consultationType:
            _selectedConsultationType, // Pass consultation type filter
      );

      final doctors = response['data'] ?? [];
      if (mounted) {
        setState(() {
          _doctors = List<Map<String, dynamic>>.from(doctors);
          _filteredDoctors = _doctors;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading doctors: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredDoctors = _doctors.where((doctor) {
        final name = '${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}'
            .toLowerCase();
        final specialization = (doctor['specialization'] ?? '').toLowerCase();
        final city = (doctor['city'] ?? '').toLowerCase();

        // Text search filter
        final matchesSearch = query.isEmpty ||
            name.contains(query) ||
            specialization.contains(query) ||
            city.contains(query);

        // Specialization filter
        final matchesSpecialization = _selectedSpecialization == null ||
            specialization.contains(_selectedSpecialization!.toLowerCase());

        // City filter
        final matchesCity = _selectedCity == null ||
            city.contains(_selectedCity!.toLowerCase());

        return matchesSearch && matchesSpecialization && matchesCity;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedSpecialization = null;
      _selectedCity = null;
      _selectedConsultationType = null; // Clear consultation type filter
      _searchController.clear();
      _filteredDoctors = _doctors;
    });
    _loadDoctors(); // Reload without filters
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Doctors'),
        backgroundColor: const Color(0xFF667EEA),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Filters',
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          // Search and Filters
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search doctors, specializations, cities...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 12),

                // Filter Row
                Row(
                  children: [
                    // Specialization Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedSpecialization,
                        decoration: const InputDecoration(
                          labelText: 'Specialization',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All')),
                          ..._specializations.map((spec) =>
                              DropdownMenuItem(value: spec, child: Text(spec))),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecialization = value;
                          });
                          _filterDoctors();
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    // City Filter
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value.isEmpty ? null : value;
                          });
                          _filterDoctors();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Consultation Type Filter
                DropdownButtonFormField<String>(
                  value: _selectedConsultationType,
                  decoration: const InputDecoration(
                    labelText: 'Consultation Type',
                    prefixIcon: Icon(Icons.medical_services),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All Types')),
                    DropdownMenuItem(
                      value: 'video-call',
                      child: Row(
                        children: [
                          Icon(Icons.videocam, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Text('Video Call'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'in-person',
                      child: Row(
                        children: [
                          Icon(Icons.person, color: Colors.green, size: 18),
                          SizedBox(width: 8),
                          Text('In-Person Visit'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'phone-call',
                      child: Row(
                        children: [
                          Icon(Icons.phone, color: Colors.orange, size: 18),
                          SizedBox(width: 8),
                          Text('Phone Call'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedConsultationType = value;
                    });
                    _loadDoctors(); // Reload with new filter
                  },
                ),

                const SizedBox(height: 16),

                // Instant Doctor Appointment Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InstantBookingScreen(
                          serviceType: 'doctor',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.flash_on,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Get Instant Doctor Appointment',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'First available doctor will accept your request',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Results Count
          if (!_isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${_filteredDoctors.length} doctors found',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Doctors List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF667EEA)))
                : _filteredDoctors.isEmpty
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
                            Text(
                              'No doctors found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadDoctors,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDoctors.length,
                          itemBuilder: (context, index) {
                            final doctor = _filteredDoctors[index];
                            return _buildDoctorCard(doctor);
                          },
                        ),
                      ),
          ),
        ],
      )),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Doctor Avatar
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFF667EEA),
                  backgroundImage: doctor['profilePicture'] != null &&
                          doctor['profilePicture'].toString().isNotEmpty
                      ? NetworkImage(doctor['profilePicture'])
                      : null,
                  child: doctor['profilePicture'] == null ||
                          doctor['profilePicture'].toString().isEmpty
                      ? Text(
                          (doctor['firstName']?.toString() ?? 'D')
                              .substring(0, 1)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),

                const SizedBox(width: 16),

                // Doctor Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dr. ${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}'
                            .trim(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        doctor['specialization']?.toString() ??
                            'General Physician',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.work, size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor['experience'] ?? 0} years experience',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: 16, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            '${doctor['city'] ?? ''}, ${doctor['state'] ?? ''}'
                                .replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Consultation Fee
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${doctor['consultationFee'] ?? 500}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF667EEA),
                      ),
                    ),
                    const Text(
                      'Consultation',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Qualifications
            if (doctor['qualifications'] is List &&
                (doctor['qualifications'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children:
                    (doctor['qualifications'] as List).map((qualification) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      qualification.toString(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF667EEA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Consultation Types
            if (doctor['consultationTypes'] is List &&
                (doctor['consultationTypes'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.medical_services,
                      size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Available: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children:
                          (doctor['consultationTypes'] as List).map((type) {
                        IconData icon;
                        Color color;
                        String label;

                        switch (type.toString()) {
                          case 'video-call':
                            icon = Icons.videocam;
                            color = Colors.blue;
                            label = 'Video';
                            break;
                          case 'in-person':
                            icon = Icons.person;
                            color = Colors.green;
                            label = 'In-Person';
                            break;
                          case 'phone-call':
                            icon = Icons.phone;
                            color = Colors.orange;
                            label = 'Phone';
                            break;
                          default:
                            icon = Icons.help;
                            color = Colors.grey;
                            label = type.toString();
                        }

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: color.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: color),
                              const SizedBox(width: 4),
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: color,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],

            // Languages
            if (doctor['languages'] is List &&
                (doctor['languages'] as List).isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.language, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    'Languages: ${(doctor['languages'] as List).join(', ')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showDoctorDetails(doctor),
                    child: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _bookAppointment(doctor),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDoctorDetails(Map<String, dynamic> doctor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Doctor Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF667EEA),
                      child: Text(
                        (doctor['firstName']?.toString() ?? 'D')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dr. ${doctor['firstName'] ?? ''} ${doctor['lastName'] ?? ''}'
                                .trim(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            doctor['specialization']?.toString() ??
                                'General Physician',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // About
                if (doctor['about'] != null &&
                    doctor['about'].toString().isNotEmpty) ...[
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    doctor['about'].toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                ],

                // Details
                _buildDetailSection(
                    'Experience', '${doctor['experience'] ?? 0} years'),
                _buildDetailSection(
                    'Consultation Fee', '₹${doctor['consultationFee'] ?? 500}'),
                _buildDetailSection('License Number',
                    doctor['licenseNumber']?.toString() ?? 'Not provided'),
                _buildDetailSection(
                    'Location',
                    '${doctor['city'] ?? ''}, ${doctor['state'] ?? ''}'
                        .replaceAll(RegExp(r'^,\s*|,\s*$'), '')),

                const SizedBox(height: 20),

                // Book Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _bookAppointment(doctor);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book Appointment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _bookAppointment(Map<String, dynamic> doctor) {
    try {
      final doctorUser = User.fromJson(doctor);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingFlowScreen(
            provider: doctorUser,
            serviceType: 'doctor',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading doctor: $e')),
      );
    }
  }
}
