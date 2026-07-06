import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';

class MedicinesManagementScreen extends StatefulWidget {
  const MedicinesManagementScreen({super.key});

  @override
  State<MedicinesManagementScreen> createState() => _MedicinesManagementScreenState();
}

class _MedicinesManagementScreenState extends State<MedicinesManagementScreen> {
  late final OnMintApiClient _apiClient;
  
  List<dynamic> _medicines = [];
  bool _isLoading = true;
  String? _error;
  
  final _searchController = TextEditingController();
  String? _selectedCategory;
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<OnMintApiClient>(context, listen: false);
    _loadMedicines();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicines() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.admin.getAllMedicines(
        page: _currentPage,
        limit: 20,
        search: _searchController.text.isEmpty ? null : _searchController.text,
        category: _selectedCategory,
      );

      if (mounted) {
        setState(() {
          _medicines = response['medicines'] ?? [];
          _totalPages = (response['total'] / 20).ceil();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _showAddMedicineDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMedicineScreen(
          onSaved: _loadMedicines,
        ),
      ),
    );
  }

  void _showEditMedicineDialog(dynamic medicine) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditMedicineScreen(
          medicine: medicine,
          onSaved: _loadMedicines,
        ),
      ),
    );
  }

  Future<void> _deleteMedicine(String medicineId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiClient.admin.deleteMedicine(medicineId);
      ToastUtils.showSuccess('Medicine deleted successfully');
      _loadMedicines();
    } catch (e) {
      ToastUtils.showError('Failed to delete medicine: ${e.toString()}');
    }
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filter by Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'All',
                'Analgesics',
                'Antibiotics',
                'Antacids',
                'Vitamins',
                'Supplements',
                'Pain Relief',
                'Cold & Flu',
                'Digestive Health',
                'Skin Care',
              ].map((category) {
                final isSelected = category == 'All' 
                    ? _selectedCategory == null 
                    : _selectedCategory == category;
                return FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = category == 'All' ? null : category;
                      _currentPage = 1;
                    });
                    Navigator.pop(context);
                    _loadMedicines();
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicines'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
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
                          _loadMedicines();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onSubmitted: (_) => _loadMedicines(),
            ),
          ),

          // Filter Chip
          if (_selectedCategory != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Chip(
                    label: Text(_selectedCategory!),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedCategory = null;
                        _currentPage = 1;
                      });
                      _loadMedicines();
                    },
                  ),
                ],
              ),
            ),

          // Medicines List
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                    ? CustomErrorWidget(
                        message: _error!,
                        onRetry: _loadMedicines,
                      )
                    : _medicines.isEmpty
                        ? const EmptyStateWidget(
                            title: 'No Medicines',
                            message: 'No medicines found. Add your first medicine!',
                            icon: Icons.medication,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadMedicines,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _medicines.length,
                              itemBuilder: (context, index) {
                                final medicine = _medicines[index];
                                return _buildMedicineCard(medicine);
                              },
                            ),
                          ),
          ),

          // Pagination
          if (_totalPages > 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() => _currentPage--);
                            _loadMedicines();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                    label: const Text('Previous'),
                  ),
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _currentPage < _totalPages
                        ? () {
                            setState(() => _currentPage++);
                            _loadMedicines();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                    label: const Text('Next'),
                    style: ElevatedButton.styleFrom(
                      // iconAlignment is not a valid parameter, removing it
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMedicineDialog,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Medicine', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildMedicineCard(dynamic medicine) {
    final stock = medicine['stock'] ?? 0;
    final lowStock = stock < 10;
    final isActive = medicine['isActive'] ?? true;
    
    // Get first image URL (prioritize signed URL)
    String? imageUrl;
    if (medicine['imagesSigned'] != null && medicine['imagesSigned'] is List && (medicine['imagesSigned'] as List).isNotEmpty) {
      imageUrl = medicine['imagesSigned'][0];
    } else if (medicine['imageUrlSigned'] != null) {
      imageUrl = medicine['imageUrlSigned'];
    } else if (medicine['images'] != null && medicine['images'] is List && (medicine['images'] as List).isNotEmpty) {
      // Fallback to original URL
      imageUrl = medicine['images'][0];
    } else if (medicine['imageUrl'] != null) {
      // Fallback to original imageUrl
      imageUrl = medicine['imageUrl'];
    }

    if (imageUrl != null && imageUrl.startsWith('/images/')) {
      imageUrl = 'https://api.onmint.in$imageUrl';
    } else if (imageUrl != null && imageUrl.startsWith('/')) {
      imageUrl = 'https://api.onmint.in$imageUrl';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showEditMedicineDialog(medicine),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medicine Image or Icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: lowStock
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl == null
                        ? Icon(
                            Icons.medication,
                            color: lowStock ? Colors.red : Colors.green,
                            size: 32,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  
                  // Medicine Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine['name'] ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (medicine['genericName'] != null && 
                            medicine['genericName'].toString().isNotEmpty)
                          Text(
                            medicine['genericName'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${medicine['dosageForm']} ${medicine['strength'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // More Options
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditMedicineDialog(medicine);
                      } else if (value == 'delete') {
                        _deleteMedicine(medicine['_id']);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Price and Stock Row
              Row(
                children: [
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.currency_rupee,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        Text(
                          '${medicine['price']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Stock
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: lowStock ? Colors.red : Colors.green,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stock: $stock',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      medicine['category'] ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Active Status
                  if (!isActive)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Inactive',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              
              // Manufacturer
              if (medicine['manufacturer'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'By ${medicine['manufacturer']}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Add/Edit Medicine Screen
class AddEditMedicineScreen extends StatefulWidget {
  final dynamic medicine;
  final VoidCallback onSaved;

  const AddEditMedicineScreen({
    super.key,
    this.medicine,
    required this.onSaved,
  });

  @override
  State<AddEditMedicineScreen> createState() => _AddEditMedicineScreenState();
}

class _AddEditMedicineScreenState extends State<AddEditMedicineScreen> {
  late final OnMintApiClient _apiClient;
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  List<String> _existingImageUrls = [];
  
  // Controllers
  final _nameController = TextEditingController();
  final _genericNameController = TextEditingController();
  final _manufacturerController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _strengthController = TextEditingController();
  final _packagingController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedDosageForm;
  bool _requiresPrescription = false;

  final List<String> _categories = [
    'Pain Relief',
    'Antibiotics',
    'Vitamins',
    'Diabetes',
    'Heart',
    'Digestive',
    'Respiratory',
    'Skin Care',
    'Other',
  ];

  final List<String> _dosageForms = [
    'Tablet',
    'Capsule',
    'Syrup',
    'Injection',
    'Ointment',
    'Cream',
    'Drops',
    'Inhaler',
  ];

  @override
  void initState() {
    super.initState();
    _apiClient = Provider.of<OnMintApiClient>(context, listen: false);
    
    if (widget.medicine != null) {
      _loadMedicineData();
    }
  }

  void _loadMedicineData() {
    final medicine = widget.medicine;
    _nameController.text = medicine['name'] ?? '';
    _genericNameController.text = medicine['genericName'] ?? '';
    _manufacturerController.text = medicine['manufacturer'] ?? '';
    _descriptionController.text = medicine['description'] ?? '';
    _priceController.text = medicine['price']?.toString() ?? '';
    _discountedPriceController.text = medicine['discountedPrice']?.toString() ?? '';
    _stockController.text = medicine['stock']?.toString() ?? '';
    _strengthController.text = medicine['strength'] ?? '';
    _packagingController.text = medicine['packaging'] ?? '';
    _selectedCategory = medicine['category'];
    _selectedDosageForm = medicine['dosageForm'];
    _requiresPrescription = medicine['requiresPrescription'] ?? false;
    
    // Load existing images (prioritize signed URLs)
    if (medicine['imagesSigned'] != null && medicine['imagesSigned'] is List) {
      _existingImageUrls = List<String>.from(medicine['imagesSigned']);
    } else if (medicine['images'] != null && medicine['images'] is List) {
      _existingImageUrls = (medicine['images'] as List).map((url) {
        return url.toString();
      }).toList();
    } else if (medicine['imageUrlSigned'] != null) {
      _existingImageUrls = [medicine['imageUrlSigned']];
    } else if (medicine['imageUrl'] != null) {
      _existingImageUrls = [medicine['imageUrl']];
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      
      if (images.isNotEmpty) {
        final totalImages = _selectedImages.length + _existingImageUrls.length + images.length;
        
        if (totalImages > 5) {
          ToastUtils.showError('Maximum 5 images allowed');
          return;
        }
        
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } catch (e) {
      ToastUtils.showError('Failed to pick images: ${e.toString()}');
    }
  }

  void _removeSelectedImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _genericNameController.dispose();
    _manufacturerController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _stockController.dispose();
    _strengthController.dispose();
    _packagingController.dispose();
    super.dispose();
  }

  Future<void> _saveMedicine() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategory == null) {
      ToastUtils.showError('Please select a category');
      return;
    }

    if (_selectedDosageForm == null) {
      ToastUtils.showError('Please select a dosage form');
      return;
    }

    // Validate images (at least 1, max 5)
    final totalImages = _selectedImages.length + _existingImageUrls.length;
    if (totalImages == 0) {
      ToastUtils.showError('Please add at least 1 image');
      return;
    }
    if (totalImages > 5) {
      ToastUtils.showError('Maximum 5 images allowed');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': _nameController.text.trim(),
        'genericName': _genericNameController.text.trim(),
        'manufacturer': _manufacturerController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'discountedPrice': _discountedPriceController.text.isEmpty 
            ? null 
            : double.parse(_discountedPriceController.text),
        'stock': int.parse(_stockController.text),
        'category': _selectedCategory,
        'dosageForm': _selectedDosageForm,
        'strength': _strengthController.text.trim(),
        'packaging': _packagingController.text.trim(),
        'requiresPrescription': _requiresPrescription,
      };

      // Remove null values
      data.removeWhere((key, value) => value == null);

      if (widget.medicine == null) {
        // Create new medicine with images (using XFile objects for web compatibility)
        await _apiClient.admin.createMedicine(
          data, 
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
        ToastUtils.showSuccess('Medicine added successfully');
      } else {
        // Update medicine
        // If there are existing images, we need to keep them
        if (_existingImageUrls.isNotEmpty) {
          data['existingImages'] = _existingImageUrls;
        }
        await _apiClient.admin.updateMedicine(
          widget.medicine['_id'], 
          data, 
          imageFiles: _selectedImages.isNotEmpty ? _selectedImages : null,
        );
        ToastUtils.showSuccess('Medicine updated successfully');
      }

      widget.onSaved();
      Navigator.pop(context);
    } catch (e) {
      ToastUtils.showError('Failed to save medicine: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.medicine == null ? 'Add Medicine' : 'Edit Medicine'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter medicine name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Generic Name
            TextFormField(
              controller: _genericNameController,
              decoration: const InputDecoration(
                labelText: 'Generic Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.science),
              ),
            ),
            const SizedBox(height: 16),

            // Manufacturer
            TextFormField(
              controller: _manufacturerController,
              decoration: const InputDecoration(
                labelText: 'Manufacturer *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter manufacturer';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedCategory = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Dosage Form Dropdown
            DropdownButtonFormField<String>(
              value: _selectedDosageForm,
              decoration: const InputDecoration(
                labelText: 'Dosage Form *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_services),
              ),
              items: _dosageForms.map((form) {
                return DropdownMenuItem(
                  value: form,
                  child: Text(form),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => _selectedDosageForm = value);
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a dosage form';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Strength
            TextFormField(
              controller: _strengthController,
              decoration: const InputDecoration(
                labelText: 'Strength (e.g., 500mg, 10ml)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.fitness_center),
              ),
            ),
            const SizedBox(height: 16),

            // Packaging
            TextFormField(
              controller: _packagingController,
              decoration: const InputDecoration(
                labelText: 'Packaging (e.g., Strip, Bottle)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory_2),
              ),
            ),
            const SizedBox(height: 16),

            // Price
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price (₹) *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_rupee),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Discounted Price
            TextFormField(
              controller: _discountedPriceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Discounted Price (₹)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.discount),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Stock
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter stock quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // Requires Prescription
            SwitchListTile(
              title: const Text('Requires Prescription'),
              subtitle: const Text('Enable if this medicine needs a prescription'),
              value: _requiresPrescription,
              onChanged: (value) {
                setState(() => _requiresPrescription = value);
              },
              activeColor: AppColors.primary,
            ),
            const SizedBox(height: 24),

            // Image Upload Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Medicine Images *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_selectedImages.length + _existingImageUrls.length}/5',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add 1-5 images of the medicine',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Image Grid
                  if (_existingImageUrls.isNotEmpty || _selectedImages.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // Existing images
                        ..._existingImageUrls.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                  image: DecorationImage(
                                    image: NetworkImage(entry.value),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeExistingImage(entry.key),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                        
                        // Selected new images
                        ..._selectedImages.asMap().entries.map((entry) {
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    entry.value.path,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey.shade200,
                                        child: const Icon(
                                          Icons.image_not_supported,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeSelectedImage(entry.key),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Add Images Button
                  if (_selectedImages.length + _existingImageUrls.length < 5)
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add Images'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                      ),
                    ),
                  
                  // Validation message
                  if (_selectedImages.isEmpty && _existingImageUrls.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'At least 1 image is required',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveMedicine,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      widget.medicine == null ? 'Add Medicine' : 'Update Medicine',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
