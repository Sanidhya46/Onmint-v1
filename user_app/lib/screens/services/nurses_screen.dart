import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import '../booking/nurse_booking_screen.dart';
import '../services/instant_booking_screen.dart';

class NursesScreen extends StatefulWidget {
  const NursesScreen({super.key});

  @override
  State<NursesScreen> createState() => _NursesScreenState();
}

class _NursesScreenState extends State<NursesScreen> {
  final PatientService _patientService = PatientService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _nurses = [];
  List<Map<String, dynamic>> _filteredNurses = [];
  bool _isLoading = false;
  String? _selectedCity;
  @override
  void initState() {
    super.initState();
    _loadNurses();
    _searchController.addListener(_filterNurses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNurses() async {
    if (!mounted) return;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      // Search for nurses using the correct API
      final response = await _patientService.searchNurses(
        limit: 100,
      );

      final data = response['data'];
      List<Map<String, dynamic>> nurses = [];

      if (data is List) {
        nurses = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['data'] is List) {
        nurses = List<Map<String, dynamic>>.from(data['data']);
      }

      if (mounted) {
        setState(() {
          _nurses = nurses;
          _filteredNurses = nurses;
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
            content: Text('Error loading nurses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterNurses() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredNurses = _nurses.where((nurse) {
        final name = '${nurse['firstName'] ?? ''} ${nurse['lastName'] ?? ''}'
            .toLowerCase();
        final services =
            (nurse['services'] as List?)?.join(' ').toLowerCase() ?? '';
        final city = (nurse['city'] ?? nurse['address']?['city'] ?? '')
            .toString()
            .toLowerCase();

        // Text search filter
        final matchesSearch = query.isEmpty ||
            name.contains(query) ||
            services.contains(query) ||
            city.contains(query);

        // City filter
        final matchesCity = _selectedCity == null ||
            city.contains(_selectedCity!.toLowerCase());

        return matchesSearch && matchesCity;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _searchController.clear();
      _filteredNurses = _nurses;
    });
    _loadNurses(); // Reload without filters
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Find Nurses'),
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
                    hintText: 'Search nurses, services, cities...',
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
                    // City Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('All Cities')),
                          const DropdownMenuItem(
                              value: 'Mumbai', child: Text('Mumbai')),
                          const DropdownMenuItem(
                              value: 'Delhi', child: Text('Delhi')),
                          const DropdownMenuItem(
                              value: 'Bangalore', child: Text('Bangalore')),
                          const DropdownMenuItem(
                              value: 'Chennai', child: Text('Chennai')),
                          const DropdownMenuItem(
                              value: 'Kolkata', child: Text('Kolkata')),
                          const DropdownMenuItem(
                              value: 'Hyderabad', child: Text('Hyderabad')),
                          const DropdownMenuItem(
                              value: 'Pune', child: Text('Pune')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                          _filterNurses();
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
                          _filterNurses();
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Instant Nurse Booking Button
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const InstantBookingScreen(
                          serviceType: 'nurse',
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
                                'Get Instant Nurse Service',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'First available nurse will accept your request',
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
                    '${_filteredNurses.length} nurses found',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

          // Nurses List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF667EEA)))
                : _filteredNurses.isEmpty
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
                              'No nurses found',
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
                        onRefresh: _loadNurses,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredNurses.length,
                          itemBuilder: (context, index) {
                            final nurse = _filteredNurses[index];
                            return _buildNurseCard(nurse);
                          },
                        ),
                      ),
          ),
        ],
      )),
    );
  }

  Widget _buildNurseCard(Map<String, dynamic> nurse) {
    final services = nurse['services'] as List? ?? [];
    final rating = (nurse['rating'] ?? 0).toDouble();
    final reviewCount = nurse['reviewCount'] ?? nurse['totalRatings'] ?? 0;
    final experience = nurse['experience'] ?? 0;
    final distance = nurse['distance']; // NEW: Get distance from API

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Nurse Avatar
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: const Color(0xFF667EEA),
                      backgroundImage: nurse['profilePicture'] != null &&
                              nurse['profilePicture'].toString().isNotEmpty
                          ? NetworkImage(nurse['profilePicture'])
                          : null,
                      child: nurse['profilePicture'] == null ||
                              nurse['profilePicture'].toString().isEmpty
                          ? Text(
                              (nurse['firstName']?.toString() ?? 'N')
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

                    // Nurse Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${nurse['firstName'] ?? ''} ${nurse['lastName'] ?? ''}'
                                .trim(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.work,
                                  size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                '$experience years experience',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          if (rating > 0) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  ' ($reviewCount reviews)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ],
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${nurse['city'] ?? nurse['address']?['city'] ?? ''}, ${nurse['state'] ?? nurse['address']?['state'] ?? ''}'
                                      .replaceAll(RegExp(r'^,\s*|,\s*$'), ''),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Hourly Rate
                    if (nurse['hourlyRate'] != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${nurse['hourlyRate']}/hr',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF667EEA),
                            ),
                          ),
                          const Text(
                            'Per Hour',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Services
                if (services.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: services.take(4).map((service) {
                      final serviceName = service is String
                          ? service
                          : service['name'] ?? service.toString();
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF667EEA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          serviceName,
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

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showNurseDetails(nurse),
                        child: const Text('View Profile'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _bookNurse(nurse),
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
          // Distance Badge (NEW)
          if (distance != null)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF667EEA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${distance.toStringAsFixed(1)} km',
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
    );
  }

  void _showNurseDetails(Map<String, dynamic> nurse) {
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

                // Nurse Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF667EEA),
                      child: Text(
                        (nurse['firstName']?.toString() ?? 'N')
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
                            '${nurse['firstName'] ?? ''} ${nurse['lastName'] ?? ''}'
                                .trim(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${nurse['experience'] ?? 0} years experience',
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

                // Details
                if (nurse['about'] != null &&
                    nurse['about'].toString().isNotEmpty) ...[
                  const Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nurse['about'].toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                ],

                _buildDetailSection(
                    'Experience', '${nurse['experience'] ?? 0} years'),
                _buildDetailSection(
                    'Hourly Rate', '₹${nurse['hourlyRate'] ?? 'N/A'}/hour'),
                _buildDetailSection(
                    'Location',
                    '${nurse['city'] ?? ''}, ${nurse['state'] ?? ''}'
                        .replaceAll(RegExp(r'^,\s*|,\s*$'), '')),

                const SizedBox(height: 20),

                // Book Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _bookNurse(nurse);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book Nurse',
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

  void _bookNurse(Map<String, dynamic> nurse) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NurseBookingScreen(nurse: nurse),
      ),
    );
  }
}
