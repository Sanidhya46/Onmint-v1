import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import 'bloodbank_detail_screen.dart';

class BloodBanksScreen extends StatefulWidget {
  const BloodBanksScreen({super.key});

  @override
  State<BloodBanksScreen> createState() => _BloodBanksScreenState();
}

class _BloodBanksScreenState extends State<BloodBanksScreen> {
  final _apiClient = OnMintApiClient();
  final _searchController = TextEditingController();

  List<dynamic> _bloodBanks = [];
  bool _isLoading = true;
  String? _error;
  String _selectedBloodGroup = 'All';

  final List<String> _bloodGroups = [
    'All',
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  @override
  void initState() {
    super.initState();
    _loadBloodBanks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBloodBanks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiClient.initialize();

      final result = await _apiClient.patient.searchBloodBanks(
        bloodGroup: _selectedBloodGroup == 'All' ? null : _selectedBloodGroup,
        city: _searchController.text.isEmpty ? null : _searchController.text,
      );

      setState(() {
        _bloodBanks = result['data'] as List? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Color _getStockColor(int units) {
    if (units == 0) return Colors.red;
    if (units < 5) return Colors.orange;
    if (units < 10) return Colors.yellow.shade700;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Banks'),
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
              hint: 'Search blood banks by name or location',
              prefixIcon: Icons.search,
              onChanged: (value) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _loadBloodBanks();
                  }
                });
              },
            ),
          ),

          // Blood Group Filter
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _bloodGroups.length,
              itemBuilder: (context, index) {
                final bloodGroup = _bloodGroups[index];
                final isSelected = _selectedBloodGroup == bloodGroup;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(bloodGroup),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedBloodGroup = bloodGroup;
                      });
                      _loadBloodBanks();
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.red.shade700,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Blood Banks List
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                    ? CustomErrorWidget(
                        message: _error!,
                        onRetry: _loadBloodBanks,
                      )
                    : _bloodBanks.isEmpty
                        ? const EmptyStateWidget(
                            title: 'No Blood Banks',
                            message: 'No blood banks found',
                            icon: Icons.bloodtype,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadBloodBanks,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _bloodBanks.length,
                              itemBuilder: (context, index) {
                                final bloodBank = _bloodBanks[index];
                                return _buildBloodBankCard(bloodBank);
                              },
                            ),
                          ),
          ),
        ],
      )),
    );
  }

  Widget _buildBloodBankCard(dynamic bloodBank) {
    final bloodStock = bloodBank['bloodStock'] ?? {};
    final rating = bloodBank['rating']?.toDouble() ?? 0.0;
    final reviewCount = bloodBank['reviewCount'] ?? 0;

    // Calculate total available units
    int totalUnits = 0;
    bloodStock.forEach((key, value) {
      totalUnits += (value as int? ?? 0);
    });

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BloodBankDetailScreen(bloodBankId: bloodBank['_id']),
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
                  // Blood Bank Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.bloodtype,
                      color: Colors.red.shade700,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Blood Bank Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bloodBank['name'] ?? 'Unknown Blood Bank',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),

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

                        // Location
                        if (bloodBank['address'] != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${bloodBank['address']['city']}, ${bloodBank['address']['state']}',
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
                        const SizedBox(height: 4),

                        // Phone
                        if (bloodBank['phone'] != null)
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                bloodBank['phone'],
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

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),

              // Blood Stock Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Blood Availability',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$totalUnits units available',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Blood Group Stock Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _bloodGroups.length - 1, // Exclude 'All'
                itemBuilder: (context, index) {
                  final group = _bloodGroups[index + 1];
                  final units = bloodStock[group] ?? 0;
                  final color = _getStockColor(units);

                  return Container(
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      border: Border.all(color: color),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          group,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$units',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
