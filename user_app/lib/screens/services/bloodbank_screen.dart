import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'instant_booking_screen.dart';

class BloodbankScreen extends StatefulWidget {
  const BloodbankScreen({super.key});

  @override
  State<BloodbankScreen> createState() => _BloodbankScreenState();
}

class _BloodbankScreenState extends State<BloodbankScreen> {
  late final PatientService _patientService;

  List<Map<String, dynamic>> _bloodBanks = [];
  String _selectedBloodGroup = '';
  bool _isLoading = true;

  final List<Map<String, dynamic>> _bloodGroups = [
    {'id': '', 'name': 'All Groups', 'color': Colors.grey},
    {'id': 'A+', 'name': 'A+', 'color': Colors.red},
    {'id': 'A-', 'name': 'A-', 'color': Colors.red[300]},
    {'id': 'B+', 'name': 'B+', 'color': Colors.blue},
    {'id': 'B-', 'name': 'B-', 'color': Colors.blue[300]},
    {'id': 'AB+', 'name': 'AB+', 'color': Colors.purple},
    {'id': 'AB-', 'name': 'AB-', 'color': Colors.purple[300]},
    {'id': 'O+', 'name': 'O+', 'color': Colors.green},
    {'id': 'O-', 'name': 'O-', 'color': Colors.green[300]},
  ];

  @override
  void initState() {
    super.initState();
    _patientService = PatientService();
    _loadBloodBanks();
  }

  Future<void> _loadBloodBanks() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      debugPrint('Loading blood banks with filter: $_selectedBloodGroup');

      // Search for blood banks with optional blood group filter
      final response = await _patientService.searchBloodBanks(
        bloodGroup: _selectedBloodGroup.isEmpty ? null : _selectedBloodGroup,
        limit: 50,
      );

      debugPrint('Blood banks response: $response');

      // FIX: The API returns data as an array directly, not data.bloodBanks
      final data = response['data'];
      List<Map<String, dynamic>> bloodBanks = [];

      if (data is List) {
        bloodBanks = List<Map<String, dynamic>>.from(data);
      } else if (data is Map && data['bloodBanks'] != null) {
        bloodBanks = List<Map<String, dynamic>>.from(data['bloodBanks']);
      }

      debugPrint('Found ${bloodBanks.length} blood banks');

