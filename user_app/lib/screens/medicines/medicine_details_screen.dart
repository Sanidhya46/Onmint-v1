import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../utils/app_colors.dart';

class MedicineDetailsScreen extends StatefulWidget {
  const MedicineDetailsScreen({super.key});

  @override
  State<MedicineDetailsScreen> createState() => _MedicineDetailsScreenState();
}

class _MedicineDetailsScreenState extends State<MedicineDetailsScreen> {
  int _quantity = 1;
  Map<String, dynamic>? _deliveryInfo;
  bool _isLoadingDelivery = false;

  @override
  void initState() {
    super.initState();
    // Load delivery info if this is from an order
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final bookingId = args?['bookingId'] as String?;
      if (bookingId != null) {
        _loadDeliveryInfo(bookingId);
      }
    });
  }

  Future<void> _loadDeliveryInfo(String bookingId) async {
    setState(() => _isLoadingDelivery = true);
    try {
      // Fetch booking details to get delivery status
      // This would call your API client
      // For now, we'll use mock data structure
      setState(() {
        _deliveryInfo = {
          'deliveryStatus': 'out_for_delivery',
          'trackingId': 'TRK123456789',
          'estimatedDelivery': DateTime.now().add(const Duration(hours: 2)),
        };
      });
    } catch (e) {
      print('Error loading delivery info: $e');
    } finally {
      setState(() => _isLoadingDelivery = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final medicine = args?['medicine'] as Map<String, dynamic>?;

    if (medicine == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Medicine Details'),
          backgroundColor: AppColors.pharmacy,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('Medicine not found')),
      );
    }

    final price = (medicine['price'] ?? 0).toDouble();
    final discount = medicine['discount'] ?? 0;
    final originalPrice = discount > 0 ? price / (1 - discount / 100) : price;

    String? imageUrl;
    if (medicine['imagesSigned'] != null &&
        medicine['imagesSigned'] is List &&
        medicine['imagesSigned'].isNotEmpty) {
      imageUrl = medicine['imagesSigned'][0];
    } else if (medicine['imageUrlSigned'] != null && 
        medicine['imageUrlSigned'].toString().isNotEmpty) {
      imageUrl = medicine['imageUrlSigned'];
    }

    if (imageUrl == null || imageUrl.isEmpty) {
      if (medicine['images'] != null &&
          medicine['images'] is List &&
          medicine['images'].isNotEmpty) {
        imageUrl = medicine['images'][0];
      } else if (medicine['imageUrl'] != null && 
          medicine['imageUrl'].toString().isNotEmpty) {
        imageUrl = medicine['imageUrl'];
      }
    }

    if (imageUrl != null && imageUrl.startsWith('/images/')) {
      imageUrl = 'https://api.onmint.in$imageUrl';
    } else if (imageUrl != null && imageUrl.startsWith('/')) {
      imageUrl = 'https://api.onmint.in$imageUrl';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Details'),
        backgroundColor: AppColors.pharmacy,
        foregroundColor: Colors.white,
        actions: [
          Consumer<CartService>(
            builder: (context, cart, child) {
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart),
                    onPressed: () {
                      Navigator.pushNamed(context, '/cart');
                    },
                  ),
                  if (cart.itemCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine Image
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: AppColors.pharmacy.withOpacity(0.1),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.medication,
                                    size: 100, color: AppColors.pharmacy),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(Icons.medication,
                                size: 100, color: AppColors.pharmacy),
                          ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Medicine Name
                        Text(
                          medicine['name'] ?? 'Medicine',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Category
                        if (medicine['category'] != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.pharmacy.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              medicine['category'],
                              style: const TextStyle(
                                color: AppColors.pharmacy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // Price
                        Row(
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.pharmacy,
                              ),
                            ),
                            if (discount > 0) ...[
                              const SizedBox(width: 12),
                              Text(
                                '₹${originalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${discount.toInt()}% OFF',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Description
                        if (medicine['description'] != null) ...[
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            medicine['description'],
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Manufacturer
                        if (medicine['manufacturer'] != null) ...[
                          _buildInfoRow(
                              'Manufacturer', medicine['manufacturer']),
                          const SizedBox(height: 12),
                        ],

                        // Dosage
                        if (medicine['dosage'] != null) ...[
                          _buildInfoRow('Dosage', medicine['dosage']),
                          const SizedBox(height: 12),
                        ],

                        // Stock Status
                        _buildInfoRow(
                          'Stock',
                          medicine['inStock'] == true
                              ? 'In Stock'
                              : 'Out of Stock',
                          valueColor: medicine['inStock'] == true
                              ? Colors.green
                              : Colors.red,
                        ),
                        const SizedBox(height: 12),

                        // Delivery Status (if medicine is from an order with tracking)
                        if (_deliveryInfo != null &&
                            _deliveryInfo!['deliveryStatus'] != null) ...[
                          const SizedBox(height: 24),
                          const Text(
                            'Delivery Tracking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDeliveryTracker(
                              _deliveryInfo!['deliveryStatus']),

                          // Tracking ID
                          if (_deliveryInfo!['trackingId'] != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.local_shipping,
                                      size: 20, color: AppColors.pharmacy),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tracking ID',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          _deliveryInfo!['trackingId'],
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Add to Cart Section
          Container(
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
            child: Row(
              children: [
                // Quantity Selector
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.pharmacy),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (_quantity > 1) {
                            setState(() => _quantity--);
                          }
                        },
                        icon: const Icon(Icons.remove),
                        color: AppColors.pharmacy,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() => _quantity++);
                        },
                        icon: const Icon(Icons.add),
                        color: AppColors.pharmacy,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Add to Cart Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: medicine['inStock'] == true
                        ? () {
                            final cart = Provider.of<CartService>(context,
                                listen: false);
                            for (int i = 0; i < _quantity; i++) {
                              cart.addItem(
                                medicine['_id'] ?? medicine['id'],
                                medicine['name'],
                                price,
                                imageUrl,
                              );
                            }
                            // Removed SnackBar notification
                            setState(() => _quantity = 1);
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.pharmacy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    child: Text(
                      medicine['inStock'] == true
                          ? 'Add to Cart'
                          : 'Out of Stock',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTracker(String status) {
    final stages = [
      {'key': 'ordered', 'label': 'Ordered', 'icon': Icons.shopping_cart},
      {'key': 'packed', 'label': 'Packed', 'icon': Icons.inventory_2},
      {'key': 'shipped', 'label': 'Shipped', 'icon': Icons.local_shipping},
      {
        'key': 'out_for_delivery',
        'label': 'Out for Delivery',
        'icon': Icons.delivery_dining
      },
      {'key': 'delivered', 'label': 'Delivered', 'icon': Icons.check_circle},
    ];

    final currentIndex = stages.indexWhere((s) => s['key'] == status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          ...List.generate(stages.length, (index) {
            final stage = stages[index];
            final isCompleted = index <= currentIndex;
            final isCurrent = index == currentIndex;

            return Column(
              children: [
                Row(
                  children: [
                    // Icon Circle
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            isCompleted ? AppColors.pharmacy : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        stage['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Label
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stage['label'] as String,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isCurrent ? FontWeight.bold : FontWeight.w500,
                              color: isCompleted ? Colors.black87 : Colors.grey,
                            ),
                          ),
                          if (isCurrent)
                            Text(
                              'Current Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.pharmacy,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Checkmark
                    if (isCompleted && !isCurrent)
                      const Icon(
                        Icons.check,
                        color: AppColors.pharmacy,
                        size: 24,
                      ),
                  ],
                ),

                // Connector Line
                if (index < stages.length - 1)
                  Container(
                    margin: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                    width: 2,
                    height: 30,
                    color: isCompleted ? AppColors.pharmacy : Colors.grey[300],
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
