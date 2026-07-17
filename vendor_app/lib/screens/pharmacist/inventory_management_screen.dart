import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_client/api_client.dart';
import 'package:auth_service/auth_service.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class InventoryManagementScreen extends StatefulWidget {
  const InventoryManagementScreen({super.key});

  @override
  State<InventoryManagementScreen> createState() => _InventoryManagementScreenState();
}

class _InventoryManagementScreenState extends State<InventoryManagementScreen> {
  final _apiClient = OnMintApiClient();
  final _searchController = TextEditingController();
  
  List<dynamic> _medicines = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInventory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiClient.initialize();
      final response = await _apiClient.pharmacist.getInventory();

      setState(() {
        _medicines = (response['medicines'] as List?) ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _showAddMedicineDialog() {
    final nameController = TextEditingController();
    final genericNameController = TextEditingController();
    final manufacturerController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final categoryController = TextEditingController();
    bool requiresPrescription = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Medicine'),
          content: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: genericNameController,
                  decoration: const InputDecoration(
                    labelText: 'Generic Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹) *',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Requires Prescription'),
                  value: requiresPrescription,
                  onChanged: (value) {
                    setDialogState(() {
                      requiresPrescription = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || 
                    priceController.text.isEmpty || 
                    stockController.text.isEmpty) {
                  ToastUtils.showError('Please fill required fields');
                  return;
                }

                Navigator.pop(context);
                await _addMedicine({
                  'name': nameController.text,
                  'genericName': genericNameController.text,
                  'manufacturer': manufacturerController.text,
                  'price': double.parse(priceController.text),
                  'stock': int.parse(stockController.text),
                  'category': categoryController.text,
                  'requiresPrescription': requiresPrescription,
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMedicineDialog(dynamic medicine) {
    final nameController = TextEditingController(text: medicine['name']);
    final genericNameController = TextEditingController(text: medicine['genericName']);
    final manufacturerController = TextEditingController(text: medicine['manufacturer']);
    final priceController = TextEditingController(text: medicine['price'].toString());
    final stockController = TextEditingController(text: medicine['stock'].toString());
    final categoryController = TextEditingController(text: medicine['category']);
    bool requiresPrescription = medicine['requiresPrescription'] ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Medicine'),
          content: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medicine Name *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: genericNameController,
                  decoration: const InputDecoration(
                    labelText: 'Generic Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: manufacturerController,
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (₹) *',
                    border: OutlineInputBorder(),
                    prefixText: '₹ ',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  title: const Text('Requires Prescription'),
                  value: requiresPrescription,
                  onChanged: (value) {
                    setDialogState(() {
                      requiresPrescription = value ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || 
                    priceController.text.isEmpty || 
                    stockController.text.isEmpty) {
                  ToastUtils.showError('Please fill required fields');
                  return;
                }

                Navigator.pop(context);
                await _updateMedicine(medicine['_id'], {
                  'name': nameController.text,
                  'genericName': genericNameController.text,
                  'manufacturer': manufacturerController.text,
                  'price': double.parse(priceController.text),
                  'stock': int.parse(stockController.text),
                  'category': categoryController.text,
                  'requiresPrescription': requiresPrescription,
                });
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateStockDialog(dynamic medicine) {
    final stockController = TextEditingController(
      text: medicine['stock'].toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Stock - ${medicine['name']}'),
        content: TextField(
          controller: stockController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Stock Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateStock(
                medicine['_id'],
                int.parse(stockController.text),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _addMedicine(Map<String, dynamic> data) async {
    try {
      await _apiClient.pharmacist.addMedicine(data);
      ToastUtils.showSuccess('Medicine added successfully');
      _loadInventory();
    } catch (e) {
      ToastUtils.showError(e.toString());
    }
  }

  Future<void> _updateMedicine(String id, Map<String, dynamic> data) async {
    try {
      await _apiClient.pharmacist.updateMedicine(id, data);
      ToastUtils.showSuccess('Medicine updated successfully');
      _loadInventory();
    } catch (e) {
      ToastUtils.showError(e.toString());
    }
  }

  Future<void> _updateStock(String id, int stock) async {
    try {
      await _apiClient.pharmacist.updateStock(id, stock);
      ToastUtils.showSuccess('Stock updated successfully');
      _loadInventory();
    } catch (e) {
      ToastUtils.showError(e.toString());
    }
  }

  Future<void> _deleteMedicine(String id) async {
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
      await _apiClient.pharmacist.deleteMedicine(id);
      ToastUtils.showSuccess('Medicine deleted successfully');
      _loadInventory();
    } catch (e) {
      ToastUtils.showError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddMedicineDialog,
            tooltip: 'Add Medicine',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: CustomTextField(
              controller: _searchController,
              label: 'Search',
              hint: 'Search medicines',
              prefixIcon: Icons.search,
              onChanged: (value) {
                setState(() {});
              },
            ),
          ),

          // Medicines List
          Expanded(
            child: _isLoading
                ? const LoadingWidget()
                : _error != null
                    ? CustomErrorWidget(
                        message: _error!,
                        onRetry: _loadInventory,
                      )
                    : _medicines.isEmpty
                        ? const EmptyStateWidget(
                            title: 'No Medicines',
                            message: 'No medicines in inventory',
                            icon: Icons.medication,
                          )
                        : RefreshIndicator(
                            onRefresh: _loadInventory,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _medicines.length,
                              itemBuilder: (context, index) {
                                final medicine = _medicines[index];
                                final stock = medicine['stock'] ?? 0;
                                final lowStock = stock < 10;
                                
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: lowStock
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.medication,
                                        color: lowStock ? Colors.red : Colors.green,
                                      ),
                                    ),
                                    title: Text(
                                      medicine['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (medicine['genericName'] != null)
                                          Text(medicine['genericName']),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '₹${medicine['price']}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: lowStock
                                                    ? Colors.red
                                                    : Colors.green,
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                'Stock: $stock',
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
                                    trailing: PopupMenuButton(
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'stock',
                                          child: Row(
                                            children: [
                                              Icon(Icons.inventory, size: 20),
                                              SizedBox(width: 8),
                                              Text('Update Stock'),
                                            ],
                                          ),
                                        ),
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
                                        if (value == 'stock') {
                                          _showUpdateStockDialog(medicine);
                                        } else if (value == 'edit') {
                                          _showEditMedicineDialog(medicine);
                                        } else if (value == 'delete') {
                                          _deleteMedicine(medicine['_id']);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddMedicineDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
