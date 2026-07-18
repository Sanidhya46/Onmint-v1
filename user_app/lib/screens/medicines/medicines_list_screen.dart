import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import '../../services/cart_service.dart';
import '../../utils/app_colors.dart';
import 'widgets/cart_floating_bar.dart';

class MedicinesListScreen extends StatefulWidget {
  const MedicinesListScreen({super.key});

  @override
  State<MedicinesListScreen> createState() => _MedicinesListScreenState();
}

class _MedicinesListScreenState extends State<MedicinesListScreen> {
  final _searchController = TextEditingController();
  final _apiClient = OnMintApiClient();

  List<Map<String, dynamic>> _medicines = [];
  List<Map<String, dynamic>> _filteredMedicines = [];
  bool _isLoading = true;
  String? _category;
  String? _searchQuery;
  String _sortBy = 'name'; // name, price_low, price_high, discount

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _category = args?['category'];
    _loadMedicines();
    
    // Fetch backend cart once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CartService>(context, listen: false).fetchBackendCart();
    });
  }

  Future<void> _loadMedicines() async {
    setState(() => _isLoading = true);

    try {
      await _apiClient.initialize();
      final response = await _apiClient.patient.searchMedicines(
        search: _searchQuery,
        category: _category,
        limit: 50,
      );

      setState(() {
        _medicines = List<Map<String, dynamic>>.from(response['data'] ?? []);
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medicines: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    _filteredMedicines = List.from(_medicines);

    // Apply sorting
    switch (_sortBy) {
      case 'price_low':
        _filteredMedicines.sort((a, b) =>
            ((a['price'] ?? 0) as num).compareTo((b['price'] ?? 0) as num));
        break;
      case 'price_high':
        _filteredMedicines.sort((a, b) =>
            ((b['price'] ?? 0) as num).compareTo((a['price'] ?? 0) as num));
        break;
      case 'discount':
        _filteredMedicines.sort((a, b) => ((b['discount'] ?? 0) as num)
            .compareTo((a['discount'] ?? 0) as num));
        break;
      case 'name':
      default:
        _filteredMedicines.sort((a, b) => (a['name'] ?? '')
            .toString()
            .compareTo((b['name'] ?? '').toString()));
        break;
    }
  }

  void _searchMedicines(String query) {
    setState(() {
      _searchQuery = query.isEmpty ? null : query;
    });
    _loadMedicines();
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sort By',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Name (A-Z)'),
                trailing: _sortBy == 'name'
                    ? const Icon(Icons.check, color: AppColors.pharmacy)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'name';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Price: Low to High'),
                trailing: _sortBy == 'price_low'
                    ? const Icon(Icons.check, color: AppColors.pharmacy)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'price_low';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text('Price: High to Low'),
                trailing: _sortBy == 'price_high'
                    ? const Icon(Icons.check, color: AppColors.pharmacy)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'price_high';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.local_offer),
                title: const Text('Discount: High to Low'),
                trailing: _sortBy == 'discount'
                    ? const Icon(Icons.check, color: AppColors.pharmacy)
                    : null,
                onTap: () {
                  setState(() {
                    _sortBy = 'discount';
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addToCart(Map<String, dynamic> medicine) {
    final cart = Provider.of<CartService>(context, listen: false);
    cart.addItem(
      medicine['_id'] ?? medicine['id'],
      medicine['name'],
      (medicine['price'] ?? 0).toDouble(),
      medicine['images']?[0],
    );

    // Removed SnackBar notification
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_category ?? 'Medicines'),
        backgroundColor: AppColors.pharmacy,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Sort & Filter',
          ),
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
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medicines...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchMedicines('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _searchMedicines,
            ),
          ),

          // Medicines Grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMedicines.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medication_outlined,
                                size: 80, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No medicines found',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _filteredMedicines.length,
                        itemBuilder: (context, index) {
                          final medicine = _filteredMedicines[index];
                          return _buildMedicineCard(medicine);
                        },
                      ),
          ),
          

        ],
      )),
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
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

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/medicine-details',
            arguments: {'medicine': medicine},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine Image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.pharmacy.withOpacity(0.1),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(Icons.medication,
                                  size: 50, color: AppColors.pharmacy),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.medication,
                            size: 50, color: AppColors.pharmacy),
                      ),
              ),
            ),

            // Medicine Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['name'] ?? 'Medicine',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.pharmacy,
                          ),
                        ),
                        if (discount > 0) ...[
                          const SizedBox(width: 4),
                          Text(
                            '₹${originalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Consumer<CartService>(
                      builder: (context, cart, child) {
                        final medicineId = medicine['_id'] ?? medicine['id'];
                        final cartItem = cart.items[medicineId];
                        final quantity = cartItem?.quantity ?? 0;

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _addToCart(medicine),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red[400],
                                  side: BorderSide(color: Colors.red[400]!),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                                child: const Text(
                                  'ADD',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (quantity > 0) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/cart'),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Icon(
                                      Icons.shopping_cart_outlined,
                                      color: Colors.grey[700],
                                      size: 24,
                                    ),
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$quantity',
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
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
