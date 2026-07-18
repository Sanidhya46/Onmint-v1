import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'instant_booking_screen.dart';
import '../booking/lab_test_booking_screen.dart';

class PathologyScreen extends StatefulWidget {
  const PathologyScreen({super.key});

  @override
  State<PathologyScreen> createState() => _PathologyScreenState();
}

class _PathologyScreenState extends State<PathologyScreen> {
  final PatientService _patientService = PatientService();

  List<Map<String, dynamic>> _labs = [];
  String _selectedCategory = '';
  String _selectedCity = '';
  bool _isLoading = true;
  final TextEditingController _cityController = TextEditingController();

  final List<Map<String, dynamic>> _testCategories = [
    {'id': '', 'name': 'All Tests', 'icon': Icons.science},
    {'id': 'blood_test', 'name': 'Blood Test', 'icon': Icons.bloodtype},
    {'id': 'urine_test', 'name': 'Urine Test', 'icon': Icons.local_hospital},
    {'id': 'diabetes', 'name': 'Diabetes', 'icon': Icons.monitor_heart},
    {'id': 'thyroid', 'name': 'Thyroid', 'icon': Icons.medical_services},
    {'id': 'liver', 'name': 'Liver Function', 'icon': Icons.health_and_safety},
    {'id': 'kidney', 'name': 'Kidney Function', 'icon': Icons.water_drop},
    {'id': 'cardiac', 'name': 'Cardiac', 'icon': Icons.favorite},
    {'id': 'vitamin', 'name': 'Vitamin', 'icon': Icons.medication},
    {'id': 'allergy', 'name': 'Allergy Test', 'icon': Icons.warning},
  ];

  @override
  void initState() {
    super.initState();
    _loadLabs();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadLabs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      debugPrint('Loading pathology labs with city filter: $_selectedCity');

      // Call the correct API endpoint: /patient/search/labs
      final response = await _patientService.searchPathologyLabs(
        city: _selectedCity.isEmpty ? null : _selectedCity,
        page: 1,
        limit: 20,
      );

      debugPrint('Pathology labs response: $response');

      // Parse response: {"success": true, "data": [...], "pagination": {...}}
      final data = response['data'];
      List<Map<String, dynamic>> labs = [];

      if (data is List) {
        labs = List<Map<String, dynamic>>.from(data);
      }

      debugPrint('Found ${labs.length} pathology labs');

      if (mounted) {
        setState(() {
          _labs = labs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading pathology labs: $e');
      if (mounted) {
        setState(() {
          _labs = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load labs: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Lab Tests'),
        backgroundColor: const Color(0xFFFF6B6B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => _loadLabs(),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          _buildQuickBookSection(),
          _buildCityFilterSection(),
          _buildCategoriesSection(),
          Expanded(child: _buildLabsList()),
        ],
      )),
    );
  }

  Widget _buildCityFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'Filter by city',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.location_city,
                    color: Color(0xFFFF6B6B), size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onSubmitted: (value) {
                setState(() => _selectedCity = value.trim());
                _loadLabs();
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              setState(() => _selectedCity = _cityController.text.trim());
              _loadLabs();
            },
            icon: const Icon(Icons.search),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickBookSection() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.science, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Need Lab Tests?',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Home sample collection',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const InstantBookingScreen(serviceType: 'pathology'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF6B6B),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Book Now', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Test Categories',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 70,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _testCategories.length,
            itemBuilder: (context, index) {
              final category = _testCategories[index];
              final isSelected = _selectedCategory == category['id'];

              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category['id']),
                child: Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 10),
                  child: Column(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFF6B6B)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          category['icon'],
                          color: isSelected ? Colors.white : Colors.grey[600],
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category['name'],
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected
                              ? const Color(0xFFFF6B6B)
                              : Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildLabsList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF6B6B)));
    }

    if (_labs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.science, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _selectedCity.isEmpty
                  ? 'No labs available'
                  : 'No labs found in $_selectedCity',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCity.isEmpty
                  ? 'Try filtering by city'
                  : 'Try a different city',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            _selectedCity.isEmpty
                ? 'Pathology Labs (${_labs.length})'
                : 'Labs in $_selectedCity (${_labs.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _labs.length,
            itemBuilder: (context, index) {
              final lab = _labs[index];
              final testsOffered = lab['testsOffered'] as List? ?? [];
              final homeCollection = lab['homeCollectionAvailable'] ?? false;
              final homeCollectionFee = lab['homeCollectionFee'] ?? 0;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _viewLabDetails(lab),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B6B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.science,
                                color: Color(0xFFFF6B6B),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lab['labName'] ??
                                        lab['firstName'] ??
                                        'Lab Center',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  if (lab['city'] != null)
                                    Text(
                                      '${lab['city']}, ${lab['state'] ?? ''}',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600]),
                                    ),
                                ],
                              ),
                            ),
                            if (homeCollection)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Home Collection',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (testsOffered.isNotEmpty) ...[
                          Text(
                            'Available Tests (${testsOffered.length}):',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: testsOffered.take(3).map((test) {
                              final price = test['price'] ?? 0;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.blue, width: 1),
                                ),
                                child: Text(
                                  '${test['name']} - ₹$price',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500),
                                ),
                              );
                            }).toList(),
                          ),
                          if (testsOffered.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '+${testsOffered.length - 3} more tests',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            if (homeCollection)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Home Collection Fee',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600]),
                                    ),
                                    Text(
                                      '₹$homeCollectionFee',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            ElevatedButton(
                              onPressed: () => _bookLabTest(lab),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6B6B),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                              child: const Text('Book Test',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _viewLabDetails(Map<String, dynamic> lab) {
    // TODO: Navigate to lab details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Viewing ${lab['labName'] ?? 'Lab'} details'),
        backgroundColor: const Color(0xFFFF6B6B),
      ),
    );
  }

  void _bookLabTest(Map<String, dynamic> lab) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LabTestBookingScreen(lab: lab),
      ),
    );
  }
}
