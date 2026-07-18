import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import '../../utils/app_colors.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  late final OnMintApiClient _apiClient;
  Map<String, dynamic>? _bookingData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _apiClient = OnMintApiClient();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    setState(() => _isLoading = true);

    try {
      await _apiClient.initialize();

      // Try realtime booking first
      try {
        final realtimeData = await _apiClient.patient
            .getRealtimeBookingDetails(widget.bookingId);
        setState(() {
          _bookingData = realtimeData;
          _isLoading = false;
        });
        return;
      } catch (e) {
        print('Not a realtime booking, trying regular booking: $e');
      }

      // Fallback to regular booking
      final booking =
          await _apiClient.patient.getBookingDetails(widget.bookingId);
      setState(() {
        _bookingData = booking.toJson();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading booking details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(top: false, bottom: true, child: const Center(
            child: CircularProgressIndicator(color: Color(0xFF4CAF50)))),
      );
    }

    if (_bookingData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        body: SafeArea(top: false, bottom: true, child: const Center(child: Text('Booking not found'))),
      );
    }

    final serviceType = _bookingData!['serviceType'] ?? '';
    final status = _bookingData!['status'] ?? '';
    final price = (_bookingData!['price'] ?? _bookingData!['totalAmount'] ?? 0)
        .toDouble();
    final createdAt = DateTime.parse(
        _bookingData!['createdAt'] ?? DateTime.now().toIso8601String());
    final medicines = _bookingData!['medicines'] as List?;
    final requirements = _bookingData!['requirements'] as Map<String, dynamic>?;
    final location = _bookingData!['location'] as Map<String, dynamic>?;
    final acceptedProvider =
        _bookingData!['acceptedProvider'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Tracking Timeline
            _buildOrderTracking(status),

            const Divider(height: 1),

            // Order Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order ID
                  Text(
                    'Order #${widget.bookingId.substring(widget.bookingId.length - 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Placed on ${DateFormat('dd MMM yyyy, hh:mm a').format(createdAt)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Medicines List (if pharmacist)
                  if (serviceType == 'pharmacist' &&
                      medicines != null &&
                      medicines.isNotEmpty) ...[
                    const Text(
                      'Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...medicines.map((med) => _buildMedicineItem(med)),
                    const SizedBox(height: 24),
                  ],

                  // Requirements
                  if (requirements != null) ...[
                    const Text(
                      'Requirements',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (requirements['description'] != null)
                      _buildInfoRow('Description', requirements['description']),
                    if (requirements['urgency'] != null)
                      _buildInfoRow('Urgency',
                          requirements['urgency'].toString().toUpperCase()),
                    if (requirements['specialRequirements'] != null)
                      _buildInfoRow('Special Requirements',
                          requirements['specialRequirements']),
                    const SizedBox(height: 24),
                  ],

                  // Delivery Address
                  if (location != null) ...[
                    const Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Color(0xFF4CAF50)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              location['address'] ?? 'No address provided',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Provider Info
                  if (acceptedProvider != null) ...[
                    const Text(
                      'Provider',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0xFF4CAF50),
                            child: Text(
                              (acceptedProvider['firstName'] ?? 'P')[0]
                                  .toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${acceptedProvider['firstName'] ?? ''} ${acceptedProvider['lastName'] ?? ''}'
                                      .trim(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (acceptedProvider['phone'] != null)
                                  Text(
                                    acceptedProvider['phone'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              // Call provider
                            },
                            icon: const Icon(Icons.phone,
                                color: Color(0xFF4CAF50)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Price Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '₹${price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildOrderTracking(String status) {
    // Define order stages
    final stages = [
      {'key': 'requested', 'label': 'Requested', 'icon': Icons.receipt},
      {'key': 'accepted', 'label': 'Accepted', 'icon': Icons.check_circle},
      {
        'key': 'in_progress',
        'label': 'In Progress',
        'icon': Icons.local_shipping
      },
      {'key': 'completed', 'label': 'Delivered', 'icon': Icons.done_all},
    ];

    int currentStageIndex = 0;
    switch (status.toLowerCase()) {
      case 'requested':
        currentStageIndex = 0;
        break;
      case 'accepted':
        currentStageIndex = 1;
        break;
      case 'in_progress':
        currentStageIndex = 2;
        break;
      case 'completed':
        currentStageIndex = 3;
        break;
      case 'expired':
      case 'cancelled':
        currentStageIndex = -1; // Special case
        break;
    }

    if (currentStageIndex == -1) {
      // Show cancelled/expired status
      return Container(
        padding: const EdgeInsets.all(24),
        color: Colors.red[50],
        child: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.red, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == 'expired'
                        ? 'This order has expired'
                        : 'This order was cancelled',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: List.generate(stages.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Line between nodes
                final lineIndex = index ~/ 2;
                final isCompleted = lineIndex < currentStageIndex;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? const Color(0xFF4CAF50)
                        : Colors.grey[300],
                  ),
                );
              } else {
                // Node
                final stageIndex = index ~/ 2;
                final stage = stages[stageIndex];
                final isCompleted = stageIndex < currentStageIndex;
                final isCurrent = stageIndex == currentStageIndex;

                return Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCompleted || isCurrent
                            ? const Color(0xFF4CAF50)
                            : Colors.grey[300],
                      ),
                      child: Icon(
                        stage['icon'] as IconData,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        stage['label'] as String,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCompleted || isCurrent
                              ? const Color(0xFF4CAF50)
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                );
              }
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(Map<String, dynamic> medicine) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9800).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication, color: Color(0xFFFF9800)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medicine['name'] ?? 'Medicine',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${medicine['quantity']} × ₹${medicine['price']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '₹${(medicine['quantity'] * medicine['price']).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
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
