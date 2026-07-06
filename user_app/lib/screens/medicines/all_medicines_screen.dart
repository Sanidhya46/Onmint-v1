import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';

class AllMedicinesScreen extends StatefulWidget {
  final String? category;

  const AllMedicinesScreen({super.key, this.category});

  @override
  State<AllMedicinesScreen> createState() => _AllMedicinesScreenState();
}

class _AllMedicinesScreenState extends State<AllMedicinesScreen>
    with SingleTickerProviderStateMixin {
  final PatientService _patientService = PatientService();
  late TabController _tabController;

  List<Map<String, dynamic>> _allMedicines = [];
  List<Map<String, dynamic>> _filteredMedicines = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _selectedSort = 'Popular';
  String _searchQuery = '';

  final List<String> _categories = [
    'All',
    'Pain Relief',
    'Vitamins',
    'Antibiotics',
    'Diabetes',
    'Heart Care',
    'Skin Care',
    'Respiratory',
    'Digestive',
  ];

  final List<String> _sortOptions = [
    'Popular',
    'Price: Low to High',
    'Price: High to Low',
    'Discount',
    'Name: A-Z',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMedicines();

    // Set initial tab based on category argument
    if (widget.category != null) {
      switch (widget.category) {
        case 'featured':
          _tabController.index = 0;
          break;
        case 'popular':
          _tabController.index = 1;
          break;
        case 'discount':
          _tabController.index = 2;
          break;
        case 'trending':
          _tabController.index = 3;
          break;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final response = await _patientService.searchMedicines(limit: 100);
      final medicines = response['data'] ?? [];

      if (mounted) {
        setState(() {
          _allMedicines = List<Map<String, dynamic>>.from(medicines);
          _applyFilters();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading medicines: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allMedicines);

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((m) {
        final category = m['category']?.toString();
        return category != null && category == _selectedCategory;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((m) {
        final name = m['name']?.toString().toLowerCase() ?? '';
        final genericName = m['genericName']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || genericName.contains(query);
      }).toList();
    }

    // Apply sorting
    switch (_selectedSort) {
      case 'Price: Low to High':
        filtered.sort((a, b) => (a['discountedPrice'] ?? a['price'] ?? 0)
            .compareTo(b['discountedPrice'] ?? b['price'] ?? 0));
        break;
      case 'Price: High to Low':
        filtered.sort((a, b) => (b['discountedPrice'] ?? b['price'] ?? 0)
            .compareTo(a['discountedPrice'] ?? a['price'] ?? 0));
        break;
      case 'Discount':
        filtered.sort((a, b) {
          final aDiscount = a['discountedPrice'] != null
              ? ((a['price'] - a['discountedPrice']) / a['price'] * 100)
              : 0;
          final bDiscount = b['discountedPrice'] != null
              ? ((b['price'] - b['discountedPrice']) / b['price'] * 100)
              : 0;
          return bDiscount.compareTo(aDiscount);
        });
        break;
      case 'Name: A-Z':
        filtered.sort((a, b) => (a['name'] ?? '')
            .toString()
            .compareTo((b['name'] ?? '').toString()));
        break;
    }

    setState(() {
      _filteredMedicines = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              floating: true,
              pinned: true,
              snap: false,
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                'All Medicines',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Color(0xFF667EEA)),
                  onPressed: () {
                    Navigator.pushNamed(context, '/cart');
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(160),
                child: Column(
                  children: [
                    // Search Bar
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _applyFilters();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search medicines...',
                          prefixIcon: const Icon(Icons.search,
                              color: Color(0xFF667EEA)),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                      _applyFilters();
                                    });
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),

                    // Filter Chips
                    Container(
                      height: 50,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Category Filter
                          Expanded(
                            child: GestureDetector(
                              onTap: _showCategoryFilter,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF667EEA).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF667EEA)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.category,
                                        size: 18, color: Color(0xFF667EEA)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _selectedCategory,
                                        style: const TextStyle(
                                          color: Color(0xFF667EEA),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down,
                                        size: 18, color: Color(0xFF667EEA)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sort Filter
                          Expanded(
                            child: GestureDetector(
                              onTap: _showSortFilter,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF10B981).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF10B981)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.sort,
                                        size: 18, color: Color(0xFF10B981)),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        _selectedSort,
                                        style: const TextStyle(
                                          color: Color(0xFF10B981),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.arrow_drop_down,
                                        size: 18, color: Color(0xFF10B981)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Tabs
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF667EEA),
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: const Color(0xFF667EEA),
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        tabs: const [
                          Tab(text: 'Featured'),
                          Tab(text: 'Popular'),
                          Tab(text: 'Discount'),
                          Tab(text: 'Trending'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildMedicineGrid(_filteredMedicines),
                  _buildMedicineGrid(_filteredMedicines),
                  _buildMedicineGrid(_getDiscountedMedicines()),
                  _buildMedicineGrid(_filteredMedicines),
                ],
              ),
      ),
    );
  }

  List<Map<String, dynamic>> _getDiscountedMedicines() {
    return _filteredMedicines
        .where((m) => m['discountedPrice'] != null)
        .toList();
  }

  Widget _buildMedicineGrid(List<Map<String, dynamic>> medicines) {
    if (medicines.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medication_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No medicines found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.57, // 160/280 = 0.57 for phone-friendly cards
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: medicines.length,
      itemBuilder: (context, index) {
        return _buildMedicineCard(medicines[index]);
      },
    );
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final name = medicine['name']?.toString() ?? 'Medicine';
    final price = medicine['discountedPrice'] ?? medicine['price'] ?? 0;
    final originalPrice = medicine['price'] ?? price;
    final hasDiscount =
        medicine['discountedPrice'] != null && originalPrice > price;
    final discountPercent = hasDiscount
        ? ((originalPrice - price) / originalPrice * 100).round()
        : 0;
    final medicineId = medicine['_id']?.toString() ?? '';
    final manufacturer = medicine['manufacturer']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        if (medicineId.isNotEmpty) {
          Navigator.pushNamed(
            context,
            '/medicine-detail',
            arguments: medicineId,
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with discount badge
            Stack(
              children: [
                Container(
                  height: 100, // Reduced from 140 to match home page
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: _buildMedicineImage(medicine),
                  ),
                ),
                // Discount badge
                if (hasDiscount)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$discountPercent% OFF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Stock status
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'In Stock',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Medicine details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Manufacturer
                    if (manufacturer.isNotEmpty)
                      Text(
                        manufacturer,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const Spacer(),

                    // Rating
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: Color(0xFFFFD700),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '4.5',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price
                    Row(
                      children: [
                        Text(
                          '₹$price',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 6),
                          Text(
                            '₹$originalPrice',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (medicineId.isNotEmpty) {
                                Navigator.pushNamed(
                                  context,
                                  '/medicine-detail',
                                  arguments: medicineId,
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text(
                              'Buy',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF667EEA),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: IconButton(
                            onPressed: () {
                              // Removed SnackBar notification
                            },
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Color(0xFF667EEA),
                              size: 18,
                            ),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                          ),
                        ),
                      ],
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

  Widget _buildMedicineImage(Map<String, dynamic> medicine) {
    // Get image URL - prioritize signed URLs
    String? imageUrl;
    if (medicine['imagesSigned'] != null &&
        medicine['imagesSigned'] is List &&
        medicine['imagesSigned'].isNotEmpty) {
      imageUrl = medicine['imagesSigned'][0];
    } else if (medicine['imageUrlSigned'] != null) {
      imageUrl = medicine['imageUrlSigned'];
    }
    
    if (imageUrl == null || imageUrl.isEmpty) {
      if (medicine['images'] != null &&
          medicine['images'] is List &&
          medicine['images'].isNotEmpty) {
        imageUrl = medicine['images'][0];
      } else if (medicine['imageUrl'] != null) {
        imageUrl = medicine['imageUrl'];
      }
    }

    // Fix relative URLs
    if (imageUrl != null && imageUrl.startsWith('/images/')) {
      imageUrl = 'https://api.onmint.in$imageUrl';
    } else if (imageUrl != null && imageUrl.startsWith('/')) {
      imageUrl = 'https://api.onmint.in$imageUrl';
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: 140,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.medication,
              size: 50,
              color: Colors.grey[400],
            ),
          );
        },
      );
    }

    return Center(
      child: Icon(
        Icons.medication,
        size: 50,
        color: Colors.grey[400],
      ),
    );
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return ListTile(
                    leading: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? const Color(0xFF667EEA) : Colors.grey,
                    ),
                    title: Text(
                      category,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color:
                            isSelected ? const Color(0xFF667EEA) : Colors.black,
                      ),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _applyFilters();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sort By',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ..._sortOptions.map((option) {
              final isSelected = option == _selectedSort;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? const Color(0xFF10B981) : Colors.grey,
                ),
                title: Text(
                  option,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected ? const Color(0xFF10B981) : Colors.black,
                  ),
                ),
                onTap: () {
                  setState(() {
                    _selectedSort = option;
                    _applyFilters();
                  });
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
