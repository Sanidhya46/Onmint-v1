import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import '../services/booking_detail_screen.dart';
import '../bookings/pharmacist_order_tracking_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final OnMintApiClient _apiClient;
  List<Booking> _orders = [];
  bool _isLoading = false;
  String _filterStatus =
      'all'; // all, requested, accepted, in_progress, completed, expired

  @override
  void initState() {
    super.initState();
    _apiClient = OnMintApiClient();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();

      // Get medicine orders from realtime bookings
      final response = await _apiClient.patient.getMyRealtimeBookings(
        page: 1,
        limit: 100,
      );

      if (response['data'] is List) {
        // Filter only pharmacist orders
        final medicineOrders = (response['data'] as List)
            .where((e) => e['serviceType'] == 'pharmacist')
            .map((e) => Booking.fromJson(e))
            .toList();

        if (mounted) {
          setState(() {
            _orders = medicineOrders;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading medicine orders: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return const Color(0xFF4CAF50);
      case 'expired':
      case 'cancelled':
        return const Color(0xFFF44336);
      case 'requested':
      case 'pending':
        return const Color(0xFFFF9800);
      case 'accepted':
      case 'in_progress':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Apply filter
    final filteredOrders = _filterStatus == 'all'
        ? _orders
        : _orders
            .where((o) => o.status.toLowerCase() == _filterStatus)
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Order History'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          // Filter dropdown
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                const Text(
                  'Filter:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterStatus,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                              value: 'all', child: Text('All Orders')),
                          DropdownMenuItem(
                              value: 'requested', child: Text('Requested')),
                          DropdownMenuItem(
                              value: 'accepted', child: Text('Accepted')),
                          DropdownMenuItem(
                              value: 'in_progress', child: Text('In Progress')),
                          DropdownMenuItem(
                              value: 'completed', child: Text('Completed')),
                          DropdownMenuItem(
                              value: 'expired', child: Text('Expired')),
                        ],
                        onChanged: (value) {
                          setState(() => _filterStatus = value!);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4CAF50)))
                : filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.medication,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              _filterStatus == 'all'
                                  ? 'No medicine orders yet'
                                  : 'No $_filterStatus orders',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final order = filteredOrders[index];
                            return _buildOrderCard(order);
                          },
                        ),
                      ),
          ),
        ],
      )),
    );
  }

  Widget _buildOrderCard(Booking order) {
    final status = order.status;
    final totalAmount = order.price;
    final createdAt =
        DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PharmacistOrderTrackingScreen(bookingId: order.id),
          ),
        ).then((_) => _loadOrders());
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order title and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Medicine Order',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(status),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Order date
              Text(
                'Ordered on $createdAt',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),

              // Notes/Description
              if (order.notes != null && order.notes!.isNotEmpty) ...[
                Text(
                  order.notes!,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Total amount
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PharmacistOrderTrackingScreen(bookingId: order.id),
                      ),
                    ).then((_) => _loadOrders());
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF4CAF50),
                    side: const BorderSide(
                      color: Color(0xFF4CAF50),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontWeight: FontWeight.w600),
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