      if (mounted) {
        setState(() {
          _bloodBanks = bloodBanks;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading blood banks: $e');
      if (mounted) {
        setState(() {
          _bloodBanks = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load blood banks: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Blood Bank'),
          backgroundColor: const Color(0xFFFF416C),
          foregroundColor: Colors.white,
        ),
        body: Column(
          children: [
            _buildEmergencySection(),
            _buildBloodGroupsSection(),
            Expanded(child: _buildBloodBanksList()),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencySection() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bloodtype, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Blood Request',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                SizedBox(height: 4),
                Text(
                  'Find nearby blood banks',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _requestEmergencyBlood(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFFF416C),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Request', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildBloodGroupsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'Blood Groups',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _bloodGroups.length,
            itemBuilder: (context, index) {
              final group = _bloodGroups[index];
              final isSelected = _selectedBloodGroup == group['id'];

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedBloodGroup = group['id']);
                  _loadBloodBanks(); // Reload with filter
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 10),
                  child: Container(
                    width: 45,
                    height: 45,
                    decoration: BoxDecoration(
                      color: isSelected ? group['color'] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(22),
                      border: isSelected
                          ? Border.all(color: group['color'], width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        group['name'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildBloodBanksList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFFF416C)));
    }

    if (_bloodBanks.isEmpty) {
      return const Center(
        child: Text('No blood banks available', style: TextStyle(fontSize: 16)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _selectedBloodGroup.isEmpty
                ? 'Nearby Blood Banks (${_bloodBanks.length})'
                : 'Blood Banks with $_selectedBloodGroup (${_bloodBanks.length})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _bloodBanks.length,
            itemBuilder: (context, index) {
              final bloodBank = _bloodBanks[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () => _requestBlood(bloodBank),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF416C).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.bloodtype,
                                color: Color(0xFFFF416C),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    bloodBank['bankName'] ?? 'Blood Bank',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    bloodBank['address'] ??
                                        'Blood Bank Address',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '24/7',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (bloodBank['bloodStock'] != null) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (bloodBank['bloodStock'] as List)
                                .take(8)
                                .map((stock) {
                              final group = stock['bloodGroup'] ?? '';

                              // Handle both int and string for units
                              int units = 0;
                              if (stock['unitsAvailable'] is int) {
                                units = stock['unitsAvailable'];
                              } else if (stock['unitsAvailable'] is String) {
                                units =
                                    int.tryParse(stock['unitsAvailable']) ?? 0;
                              }

                              // Handle both int and string for price
                              dynamic priceValue = stock['pricePerUnit'] ?? 500;
                              int price = 500;
                              if (priceValue is int) {
                                price = priceValue;
                              } else if (priceValue is String) {
                                price = int.tryParse(priceValue) ?? 500;
                              } else if (priceValue is double) {
                                price = priceValue.toInt();
                              }

                              final isAvailable = units > 0;

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isAvailable
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color:
                                        isAvailable ? Colors.green : Colors.red,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      group,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isAvailable
                                            ? Colors.green[700]
                                            : Colors.red[700],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '₹$price',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isAvailable
                                            ? Colors.green[600]
                                            : Colors.red[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _requestBlood(bloodBank),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF416C),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                                child: const Text('Request Blood',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 14)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _requestEmergencyBlood() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const InstantBookingScreen(serviceType: 'bloodbank'),
      ),
    );
  }

  void _donateBlood() {
    // TODO: Implement blood donation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your interest in blood donation!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _callBloodBank(Map<String, dynamic> bloodBank) {
    // TODO: Implement call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling ${bloodBank['bankName']}...'),
        backgroundColor: const Color(0xFFFF416C),
      ),
    );
  }

  void _requestBlood(Map<String, dynamic> bloodBank) async {
    // Show dialog to select blood group and units
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _BloodRequestDialog(
        bloodBank: bloodBank,
        availableGroups: _bloodGroups.where((g) => g['id'].isNotEmpty).toList(),
      ),
    );

    if (result != null && mounted) {
      try {
        // Create booking for blood bank with price
        final bookingData = {
          'serviceType': 'bloodbank',
          'provider': bloodBank['_id'],
          'bloodGroup': result['bloodGroup'],
          'unitsRequired': result['units'],
          'price': result['totalAmount'], // REQUIRED by backend
          'notes': result['notes'] ??
              'Blood request for ${result['bloodGroup']} (${result['units']} units)',
        };

        await _patientService.createBooking(bookingData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Blood request submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to request blood: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

// Dialog for blood request
class _BloodRequestDialog extends StatefulWidget {
  final Map<String, dynamic> bloodBank;
  final List<Map<String, dynamic>> availableGroups;

  const _BloodRequestDialog({
    required this.bloodBank,
    required this.availableGroups,
  });

  @override
  State<_BloodRequestDialog> createState() => _BloodRequestDialogState();
}

class _BloodRequestDialogState extends State<_BloodRequestDialog> {
  String? _selectedBloodGroup;
  int _units = 1;
  final _notesController = TextEditingController();
  int _pricePerUnit = 0;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int _getPriceForBloodGroup(String bloodGroup) {
    if (widget.bloodBank['bloodStock'] == null) return 500;

    final bloodStock = widget.bloodBank['bloodStock'] as List;
    final stock = bloodStock.firstWhere(
      (s) => s['bloodGroup'] == bloodGroup,
      orElse: () => {'pricePerUnit': 500},
    );

    final priceValue = stock['pricePerUnit'] ?? 500;
    if (priceValue is int) return priceValue;
    if (priceValue is String) return int.tryParse(priceValue) ?? 500;
    if (priceValue is double) return priceValue.toInt();
    return 500;
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = _pricePerUnit * _units;

    return AlertDialog(
      title: Text('Request Blood from ${widget.bloodBank['bankName']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Blood Group:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.availableGroups.map((group) {
                final isSelected = _selectedBloodGroup == group['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedBloodGroup = group['id'];
                      _pricePerUnit = _getPriceForBloodGroup(group['id']);
                    });
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? group['color'] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected
                          ? Border.all(color: group['color'], width: 2)
                          : null,
                    ),
                    child: Text(
                      group['name'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Units Required:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (_units > 1) setState(() => _units--);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: const Color(0xFFFF416C),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_units',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_units < 10) setState(() => _units++);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: const Color(0xFFFF416C),
                ),
              ],
            ),

            // PRICE CALCULATION BOX - MATCHING SCREENSHOT
            if (_selectedBloodGroup != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Price per Unit:',
                            style: TextStyle(fontSize: 14)),
                        Text('₹$_pricePerUnit',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Units:', style: TextStyle(fontSize: 14)),
                        Text('$_units',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          '₹$totalAmount',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Additional Notes (Optional)',
                border: OutlineInputBorder(),
                hintText: 'Enter any special requirements...',
              ),
              maxLines: 3,
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
          onPressed: _selectedBloodGroup == null
              ? null
              : () {
                  Navigator.pop(context, {
                    'bloodGroup': _selectedBloodGroup,
                    'units': _units,
                    'notes': _notesController.text,
                    'pricePerUnit': _pricePerUnit,
                    'totalAmount': totalAmount,
                  });
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF416C),
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit Request'),
        ),
      ],
    );
  }
}
