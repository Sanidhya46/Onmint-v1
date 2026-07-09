import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import '../home/home_screen.dart';

class PharmacistOrderTrackingScreen extends StatefulWidget {
  final String bookingId;

  const PharmacistOrderTrackingScreen({super.key, required this.bookingId});

  @override
  State<PharmacistOrderTrackingScreen> createState() => _PharmacistOrderTrackingScreenState();
}

class _PharmacistOrderTrackingScreenState extends State<PharmacistOrderTrackingScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _showAllMedicines = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      final data = await _apiClient.patient.getRealtimeBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _booking = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final status = _booking!['status']?.toString().toLowerCase() ?? '';
    bool isPending = status == 'requested' || status == 'pending';
    bool isPrescriptionBased = _booking!['isPrescriptionBased'] == true || _booking!['isPrescriptionBased'] == 'true';
    List offers = _booking!['offers'] ?? [];
    
    bool hasOffers = isPrescriptionBased && offers.isNotEmpty && isPending;
    
    String appBarTitle = 'Order Details';
    if (status == 'completed') appBarTitle = 'Order Delivered';
    else if (!isPending) appBarTitle = 'Order Confirmed';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: hasOffers ? const Color(0xFF0033CC) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: hasOffers ? Colors.white : Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen(initialIndex: 2)),
              (route) => false,
            );
          },
        ),
        title: Column(
          children: [
            Text(
              hasOffers ? 'Prescription Offers' : (isPending ? 'Request Sent' : appBarTitle),
              style: TextStyle(color: hasOffers ? Colors.white : const Color(0xFF001F4D), fontWeight: FontWeight.w700, fontSize: 18),
            ),
            if (hasOffers)
              const Text('Review and approve one offer to place your order', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.normal)),
          ],
        ),
        centerTitle: true,
        actions: isPending && !hasOffers ? [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.verified_user, color: Color(0xFF001F4D), size: 16),
              const SizedBox(width: 4),
              const Text('Secure', style: TextStyle(color: Color(0xFF001F4D), fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 16),
            ],
          )
        ] : null,
      ),
      bottomNavigationBar: isPending && !hasOffers ? _buildPendingBottomBar() : null,
      body: RefreshIndicator(
        onRefresh: _loadBooking,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              if (hasOffers)
                _buildOffersUI(offers)
              else if (isPending)
                _buildPendingHeader(),
              
              if (!hasOffers) ...[
                if (isPending) _buildPendingDetails() else _buildAcceptedDetails(),
                const SizedBox(height: 8),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _approveOffer(String offerId, String vendorId) async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      final response = await _apiClient.post('/patient/orders/${widget.bookingId}/approve-offer', data: {
        'offerId': offerId,
        'vendorId': vendorId,
      });
      if (response.statusCode == 200) {
        _loadBooking();
      } else {
        throw Exception(response.data['message'] ?? 'Failed to approve offer');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _rejectOrder() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      await _apiClient.post(
        '/realtime-bookings/${widget.bookingId}/cancel',
        data: {'reason': 'Cancelled by user'},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order cancelled successfully')));
        _loadBooking();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel order: $e')));
      }
    }
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Connecting to Support...')));
  }

  String _getDeliveryAddress() {
    String addr = _booking!['address'] ?? _booking!['location']?['address'] ?? '';
    final patient = _booking!['patientId'] ?? {};
    if (addr.isEmpty || addr == 'No address provided') {
      if (patient is Map) {
        final city = patient['city'] ?? '';
        final state = patient['state'] ?? '';
        if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
        if (city.isNotEmpty) return city;
        if (state.isNotEmpty) return state;
      }
      return 'No address provided';
    }
    if (patient is Map) {
      final state = patient['state'] ?? '';
      if (state.isNotEmpty && !addr.contains(state)) {
         return '$addr, $state';
      }
    }
    return addr;
  }

  void _showPrescriptionImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black87,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              child: Image.network(imageUrl, fit: BoxFit.contain, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersUI(List offers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Your Prescription Card
        Container(
           margin: const EdgeInsets.only(bottom: 16),
           padding: const EdgeInsets.all(12),
           decoration: BoxDecoration(
             border: Border.all(color: Colors.blue.shade100),
             borderRadius: BorderRadius.circular(12),
             color: Colors.white,
           ),
           child: Row(
             children: [
               Container(
                 padding: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                   color: Colors.green.shade50,
                   borderRadius: BorderRadius.circular(8),
                 ),
                 child: Icon(Icons.description, color: Colors.green.shade600),
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('Your Prescription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF001F4D))),
                     Text('Uploaded on ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.tryParse(_booking!['createdAt'] ?? '') ?? DateTime.now())}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                   ],
                 ),
               ),
               OutlinedButton.icon(
                 onPressed: () {},
                 icon: const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF0033CC)),
                 label: const Text('View Prescription', style: TextStyle(color: Color(0xFF0033CC), fontSize: 11)),
                 style: OutlinedButton.styleFrom(
                   side: BorderSide(color: Colors.blue.shade200),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                   minimumSize: const Size(0, 32),
                 ),
               )
             ]
           )
        ),
        
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text('Offers from Nearby Pharmacies', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                 const SizedBox(height: 2),
                 const Text('Choose one offer to continue', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_user, color: Colors.green, size: 14),
                const SizedBox(width: 4),
                const Text('Secure & Safe', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        ...offers.map((offer) {
          final vendor = offer['vendorId'] ?? {};
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          vendor['profilePicSigned'] ?? vendor['profilePic'] ?? 'https://ui-avatars.com/api/?name=${vendor['pharmacyName'] ?? vendor['firstName'] ?? 'P'}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor['pharmacyName'] ?? vendor['firstName'] ?? 'Pharmacy',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF001F4D)),
                          ),
                          const SizedBox(height: 2),
                          Text('2.1 km away', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.green, size: 10),
                                    const SizedBox(width: 2),
                                    Text('${vendor['averageRating'] ?? '4.6'}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text('(${vendor['totalRatings'] ?? '128'})', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 2),
                        Text('₹${double.tryParse(offer['amount']?.toString() ?? '0')?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                        const SizedBox(height: 2),
                        const Text('Includes all taxes', style: TextStyle(fontSize: 9, color: Colors.blue)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.electric_moped, color: Colors.green, size: 14),
                        const SizedBox(width: 6),
                        Text('Delivery in ${offer['deliveryTime'] ?? '2-3 hours'}', style: const TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.close, color: Colors.red, size: 14),
                          label: const Text('Cancel', style: TextStyle(color: Colors.red, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => _approveOffer(offer['_id'], vendor['_id']),
                          icon: const Icon(Icons.check, color: Colors.green, size: 14),
                          label: const Text('Approve', style: TextStyle(color: Colors.green, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.green),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          );
        }).toList(),
        
        // How it works
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF0033CC), size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How it works?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF001F4D))),
                    SizedBox(height: 4),
                    Text('Approve one offer to confirm your order.\nSelecting an offer will automatically cancel the others.', style: TextStyle(fontSize: 10, color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.local_pharmacy_outlined, color: Colors.blue, size: 30),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPendingHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/medicine/request_sent_top_banner.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox(
            height: 120,
            child: Center(child: Icon(Icons.local_pharmacy, size: 60, color: Color(0xFF0033CC))),
          );
        },
      ),
    );
  }

  Widget _buildAcceptedHeader() {
    final status = _booking!['status']?.toString().toLowerCase() ?? '';
    
    String title = 'Order Confirmed';
    String subtitle = 'Your order is confirmed and being processed.';
    if (status == 'completed') {
      title = 'Order Delivered Successfully!';
      final pData = _booking!['acceptedProvider'] ?? _booking!['provider'] ?? {};
      final pName = pData['businessName'] ?? pData['fullName'] ?? 'Pharmacy';
      subtitle = 'Your order has been delivered.\nThank you for choosing $pName.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1FDF3), // very light green
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD0F0D9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: Colors.green[800], fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.green[800], fontSize: 11, height: 1.3),
                ),
              ],
            ),
          ),
          // Placeholder for the illustration
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.local_mall, color: Colors.green, size: 20),
          )
        ],
      ),
    );
  }

  Widget _buildPendingDetails() {
    bool isPrescriptionBased = _booking!['isPrescriptionBased'] == true || _booking!['isPrescriptionBased'] == 'true';
    List medicines = _booking!['medicines'] ?? [];
    List prescriptionImages = _booking!['prescriptionImages'] ?? [];
    
    // For pending orders, we calculate amount from medicines array if it's not prescription
    double totalAmt = double.tryParse(_booking!['price']?.toString() ?? '0') ?? 0.0;
    if (totalAmt == 0.0 && !isPrescriptionBased) {
      totalAmt = medicines.fold(0.0, (sum, med) {
        if (med is Map) {
          return sum + ((double.tryParse(med['price']?.toString() ?? '0') ?? 0.0) * (int.tryParse(med['quantity']?.toString() ?? '1') ?? 1));
        }
        return sum;
      });
    }

    return Column(
      children: [
        // Ordered Medicines / Prescription Card
        Container(
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
              if (isPrescriptionBased) ...[
                Row(
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
                                child: const Text('View Prescription Image', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: GestureDetector(
                        onTap: () {
                          if (prescriptionImages.isNotEmpty) {
                            _showPrescriptionImage(prescriptionImages[0]);
                          }
                        },
                        child: Container(
                          height: 100,
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
              ] else ...[
                const Text('Ordered Medicines', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                const SizedBox(height: 16),
                ...medicines.take(_showAllMedicines ? medicines.length : (medicines.length > 5 ? 5 : medicines.length)).map((medRaw) {
                  if (medRaw is! Map) return const SizedBox.shrink();
                  final med = medRaw;
                  final medicineDetails = med['medicineId'] is Map ? med['medicineId'] : {};
                  final medName = medicineDetails['name'] ?? med['name'] ?? 'Medicine';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(Icons.medication, color: Color(0xFF001F4D), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(medName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                              Text('Qty: ${med['quantity'] ?? 1}', style: const TextStyle(color: Colors.black54, fontSize: 11)),
                            ],
                          ),
                        ),
                        Text('₹${((double.tryParse(med['price']?.toString() ?? '0') ?? 0.0) * (int.tryParse(med['quantity']?.toString() ?? '1') ?? 1)).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                      ],
                    ),
                  );
                }).toList(),
                if (medicines.length > 5) ...[
                  const Divider(),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _showAllMedicines = !_showAllMedicines;
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _showAllMedicines ? 'Show less' : 'View ${medicines.length - 5} more medicine(s)',
                        style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                ],
              ]
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Delivery Address Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, size: 20, color: Color(0xFF001F4D)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivery Address', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                    const SizedBox(height: 4),
                    const Text('Home', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(
                      _getDeliveryAddress(),
                      style: const TextStyle(fontSize: 11, height: 1.3, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Order Summary Card
        Container(
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
              const Text('Order Summary', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
              const SizedBox(height: 12),
              if (isPrescriptionBased) ...[
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.access_time, size: 20, color: Color(0xFF001F4D)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Estimated Acceptance', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                SizedBox(height: 2),
                                Text('1 - 3 Minutes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 30, color: Colors.grey.shade300),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.delivery_dining, size: 20, color: Color(0xFF001F4D)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delivery Charge', style: TextStyle(fontSize: 10, color: Colors.black54)),
                                SizedBox(height: 2),
                                Text('₹120', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCol(Icons.shopping_bag_outlined, 'Items', '${medicines.length} Meds'),
                    _buildSummaryCol(Icons.currency_rupee, 'Amount', '₹${totalAmt.toStringAsFixed(2)}'),
                    _buildSummaryCol(Icons.receipt_long_outlined, 'Order ID', '#${widget.bookingId.length > 8 ? widget.bookingId.substring(0, 8).toUpperCase() : widget.bookingId}'),
                    _buildSummaryCol(Icons.access_time, 'Acceptance', '1-3 Min'),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        
        // Notification Banner
        Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFD9E2FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications, color: Color(0xFF001F4D), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notifying nearby verified pharmacies...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF001F4D))),
                    SizedBox(height: 4),
                    Text("You'll get a notification as soon as any pharmacy accepts your order.", style: TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCol(IconData icon, String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF001F4D)),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
        ],
      ),
    );
  }

  Widget _buildPendingBottomBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rejectOrder,
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Cancel Request'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF001F4D),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF001F4D)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _contactSupport,
                    icon: const Icon(Icons.headset_mic, size: 18),
                    label: const Text('Contact Support'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001F4D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedDetails() {
    final pData = _booking!['acceptedProvider'] ?? _booking!['provider'];
    final provider = (pData is Map) ? pData : {};
    final pName = provider['businessName'] ?? provider['fullName'] ?? 'Pharmacy Store';
    final medicines = (_booking!['medicines'] as List?) ?? [];
    double totalAmt = _booking!['price'] ?? 0.0;
    totalAmt += 45; // Delivery + packing for UI realism
    
    final createdStr = _booking!['createdAt']?.toString();
    DateTime date = DateTime.now();
    if (createdStr != null) {
      date = DateTime.tryParse(createdStr) ?? DateTime.now();
    }
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(date);
    
    return Column(
      children: [
        // Pharmacy Info
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[50],
                backgroundImage: provider['profilePic'] != null ? NetworkImage(provider['profilePic']) : null,
                onBackgroundImageError: (e, s) {},
                child: provider['profilePic'] == null ? const Icon(Icons.local_pharmacy, size: 16, color: Color(0xFF0033CC)) : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Row(
                      children: [
                        const Icon(Icons.verified, size: 10, color: Colors.blue),
                        const SizedBox(width: 2),
                        Text('Verified Store', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                      ],
                    )
                  ],
                ),
              ),
              _buildSquareIconBtn(Icons.call, 'Call'),
              const SizedBox(width: 6),
              _buildSquareIconBtn(Icons.chat, 'Chat'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Tracking Info Row
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 12, color: Colors.blue.shade800),
                        const SizedBox(width: 4),
                        const Text('Order Placed', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(formattedDate, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(width: 1, height: 20, color: Colors.grey.shade200),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.blue.shade800),
                        const SizedBox(width: 4),
                        const Text('Home Delivery', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Within 8 hours', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Container(width: 1, height: 20, color: Colors.grey.shade200),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.payments_outlined, size: 12, color: Colors.blue.shade800),
                        const SizedBox(width: 4),
                        const Text('Payment Mode', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text('Cash on Delivery', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Delivery Address
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Delivered to', style: TextStyle(fontSize: 9, color: Colors.grey)),
                    const SizedBox(height: 2),
                    Text(
                      _booking!['location']?['address'] ?? 'No address provided',
                      style: const TextStyle(fontSize: 10, height: 1.2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Medicines List or Prescription Image
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Medicine Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
              const SizedBox(height: 16),
              if (_booking!['isPrescriptionBased'] == true) ...[
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
                          if (_booking!['prescriptionImages'] != null && _booking!['prescriptionImages'].isNotEmpty) {
                            showDialog(
                              context: context,
                              builder: (ctx) => Dialog(
                                insetPadding: EdgeInsets.zero,
                                backgroundColor: Colors.black,
                                child: Stack(
                                  children: [
                                    Center(
                                      child: InteractiveViewer(
                                        child: Image.network(_booking!['prescriptionImages'][0], errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey)),
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
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: (_booking!['prescriptionImages'] != null && _booking!['prescriptionImages'].isNotEmpty)
                                ? Image.network(_booking!['prescriptionImages'][0], fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey))
                                : const Center(child: Icon(Icons.image, color: Colors.grey)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Medicines (${medicines.length} Items)', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                    const Text('See All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                ...medicines.take(5).map((medRaw) {
                  if (medRaw is! Map) return const SizedBox.shrink();
                  final med = medRaw;
                  final double price = double.tryParse(med['price']?.toString() ?? '0') ?? 0.0;
                  final int qty = int.tryParse(med['quantity']?.toString() ?? '1') ?? 1;
                  return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                        child: const Icon(Icons.medication, size: 14, color: Colors.blue),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: Text(med['name'] ?? 'Medicine', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF001F4D))),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('$qty x ₹$price', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text('₹${price * qty}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                      ),
                    ],
                  ),
                );}).toList(),
                if (medicines.length > 5) ...[
                  const Divider(),
                  Center(
                    child: TextButton(
                      onPressed: (){}, 
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View all ${medicines.length} items', style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold)),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black87),
                      ],
                    )
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
        const SizedBox(height: 8),

        // Payment Mode
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.mobile_friendly, size: 20, color: Color(0xFF0033CC)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Payment Mode', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                    const SizedBox(height: 2),
                    const Text('Cash on Delivery', style: TextStyle(fontSize: 10, color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text('Paid in cash for this order.', style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 12, color: Colors.green),
                    const SizedBox(width: 4),
                    Text('Paid', style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Total Amount
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB), // Light blue-grey
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
                  const SizedBox(height: 2),
                  Text('(Includes medicines + packing + delivery charges)', style: TextStyle(fontSize: 8, color: Colors.grey.shade600)),
                ],
              ),
              Text('₹${totalAmt.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Order Status
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Order Status', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF001F4D))),
              const SizedBox(height: 12),
              _buildStatusTracker(),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTracker() {
    final status = _booking!['status']?.toString().toLowerCase() ?? '';
    int currentStep = 0;
    if (status == 'completed' || status == 'delivered') currentStep = 3;
    else if (status == 'out_for_delivery' || status == 'on_the_way') currentStep = 2;
    else if (status == 'packing_medicines' || status == 'packing' || status == 'in_progress') currentStep = 1;
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final double nodeWidth = 70.0;
        final double availableWidth = constraints.maxWidth;
        final double lineLeft = nodeWidth / 2;
        final double lineRight = nodeWidth / 2;
        final double lineTotalWidth = availableWidth - lineLeft - lineRight;
        
        return Stack(
          children: [
            Positioned(
              top: 11,
              left: lineLeft,
              right: lineRight,
              child: Container(height: 2, color: Colors.grey.shade300),
            ),
            if (currentStep > 0)
              Positioned(
                top: 11,
                left: lineLeft,
                width: lineTotalWidth * (currentStep / 3),
                child: Container(height: 2, color: Colors.green),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTrackerNode('Order Accepted', 'Just Now', currentStep >= 0, nodeWidth),
                _buildTrackerNode('Packing Medicines', '10:20 AM', currentStep >= 1, nodeWidth),
                _buildTrackerNode('Out for Delivery', '12:15 PM', currentStep >= 2, nodeWidth),
                _buildTrackerNode('Delivered', '--:--', currentStep >= 3, nodeWidth),
              ],
            ),
          ],
        );
      }
    );
  }
  
  Widget _buildTrackerNode(String label, String time, bool isDone, double nodeWidth) {
    return SizedBox(
      width: nodeWidth,
      child: Column(
        children: [
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              color: isDone ? Colors.green : Colors.white,
              border: Border.all(color: isDone ? Colors.green : Colors.grey.shade300, width: 2),
              shape: BoxShape.circle,
            ),
            child: isDone ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
          ),
          const SizedBox(height: 8),
          Text(
            label, 
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 9, 
              fontWeight: isDone ? FontWeight.bold : FontWeight.normal, 
              color: isDone ? Colors.green.shade700 : Colors.black87
            )
          ),
          const SizedBox(height: 2),
          Text(time, style: TextStyle(fontSize: 8, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Widget _buildSquareIconBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildNeedHelp() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.headset_mic, color: Color(0xFF001F4D), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Need help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF001F4D))),
                const SizedBox(height: 2),
                Text('You can contact support anytime', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.black54),
        ],
      ),
    );
  }
}
