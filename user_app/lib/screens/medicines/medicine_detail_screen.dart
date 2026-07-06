import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import '../../services/cart_service.dart';
import 'cart_screen.dart';

class MedicineDetailScreen extends StatefulWidget {
  final String medicineId;

  const MedicineDetailScreen({super.key, required this.medicineId});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  final _apiClient = OnMintApiClient();
  final _cartService = CartService();
  Map<String, dynamic>? _medicine;
  bool _isLoading = true;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadMedicine();
  }

  Future<void> _loadMedicine() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await _apiClient.initialize();

      // Use getMedicineById instead of search
      final PatientService patientService = PatientService();
      final medicine = await patientService.getMedicineById(widget.medicineId);

      if (mounted) {
        setState(() {
          _medicine = medicine;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medicine: ${e.toString()}')),
        );
      }
    }
  }

  void _addToCart() {
    if (_medicine == null) return;

    for (int i = 0; i < _quantity; i++) {
      _cartService.addItem(
        _medicine!['_id'],
        _medicine!['name'],
        (_medicine!['discountedPrice'] ?? _medicine!['price']).toDouble(),
        _medicine!['imagesSigned']?.isNotEmpty == true
            ? _medicine!['imagesSigned'][0]
            : null,
      );
    }

    // Removed SnackBar notification
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
              if (_cartService.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_cartService.itemCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _medicine == null
              ? const Center(child: Text('Medicine not found'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Medicine Image
                      if (_medicine!['imagesSigned']?.isNotEmpty == true)
                        Container(
                          height: 300,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: Image.network(
                            _medicine!['imagesSigned'][0],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          ),
                        )
                      else
                        Container(
                          height: 300,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.medication, size: 100),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Name
                            Text(
                              _medicine!['name'] ?? '',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Generic Name
                            if (_medicine!['genericName'] != null)
                              Text(
                                _medicine!['genericName'],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Price
                            Row(
                              children: [
                                Text(
                                  '₹${_medicine!['discountedPrice'] ?? _medicine!['price']}',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                                if (_medicine!['discountedPrice'] != null) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    '₹${_medicine!['price']}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${((((_medicine!['price'] - _medicine!['discountedPrice']) / _medicine!['price']) * 100).round())}% OFF',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Stock Status
                            Row(
                              children: [
                                Icon(
                                  _medicine!['stock'] > 0
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: _medicine!['stock'] > 0
                                      ? Colors.green
                                      : Colors.red,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _medicine!['stock'] > 0
                                      ? 'In Stock (${_medicine!['stock']} available)'
                                      : 'Out of Stock',
                                  style: TextStyle(
                                    color: _medicine!['stock'] > 0
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Details
                            _buildDetailRow(
                                'Manufacturer', _medicine!['manufacturer']),
                            _buildDetailRow('Category', _medicine!['category']),
                            _buildDetailRow(
                                'Dosage Form', _medicine!['dosageForm']),
                            _buildDetailRow('Strength', _medicine!['strength']),
                            _buildDetailRow(
                                'Packaging', _medicine!['packaging']),

                            if (_medicine!['requiresPrescription'] == true)
                              Container(
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.warning, color: Colors.orange),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Prescription Required',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            // Description
                            if (_medicine!['description'] != null) ...[
                              const Text(
                                'Description',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _medicine!['description'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: _medicine != null && _medicine!['stock'] > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity Selector
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () => setState(() => _quantity--)
                              : null,
                        ),
                        Text(
                          '$_quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _quantity < _medicine!['stock']
                              ? () => setState(() => _quantity++)
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Add to Cart Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'ADD TO CART',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
