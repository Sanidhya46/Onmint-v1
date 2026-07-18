import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import '../booking/test_booking_screen.dart';

class PathologyLabDetailScreen extends StatefulWidget {
  final String labId;

  const PathologyLabDetailScreen({
    super.key,
    required this.labId,
  });

  @override
  State<PathologyLabDetailScreen> createState() =>
      _PathologyLabDetailScreenState();
}

class _PathologyLabDetailScreenState extends State<PathologyLabDetailScreen> {
  final _apiClient = OnMintApiClient();
  final _searchController = TextEditingController();

  Map<String, dynamic>? _lab;
  List<dynamic> _tests = [];
  List<dynamic> _filteredTests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLabDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLabDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await _apiClient.patient.getPathologyLabDetails(widget.labId);

      setState(() {
        _lab = response;
        _tests = response['tests'] ?? [];
        _filteredTests = _tests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterTests(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredTests = _tests;
      } else {
        _filteredTests = _tests.where((test) {
          final name = (test['name'] ?? '').toLowerCase();
          final description = (test['description'] ?? '').toLowerCase();
          final searchQuery = query.toLowerCase();
          return name.contains(searchQuery) ||
              description.contains(searchQuery);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _loadLabDetails,
                )
              : _lab == null
                  ? const EmptyStateWidget(
                      title: 'Not Found',
                      message: 'Lab not found',
                      icon: Icons.science,
                    )
                  : Column(
                      children: [
                        _buildHeader(),
                        _buildSearchBar(),
                        Expanded(
                          child: _filteredTests.isEmpty
                              ? const EmptyStateWidget(
                                  title: 'No Tests',
                                  message: 'No tests found',
                                  icon: Icons.science,
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredTests.length,
                                  itemBuilder: (context, index) {
                                    final test = _filteredTests[index];
                                    return _buildTestCard(test);
                                  },
                                ),
                        ),
                      ],
                    )),
    );
  }

  Widget _buildHeader() {
    final rating = _lab!['rating']?.toDouble() ?? 0.0;
    final reviewCount = _lab!['reviewCount'] ?? 0;
    final isOpen = _lab!['isOpen'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade700, Colors.purple.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.science,
                  color: Colors.purple,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _lab!['name'] ?? 'Unknown Lab',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (rating > 0) ...[
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '${rating.toStringAsFixed(1)} ($reviewCount)',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isOpen ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isOpen ? 'Open' : 'Closed',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_lab!['address'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_lab!['address']['street']}, ${_lab!['address']['city']}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_lab!['homeCollection'] == true) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.home, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Home Sample Collection Available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: CustomTextField(
        label: 'Search',
        controller: _searchController,
        hint: 'Search tests',
        prefixIcon: Icons.search,
        onChanged: _filterTests,
      ),
    );
  }

  Widget _buildTestCard(dynamic test) {
    final price = test['price']?.toDouble() ?? 0.0;
    final preparationRequired = test['preparationRequired'] ?? false;
    final reportTime = test['reportTime'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.medical_services,
                    color: Colors.purple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        test['name'] ?? 'Unknown Test',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (test['description'] != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          test['description'],
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Report: $reportTime',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      if (preparationRequired) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber,
                                size: 14, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              'Preparation required',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TestBookingScreen(
                              lab: _lab!,
                              test: test,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Book', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
