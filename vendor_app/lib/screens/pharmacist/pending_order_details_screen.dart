import 'package:flutter/material.dart';
import 'dart:async';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../../config/app_colors.dart';
import 'accepted_order_details_screen.dart';

class PendingOrderDetailsScreen extends StatefulWidget {
  final dynamic order;

  const PendingOrderDetailsScreen({super.key, required this.order});

  @override
  State<PendingOrderDetailsScreen> createState() => _PendingOrderDetailsScreenState();
}

class _PendingOrderDetailsScreenState extends State<PendingOrderDetailsScreen> {
  final _apiClient = OnMintApiClient();
  bool _isProcessing = false;

  Future<void> _acceptOrder() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.initialize();
      await _apiClient.post('/realtime-bookings/${widget.order['_id']}/accept');
      
      if (!mounted) return;
      
      ToastUtils.showSuccess('Order accepted successfully!');
      
      // Navigate to accepted order details screen, replacing current
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AcceptedOrderDetailsScreen(bookingId: widget.order['_id']),
        ),
      );
    } catch (e) {
      if (mounted) {
        ToastUtils.showError(e.toString());
        setState(() => _isProcessing = false);
      }
    }
  }

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool _offerSent = false;
  Timer? _timer;
  Map<String, dynamic>? _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _offerSent = _currentOrder!['hasOffered'] == true ||
                 _currentOrder!['status'] == 'pending_patient_approval' || 
                 _currentOrder!['status'] == 'offer_sent';
                 
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollOrderDetails();
    });
  }

  Future<void> _pollOrderDetails() async {
    try {
      final response = await _apiClient.get('/realTimeBooking/${widget.order['_id']}');
      if (!mounted) return;
      final data = response.data['data'];
      final status = data['status'];
      setState(() {
        _currentOrder = data;
        _offerSent = _currentOrder!['hasOffered'] == true ||
                     status == 'pending_patient_approval' || 
                     status == 'offer_sent';
      });
      
      // If patient accepted the offer
      if (status == 'accepted') {
        _timer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => AcceptedOrderDetailsScreen(bookingId: widget.order['_id']),
          ),
        );
      } else if (status == 'cancelled' || status == 'rejected') {
        _timer?.cancel();
        Navigator.pop(context); // Go back if cancelled
      }
    } catch (e) {
      // Ignore polling errors silently
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amountController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _submitOffer(String amount, String deliveryTime) async {
    if (amount.isEmpty) {
      ToastUtils.showError('Please enter the total amount');
      return;
    }
    setState(() => _isProcessing = true);
    try {
      await _apiClient.initialize();
      await _apiClient.post('/realtime-bookings/${widget.order['_id']}/offer', data: {
        'amount': amount,
        'deliveryTime': deliveryTime,
      });
      
      if (!mounted) return;
      
      ToastUtils.showSuccess('Offer submitted successfully!');
      setState(() {
        _isProcessing = false;
        _offerSent = true;
      });
    } catch (e) {
      if (mounted) {
        if (e.toString().contains('already submitted')) {
          ToastUtils.showSuccess('Offer already submitted!');
          setState(() {
            _isProcessing = false;
            _offerSent = true;
          });
        } else {
          ToastUtils.showError(e.toString());
          setState(() => _isProcessing = false);
        }
      }
    }
  }

  // Removed dialog, using inline input now

  Future<void> _rejectOrder() async {
    // In our backend, cancel means we decline it. Or we can just pop so someone else can accept.
    // Usually, a vendor ignoring it means they don't accept it.
    // We'll just pop the screen.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    bool isPrescriptionBased = order['isPrescriptionBased'] ?? false;
    bool isDirect = !isPrescriptionBased;
    
    // Formatting time
    String timeStr = '';
    String dateStr = '';
    if (order['createdAt'] != null) {
      final dt = DateTime.parse(order['createdAt']).toLocal();
      timeStr = '${dt.hour > 12 ? dt.hour - 12 : dt.hour}:${dt.minute.toString().padLeft(2, '0')} ${dt.hour >= 12 ? 'PM' : 'AM'}';
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    }

    final medicines = (order['medicines'] as List?) ?? [];
    final prescriptionImages = (order['prescriptionImagesSigned'] as List?) ?? (order['prescriptionImages'] as List?) ?? [];
    
    final deliveryFee = 25.0; // Assume a flat fee if not in model
    final packingFee = 20.0;
    final medicinesTotal = order['price'] ?? 0.0;
    final totalAmount = medicinesTotal > 0 ? medicinesTotal + deliveryFee + packingFee : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: const Color(0xFF0033CC),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isProcessing 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
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
                        Icon(Icons.assignment_outlined, size: 14, color: Colors.green[700]),
                        const SizedBox(width: 6),
                        Text(
                          isDirect ? 'Direct Medicine Order' : 'Prescription Medicines',
                          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Order Summary / Customer Details
                  _buildSectionCard(
                    title: 'Customer Details',
                    titleIcon: Icons.person_outline,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.transparent,
                          backgroundImage: (order['patient'] is Map && order['patient']['profilePic'] != null)
                              ? NetworkImage(order['patient']['profilePic'])
                              : AssetImage((order['patient'] is Map ? order['patient']['gender'] : order['patientGender'])?.toString().toLowerCase() == 'female' ? 'assets/images/female_profile.png' : 'assets/images/male_profile.png') as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (order['patient'] is Map ? order['patient']['fullName'] : null) ?? order['patientName'] ?? 'Unknown',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${(order['patient'] is Map ? order['patient']['age'] : null) ?? order['patientAge'] ?? 0} Years / ${(order['patient'] is Map ? order['patient']['gender'] : null) ?? order['patientGender'] ?? "Unknown"}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                const Text('Ordered On', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 2),
                            Text(timeStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Delivery Address
                  _buildSectionCard(
                    title: 'Delivery Address',
                    titleIcon: Icons.location_on_outlined,
                    child: Text(
                      order['location']?['address'] ?? order['address'] ?? 'No address provided',
                      style: const TextStyle(fontSize: 13, height: 1.3, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Medicine Details
                  if (isPrescriptionBased) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 2.0),
                                      child: Icon(Icons.description_outlined, color: Color(0xFF001F4D), size: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: const Text('View Prescription Image\nand Add Medicine Amount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text('Carefully review the prescription image provided by the customer and add the total medicine amount including delivery charge.', style: TextStyle(fontSize: 10, color: Colors.black54, height: 1.3)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: GestureDetector(
                              onTap: () {
                                if (prescriptionImages.isNotEmpty) {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => Dialog(
                                      insetPadding: EdgeInsets.zero,
                                      backgroundColor: Colors.black,
                                      child: Stack(
                                        children: [
                                          Center(
                                            child: InteractiveViewer(
                                              child: Image.network(prescriptionImages[0], errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey)),
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
                                height: 140,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                  color: Colors.grey.shade50,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: prescriptionImages.isNotEmpty 
                                      ? Image.network(prescriptionImages[0], fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey))
                                      : const Center(child: Icon(Icons.image, color: Colors.grey)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Estimated Delivery Time Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estimated Delivery Time', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                                SizedBox(height: 4),
                                Text('Delivery will reach the customer within.', style: TextStyle(fontSize: 11, color: Colors.black54)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 90,
                            height: 40,
                            child: TextField(
                              controller: _timeController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              readOnly: _offerSent,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              decoration: InputDecoration(
                                suffixIcon: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [Text('Hours ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black))],
                                ),
                                suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
                                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF001F4D)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(color: Color(0xFF001F4D), width: 1.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Payment Amount Input
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF001F4D), size: 20),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Payment Amount (Set by you)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                                    SizedBox(height: 12),
                                    Text('Total Amount', style: TextStyle(fontSize: 12, color: Colors.black87)),
                                    SizedBox(height: 2),
                                    Text('Total amount includes delivery charge.', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                height: 40,
                                child: TextField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  readOnly: _offerSent,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  decoration: InputDecoration(
                                    prefixIcon: const Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [Text(' ₹ ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black))],
                                    ),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 24, minHeight: 0),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF001F4D)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(color: Color(0xFF001F4D), width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline, size: 16, color: Colors.black54),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'Please enter the total amount after reviewing the prescription. This amount will be shown to the customer.',
                                    style: TextStyle(fontSize: 10, color: Colors.black54, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    _buildSectionCard(
                      title: 'Medicine Details',
                      child: Column(
                        children: [
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
                                  Expanded(flex: 3, child: Text(med['name']?.toString() ?? 'Unknown Medicine', style: const TextStyle(fontSize: 13))),
                                  Expanded(flex: 1, child: Text('${med['quantity'] ?? 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 13))),
                                  Expanded(flex: 1, child: Text('₹${med['price'] ?? 0}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13))),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionCard(
                      title: 'Delivery Details',
                      titleIcon: Icons.local_shipping_outlined,
                      child: Column(
                        children: [
                          _buildDetailRow('Delivery Type', 'Home Delivery'),
                          const SizedBox(height: 12),
                          _buildDetailRow('Preferred Time', order['requirements']?['preferredTime'] ?? 'Within 8 hours'),
                          const SizedBox(height: 12),
                          Text(
                            'Your order will be delivered within 8 hours from the time of order confirmation.',
                            style: TextStyle(fontSize: 11, color: Colors.blue[800]),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
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
                              const Expanded(
                                child: Text(
                                  'Total Amount (with delivery)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF001F4D)),
                                ),
                              ),
                              Text(
                                '₹${totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0033CC)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            '(Includes medicines + packing + delivery charges)',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _offerSent
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue)
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Waiting for patient approval...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : isPrescriptionBased 
                ? SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_timeController.text.isEmpty) {
                          ToastUtils.showError('Please enter delivery time');
                          return;
                        }
                        _submitOffer(_amountController.text, '${_timeController.text} Hours');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.send, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Send for Patient Approval',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _rejectOrder,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.close, size: 20),
                              SizedBox(width: 4),
                              Text('Reject Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _acceptOrder,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check, size: 20),
                              SizedBox(width: 4),
                              Text('Accept Order', 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, IconData? titleIcon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF001F4D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
}
