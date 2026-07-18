import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import 'pharmacy_detail_screen.dart';

class PharmaciesScreen extends StatefulWidget {
  const PharmaciesScreen({super.key});

  @override
  State<PharmaciesScreen> createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  final _apiClient = OnMintApiClient();
  final _searchController = TextEditingController();

  List<dynamic> _pharmacies = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPharmacies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacies() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiClient.initialize();

      final result = await _apiClient.patient.searchPharmacies(
        city: _searchController.text.isEmpty ? null : _searchController.text,
      );

      setState(() {
        _pharmacies = result['data'] as List? ?? [];
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
        title: const Text('Pharmacies'),
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
              hint: 'Search pharmacies or medicines',
              prefixIcon: Icons.search,
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _loadPharmacies();
                  }
                });
              },
            ),
          ),

          const Divider(height: 1),

          // Pharmacies List
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                    ? CustomErrorWidget(
                        message: _error!,
                        onRetry: _loadPharmacies,
                      )
                    : _pharmacies.isEmpty
                        ? const EmptyStateWidget(
                            title: 'No Pharmacies',
                            message: 'No pharmacies found',
                            icon: Icons.medication,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadPharmacies,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _pharmacies.length,
                              itemBuilder: (context, index) {
                                final pharmacy = _pharmacies[index];
                                return _buildPharmacyCard(pharmacy);
                              },
                            ),
                          ),
          ),
        ],
      )),
    );
  }

  Widget _buildPharmacyCard(dynamic pharmacy) {
    final rating = pharmacy['rating']?.toDouble() ?? 0.0;
    final reviewCount = pharmacy['reviewCount'] ?? 0;
    final isOpen = pharmacy['isOpen'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PharmacyDetailScreen(pharmacyId: pharmacy['_id']),
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
                  // Pharmacy Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.medication,
                      color: Colors.green,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Pharmacy Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pharmacy['name'] ?? 'Unknown Pharmacy',
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

                        // Location
                        if (pharmacy['address'] != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${pharmacy['address']['street']}, ${pharmacy['address']['city']}',
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
                        const SizedBox(height: 8),

                        // Contact
                        if (pharmacy['phone'] != null)
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                pharmacy['phone'],
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Delivery Info
              if (pharmacy['deliveryAvailable'] == true) ...[
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
                        Icons.delivery_dining,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Home Delivery Available',
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
