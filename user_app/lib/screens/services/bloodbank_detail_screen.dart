import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';
import '../booking/blood_request_screen.dart';

class BloodBankDetailScreen extends StatefulWidget {
  final String bloodBankId;

  const BloodBankDetailScreen({
    super.key,
    required this.bloodBankId,
  });

  @override
  State<BloodBankDetailScreen> createState() => _BloodBankDetailScreenState();
}

class _BloodBankDetailScreenState extends State<BloodBankDetailScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _bloodBank;
  bool _isLoading = true;
  String? _error;

  final List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

  @override
  void initState() {
    super.initState();
    _loadBloodBankDetails();
  }

  Future<void> _loadBloodBankDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response =
          await _apiClient.patient.getBloodBankDetails(widget.bloodBankId);

      setState(() {
        _bloodBank = response;
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

  String _getStockStatus(int units) {
    if (units == 0) return 'Out of Stock';
    if (units < 5) return 'Critical';
    if (units < 10) return 'Low Stock';
    return 'Available';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Bank Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const LoadingWidget()
          : _error != null
              ? CustomErrorWidget(
                  message: _error!,
                  onRetry: _loadBloodBankDetails,
                )
              : _bloodBank == null
                  ? const EmptyStateWidget(
                      title: 'Not Found',
                      message: 'Blood bank not found',
                      icon: Icons.bloodtype,
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          _buildInfoSection(),
                          _buildBloodStockSection(),
                          _buildContactSection(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    )),
      bottomNavigationBar: _bloodBank != null ? _buildRequestButton() : null,
    );
  }

  Widget _buildHeader() {
    final rating = _bloodBank!['rating']?.toDouble() ?? 0.0;
    final reviewCount = _bloodBank!['reviewCount'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.bloodtype,
              size: 50,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _bloodBank!['name'] ?? 'Unknown Blood Bank',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          if (rating > 0) ...[
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
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
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
                  if (_bloodBank!['address'] != null)
                    _buildInfoRow(
                      Icons.location_on_outlined,
                      'Address',
                      '${_bloodBank!['address']['street']}, ${_bloodBank!['address']['city']}, ${_bloodBank!['address']['state']} - ${_bloodBank!['address']['zipCode']}',
                    ),
                  if (_bloodBank!['phone'] != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      Icons.phone_outlined,
                      'Phone',
                      _bloodBank!['phone'],
                    ),
                  ],
                  if (_bloodBank!['email'] != null) ...[
                    const Divider(),
                    _buildInfoRow(
                      Icons.email_outlined,
                      'Email',
                      _bloodBank!['email'],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.red.shade700, size: 20),
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

  Widget _buildBloodStockSection() {
    final bloodStock = _bloodBank!['bloodStock'] ?? {};

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Blood Availability',
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
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _bloodGroups.length,
                    itemBuilder: (context, index) {
                      final group = _bloodGroups[index];
                      final units = bloodStock[group] ?? 0;
                      final color = _getStockColor(units);
                      final status = _getStockStatus(units);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          border: Border.all(color: color, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                group,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$units units',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                  Text(
                                    status,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildLegendItem('Available', Colors.green),
                      _buildLegendItem('Low', Colors.yellow.shade700),
                      _buildLegendItem('Critical', Colors.orange),
                      _buildLegendItem('Out', Colors.red),
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

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        color: Colors.blue.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'For emergency blood requirements, please call the blood bank directly or submit a request.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestButton() {
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
        text: 'Request Blood',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BloodRequestScreen(bloodBank: _bloodBank!),
            ),
          );
        },
      ),
    );
  }
}
