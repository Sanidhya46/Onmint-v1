import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ui_components/ui_components.dart';

class OrderTrackingScreen extends StatefulWidget {
  final String orderId;

  const OrderTrackingScreen({super.key, required this.orderId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _apiClient = OnMintApiClient();
  Timer? _timer;
  Map<String, dynamic>? _order;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();

    // Poll every 5 seconds for real-time updates
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _loadOrder();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    try {
      await _apiClient.initialize();
      final response = await _apiClient.get('/realTimeBooking/${widget.orderId}');

      if (mounted) {
        setState(() {
          _order = response.data['data'];
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

  Future<void> _callStore(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ToastUtils.showError('Phone number not available');
      return;
    }
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ToastUtils.showError('Could not launch phone dialer');
    }
  }

  Future<void> _rejectOrder() async {
    try {
      await _apiClient.post(
        '/realtime-booking/${widget.orderId}/cancel',
        data: {'reason': 'Cancelled by user'},
      );
      ToastUtils.showSuccess('Order cancelled successfully');
      _loadOrder();
    } catch (e) {
      ToastUtils.showError('Failed to cancel order: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(elevation: 0, backgroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF0F2147))),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text('Error: $_error')),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Not Found')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final status = _order!['status'];
    final isSearching = status == 'requested';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Request Sent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F2147),
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadOrder,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isSearching) _buildSearchingHeader() else _buildOrderHeader(),
              const SizedBox(height: 16),
              if (isSearching) _buildOrderedMedicinesList() else _buildStatusTracker(),
              const SizedBox(height: 16),
              if (!isSearching) _buildActionButtons(),
              if (!isSearching) const SizedBox(height: 16),
              _buildDeliveryAddress(),
              const SizedBox(height: 24),
              if (isSearching) _buildCancelButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchingHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top, color: Color(0xFF0F2147), size: 40),
          ),
          const SizedBox(height: 20),
          const Text(
            'Finding a Pharmacy Partner...',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xFF0F2147)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Please wait while we assign the best pharmacy to fulfill your order.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderedMedicinesList() {
    final medicines = _order!['medicines'] as List?;
    if (medicines == null || medicines.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ordered Medicines', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2147))),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: medicines.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final med = medicines[index];
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      med['medicineId']?['name'] ?? med['name'] ?? 'Medicine',
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('x${med['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _rejectOrder,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text('Cancel Request', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Widget _buildOrderHeader() {
    bool isDirect = _order!['medicines'] != null;
    int itemsCount = (_order!['medicines'] as List?)?.length ?? 0;
    double price = double.tryParse(_order!['price']?.toString() ?? '0') ?? 0.0;
    final provider = _order!['provider'];
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_pharmacy, color: Color(0xFF0F2147)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider != null ? (provider['pharmacyName'] ?? '${provider['firstName']} ${provider['lastName']}') : 'Assigned Pharmacy',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2147)),
                    ),
                    const Text('Order Details', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Items: $itemsCount', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              Text('Total amount: ₹${price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F2147))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final provider = _order!['provider'];
    final phone = provider?['phone'];
    final status = _order!['status'];
    bool canReject = status == 'requested' || status == 'accepted';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: provider != null ? () => _callStore(phone) : null,
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Call Store', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F2147),
                side: const BorderSide(color: Color(0xFF0F2147)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          if (canReject) ...[
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _rejectOrder,
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Cancel Order', style: TextStyle(fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusTracker() {
    final currentStatus = _order!['status'];
    
    final statuses = [
      {'key': 'requested', 'label': 'Order Requested'},
      {'key': 'accepted', 'label': 'Order Accepted'},
      {'key': 'packing_medicines', 'label': 'Packing Medicines'},
      {'key': 'out_for_delivery', 'label': 'Out for Delivery'},
      {'key': 'completed', 'label': 'Delivered'},
    ];

    int currentIndex = 0;
    if (currentStatus == 'cancelled') {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: const Text('Order Cancelled', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
      );
    }
    
    // Map legacy or intermediate statuses
    String mappedStatus = currentStatus;
    if (currentStatus == 'in_progress') mappedStatus = 'packing_medicines';
    if (currentStatus == 'on_the_way') mappedStatus = 'out_for_delivery';

    for (int i = 0; i < statuses.length; i++) {
      if (statuses[i]['key'] == mappedStatus) {
        currentIndex = i;
        break;
      }
    }

    String timeStr = '';
    String dateStr = '';
    if (_order!['createdAt'] != null) {
      final dt = DateTime.parse(_order!['createdAt']).toLocal();
      timeStr = '${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = '${dt.day} ${months[dt.month - 1]}';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(statuses.length, (index) {
          final status = statuses[index];
          final isCompleted = index <= currentIndex;
          final isCurrent = index == currentIndex;
          final isLast = index == statuses.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isCompleted ? const Color(0xFF0F2147) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isCompleted ? const Color(0xFF0F2147) : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: isCompleted ? const Color(0xFF0F2147) : Colors.grey[200],
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        status['label']!,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          color: isCompleted ? const Color(0xFF0F2147) : Colors.grey,
                        ),
                      ),
                      if (isCompleted && index == 0) // Only show timestamp for first step
                        Text(
                          '$dateStr, $timeStr',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDeliveryAddress() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.location_on_outlined, color: Color(0xFF0F2147), size: 20),
              SizedBox(width: 8),
              Text(
                'Delivery Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F2147)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _order!['address'] ?? _order!['location']?['address'] ?? 'No address provided',
            style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
