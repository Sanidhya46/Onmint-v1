import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class PharmacyDetailScreen extends StatefulWidget {
  final String pharmacyId;

  const PharmacyDetailScreen({
    super.key,
    required this.pharmacyId,
  });

  @override
  State<PharmacyDetailScreen> createState() => _PharmacyDetailScreenState();
}

class _PharmacyDetailScreenState extends State<PharmacyDetailScreen> {
  final _apiClient = OnMintApiClient();
  final _searchController = TextEditingController();

  Map<String, dynamic>? _pharmacy;
  List<dynamic> _medicines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPharmacyDetails();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPharmacyDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await _apiClient.patient.getPharmacyDetails(widget.pharmacyId);

      setState(() {
        _pharmacy = response;
        _medicines = response['medicines'] ?? [];
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
        title: const Text('Pharmacy Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _loadPharmacyDetails,
                )
              : _pharmacy == null
                  ? const EmptyStateWidget(
                      title: 'Not Found',
                      message: 'Pharmacy not found',
                      icon: Icons.medication,
                    )
                  : Column(
                      children: [
                        _buildHeader(),
                        _buildSearchBar(),
                        Expanded(
                          child: _medicines.isEmpty
                              ? const EmptyStateWidget(
                                  title: 'No Medicines',
                                  message: 'No medicines available',
                                  icon: Icons.medication,
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _medicines.length,
                                  itemBuilder: (context, index) {
                                    final medicine = _medicines[index];
                                    return _buildMedicineCard(medicine);
                                  },
                                ),
                        ),
                      ],
                    )),
    );
  }

  Widget _buildHeader() {
    final rating = _pharmacy!['rating']?.toDouble() ?? 0.0;
    final reviewCount = _pharmacy!['reviewCount'] ?? 0;
    final isOpen = _pharmacy!['isOpen'] ?? false;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
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
                  Icons.medication,
                  color: Colors.green,
                  size: 40,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _pharmacy!['name'] ?? 'Unknown Pharmacy',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
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
          if (_pharmacy!['address'] != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_pharmacy!['address']['street']}, ${_pharmacy!['address']['city']}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
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
        hint: 'Search medicines',
        prefixIcon: Icons.search,
        onChanged: (value) {
          setState(() {
            // Filter medicines locally
          });
        },
      ),
    );
  }

  Widget _buildMedicineCard(dynamic medicine) {
    final price = medicine['price']?.toDouble() ?? 0.0;
    final stock = medicine['stock'] ?? 0;
    final inStock = stock > 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.medication_liquid,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    medicine['name'] ?? 'Unknown Medicine',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (medicine['genericName'] != null)
                    Text(
                      medicine['genericName'],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '₹$price',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: inStock
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          inStock ? 'In Stock' : 'Out of Stock',
                          style: TextStyle(
                            fontSize: 11,
                            color: inStock ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: inStock
                  ? () {
                      ToastUtils.showInfo('Order feature coming soon');
                    }
                  : null,
              icon: const Icon(Icons.add_shopping_cart),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }
}
