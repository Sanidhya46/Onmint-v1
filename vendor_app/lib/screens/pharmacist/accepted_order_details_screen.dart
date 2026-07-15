import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../../config/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class AcceptedOrderDetailsScreen extends StatefulWidget {
  final String bookingId;

  const AcceptedOrderDetailsScreen({super.key, required this.bookingId});

  @override
  State<AcceptedOrderDetailsScreen> createState() => _AcceptedOrderDetailsScreenState();
}

class _AcceptedOrderDetailsScreenState extends State<AcceptedOrderDetailsScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _error;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _apiClient.initialize();
      final response = await _apiClient.get('/realTimeBooking/${widget.bookingId}');
      
      if (mounted) {
        setState(() {
          _orderData = response.data['data'];
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

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await _apiClient.pharmacist.updateOrderStatus(widget.bookingId, newStatus);
      
      if (mounted) {
        ToastUtils.showSuccess('Status updated successfully');
        _loadOrderDetails(); // Reload to get updated status
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingStatus = false);
      }
    }
  }

  Future<void> _callPatient(String? phone) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color(0xFF0033CC),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _orderData == null
                  ? const Center(child: Text('Order not found'))
                  : _buildBody(),
      bottomNavigationBar: _orderData != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildBody() {
    final order = _orderData!;
    bool isDirect = order['medicines'] != null;
    final medicines = (order['medicines'] as List?) ?? [];
    
    String timeStr = '';
    String dateStr = '';
    if (order['createdAt'] != null) {
      final dt = DateTime.parse(order['createdAt']).toLocal();
      timeStr = '${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    final deliveryFee = 25.0; 
    final packingFee = 20.0;
    final medicinesTotal = order['price'] ?? 0.0;
    final totalAmount = medicinesTotal + deliveryFee + packingFee;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 14, color: Colors.green[700]),
                const SizedBox(width: 6),
                Text(
                  isDirect ? 'Direct Medicine Order' : 'Prescription Order',
                  style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Order Summary
          _buildSectionCard(
            title: 'Order Summary',
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (order['patient'] is Map && order['patient']['profilePic'] != null)
                      ? NetworkImage(order['patient']['profilePic'])
                      : null,
                  child: (order['patient'] is! Map || order['patient']['profilePic'] == null)
                      ? const Icon(Icons.person, color: Colors.grey, size: 28)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order['patientName'] ?? 'Unknown',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${order['patientAge'] ?? (order['patient'] is Map ? order['patient']['age'] : null) ?? 'Unknown'} Years / ${order['patientGender'] ?? (order['patient'] is Map ? order['patient']['gender'] : null) ?? "Unknown"}',
                        style: const TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Ordered On', style: TextStyle(fontSize: 11, color: Colors.blue)),
                    const SizedBox(height: 2),
                    Text('$dateStr, $timeStr', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Delivery Address
          _buildSectionCard(
            title: 'Delivery Address',
            titleIcon: Icons.location_on_outlined,
            child: Text(
              order['location']?['address'] ?? order['address'] ?? 'No address provided',
              style: const TextStyle(fontSize: 10, height: 1.4),
            ),
          ),
          const SizedBox(height: 8),

          // Medicine Details
          _buildSectionCard(
            title: 'Medicine Details',
            child: Column(
              children: [
                if (order['isPrescriptionBased'] == true) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text('Prescription Type', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text('Prescription Medicines', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text('Prescription Image', style: TextStyle(fontSize: 12, color: Colors.black54)),
                      ),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            if (order['prescriptionImages'] != null && (order['prescriptionImages'] as List).isNotEmpty) {
                              showDialog(
                                context: context,
                                builder: (ctx) => Dialog(
                                  insetPadding: EdgeInsets.zero,
                                  backgroundColor: Colors.black,
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: InteractiveViewer(
                                          child: Image.network(order['prescriptionImages'][0], errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey)),
                                        ),
                                      ),
                                      Positioned(
                                        top: 40,
                                        right: 20,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white, size: 30),
                                          onPressed: () => Navigator.pop(ctx),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                          child: Container(
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: (order['prescriptionImages'] != null && (order['prescriptionImages'] as List).isNotEmpty)
                                  ? Image.network(order['prescriptionImages'][0], fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey))
                                  : const Center(child: Icon(Icons.image, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Row(
                    children: [
                      Expanded(flex: 3, child: Text('Medicine', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                      Expanded(flex: 1, child: Text('Price', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                    ],
                  ),
                  const Divider(height: 20),
                  ...medicines.map((med) {
                    if (med is! Map) return const SizedBox();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(Icons.medication, size: 16, color: Colors.blue),
                          ),
                          const SizedBox(width: 8),
                          Expanded(flex: 3, child: Text(med['name']?.toString() ?? 'Unknown Medicine', style: const TextStyle(fontSize: 11))),
                          Expanded(flex: 1, child: Text('${med['quantity'] ?? 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11))),
                          Expanded(flex: 1, child: Text('₹${med['price'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11))),
                        ],
                      ),
                    );
                  }).toList(),
                ]
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Delivery Details
          _buildSectionCard(
            title: 'Delivery Details',
            titleIcon: Icons.local_shipping_outlined,
            child: Column(
              children: [
                _buildDetailRow('Delivery Type', 'Home Delivery'),
                const SizedBox(height: 12),
                _buildDetailRow('Preferred Time', order['requirements']?['preferredTime'] ?? 'Within 8 Hours'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Payment Mode
          _buildSectionCard(
            title: 'Payment Mode',
            titleIcon: Icons.payments_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Cash on Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text('You can pay the amount in cash when you receive your order.', style: TextStyle(fontSize: 11, color: Colors.blue[800])),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Total Amount
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[100]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF001F4D)),
                    ),
                    Text(
                      '₹${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0033CC)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  '(Includes medicines + packing + delivery charges)',
                  style: TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Order Status Horizontal Tracker
          _buildSectionCard(
            title: 'Order Status',
            child: _buildHorizontalTracker(order['status']),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, IconData? titleIcon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, size: 20, color: const Color(0xFF0033CC)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001F4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
      ],
    );
  }

  Widget _buildHorizontalTracker(String currentStatus) {
    final statusKey = currentStatus.toLowerCase();
    
    int currentStep = 0;
    if (statusKey == 'completed') currentStep = 3;
    else if (statusKey == 'out_for_delivery' || statusKey == 'on_the_way') currentStep = 2;
    else if (statusKey == 'packing_medicines' || statusKey == 'in_progress') currentStep = 1;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double nodeWidth = 60.0;
        final double availableWidth = constraints.maxWidth;
        final double lineLeft = nodeWidth / 2;
        final double lineRight = nodeWidth / 2;
        final double lineTotalWidth = availableWidth - lineLeft - lineRight;
        
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned(
              top: 9,
              left: lineLeft,
              right: lineRight,
              child: Container(height: 2, color: Colors.grey.shade300),
            ),
            if (currentStep > 0)
              Positioned(
                top: 9,
                left: lineLeft,
                width: lineTotalWidth * (currentStep / 3),
                child: Container(height: 2, color: Colors.green),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrackerNode('Order Accepted', 'Just Now', currentStep >= 0, isFirst: true),
                _buildTrackerNode('Packing Medicines', '10:20 AM', currentStep >= 1),
                _buildTrackerNode('Out for Delivery', '12:15 PM', currentStep >= 2),
                _buildTrackerNode('Delivered', '--:--', currentStep >= 3, isLast: true),
              ],
            ),
          ],
        );
      }
    );
  }

  Widget _buildTrackerNode(String label, String time, bool isDone, {bool isFirst = false, bool isLast = false}) {
    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              color: isDone ? Colors.green : Colors.white,
              border: Border.all(color: isDone ? Colors.green : Colors.grey.shade300, width: 2),
              shape: BoxShape.circle,
            ),
            child: isDone ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
          const SizedBox(height: 6),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8, 
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal, 
              color: isDone ? Colors.green.shade700 : Colors.black87
            )
          ),
          const SizedBox(height: 2),
          Text(time, style: TextStyle(fontSize: 7, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Future<void> _chatPatient(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ToastUtils.showError('Phone number not available');
      return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('whatsapp://send?phone=$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      final Uri webUrl = Uri.parse('https://wa.me/$cleanPhone');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        ToastUtils.showError('Could not launch WhatsApp');
      }
    }
  }

  Widget _buildBottomBar() {
    if (_isUpdatingStatus) {
      return const SafeArea(child: SizedBox(height: 60, child: Center(child: CircularProgressIndicator())));
    }
    
    final currentStatus = _orderData!['status']?.toString().toLowerCase() ?? '';
    final statuses = [
      {'key': 'accepted', 'label': 'Order Accepted'},
      {'key': 'in_progress', 'label': 'Packing Medicines'},
      {'key': 'on_the_way', 'label': 'Out for Delivery'},
      {'key': 'completed', 'label': 'Delivered'},
    ];

    int currentIndex = 0;
    if (currentStatus == 'completed') currentIndex = 3;
    else if (currentStatus == 'out_for_delivery' || currentStatus == 'on_the_way') currentIndex = 2;
    else if (currentStatus == 'packing_medicines' || currentStatus == 'in_progress') currentIndex = 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(child: _buildActionButton(Icons.call, 'Call Customer', () => _callPatient(_orderData!['patientPhone'] ?? _orderData!['patient']?['phone']))),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Expanded(child: _buildActionButton(Icons.chat, 'Chat', () => _chatPatient(_orderData!['patientPhone'] ?? _orderData!['patient']?['phone']))),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                Expanded(child: _buildActionButton(Icons.map, 'Open Map', () {})),
              ],
            ),
            if (currentIndex < statuses.length - 1) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: () => _updateStatus(statuses[currentIndex + 1]['key']!),
                  icon: Icon(
                    currentIndex == 0 ? Icons.inventory_2 : 
                    currentIndex == 1 ? Icons.moped : Icons.check_circle,
                    size: 20,
                  ),
                  label: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      statuses[currentIndex + 1]['label']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0033CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF0033CC), size: 24),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF001F4D))),
        ],
      ),
    );
  }
}
