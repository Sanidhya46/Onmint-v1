import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import 'pathology_lab_detail_screen.dart';

class PathologyLabsScreen extends StatefulWidget {
  const PathologyLabsScreen({super.key});

  @override
  State<PathologyLabsScreen> createState() => _PathologyLabsScreenState();
}

class _PathologyLabsScreenState extends State<PathologyLabsScreen> {
  final _apiClient = OnMintApiClient();
  final _searchController = TextEditingController();

  List<dynamic> _labs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLabs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLabs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiClient.initialize();

      final result = await _apiClient.patient.searchLabs(
        city: _searchController.text.isEmpty ? null : _searchController.text,
      );

      setState(() {
        _labs = result['data'] as List? ?? [];
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
        title: const Text('Pathology Labs'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: CustomTextField(
              label: 'Search',
              controller: _searchController,
              hint: 'Search labs or tests',
              prefixIcon: Icons.search,
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _loadLabs();
                  }
                });
              },
            ),
          ),

          const Divider(height: 1),

          // Labs List
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                    ? CustomErrorWidget(
                        message: _error!,
                        onRetry: _loadLabs,
                      )
                    : _labs.isEmpty
                        ? const EmptyStateWidget(
                            title: 'No Labs',
                            message: 'No pathology labs found',
                            icon: Icons.science,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadLabs,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _labs.length,
                              itemBuilder: (context, index) {
                                final lab = _labs[index];
                                return _buildLabCard(lab);
                              },
                            ),
                          ),
          ),
        ],
      )),
    );
  }

  Widget _buildLabCard(dynamic lab) {
    final rating = lab['rating']?.toDouble() ?? 0.0;
    final reviewCount = lab['reviewCount'] ?? 0;
    final tests = lab['tests'] as List? ?? [];
    final isOpen = lab['isOpen'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PathologyLabDetailScreen(labId: lab['_id']),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lab Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.science,
                      color: Colors.purple,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Lab Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                lab['name'] ?? 'Unknown Lab',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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
                        const SizedBox(height: 8),

                        // Rating
                        if (rating > 0)
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                ' ($reviewCount reviews)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 8),

                        // Tests Count
                        Row(
                          children: [
                            const Icon(Icons.medical_services,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${tests.length} tests available',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Location
                        if (lab['address'] != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${lab['address']['city']}, ${lab['address']['state']}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
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
                ],
              ),

              // Popular Tests
              if (tests.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Popular Tests',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tests.take(3).map<Widget>((test) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            test['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.purple,
                            ),
                          ),
                          if (test['price'] != null) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₹${test['price']}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Home Collection
              if (lab['homeCollection'] == true) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.home,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Home Sample Collection Available',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
