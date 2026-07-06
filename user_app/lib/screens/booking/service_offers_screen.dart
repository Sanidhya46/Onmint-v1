import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'connected_vendor_details_screen.dart';
import 'package:intl/intl.dart';

class ServiceOffersScreen extends StatefulWidget {
  final String bookingId;
  final String serviceType;
  final Map<String, dynamic> bookingData;

  const ServiceOffersScreen({
    Key? key,
    required this.bookingId,
    required this.serviceType,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<ServiceOffersScreen> createState() => _ServiceOffersScreenState();
}

class _ServiceOffersScreenState extends State<ServiceOffersScreen> {
  final _apiClient = OnMintApiClient();
  bool _isLoading = false;
  String? _approvingOfferId;
  Map<String, dynamic>? _bookingDetails;
  List<dynamic> _offers = [];
  final Set<String> _locallyRejectedOffers = {}; // Track locally rejected offers

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/realtime-bookings/${widget.bookingId}');
      final responseData = response.data is Map ? response.data : {};
      final data = responseData['data'] ?? responseData;
      if (mounted) {
        setState(() {
          _bookingDetails = data;
          _offers = data['offers'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load offers: $e')),
        );
      }
    }
  }

  Future<void> _approveOffer(dynamic offer) async {
    final offerId = offer['_id'] ?? '';
    setState(() => _approvingOfferId = offerId.toString());
    try {
      final vendorId = offer['vendorId'] is Map ? offer['vendorId']['_id'] : offer['vendorId'];
      
      final response = await _apiClient.post(
        '/realtime-bookings/${widget.bookingId}/approve-offer',
        data: {
          if (offerId.toString().isNotEmpty) 'offerId': offerId,
          'vendorId': vendorId,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Offer approved successfully!'), backgroundColor: Colors.green),
        );
        // Ensure the status reflects 'accepted' before passing data forward
        var updatedData = Map<String, dynamic>.from(widget.bookingData);
        updatedData['status'] = 'accepted';
        updatedData['acceptedProvider'] = vendorId;
        updatedData['totalAmount'] = offer['amount'];

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ConnectedVendorDetailsScreen(
              bookingId: widget.bookingId,
              bookingData: updatedData,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _approvingOfferId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to approve offer: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejectOffer(dynamic offer) async {
    final offerId = offer['_id'] ?? '';
    final vendorId = offer['vendorId'] is Map ? offer['vendorId']['_id'] : offer['vendorId'];
    
    // Hide locally immediately for better UX
    setState(() {
      _locallyRejectedOffers.add(offerId.toString().isNotEmpty ? offerId.toString() : vendorId.toString());
    });

    try {
      await _apiClient.post(
        '/realtime-bookings/${widget.bookingId}/reject-offer',
        data: {
          if (offerId.toString().isNotEmpty) 'offerId': offerId,
          'vendorId': vendorId,
        },
      );
    } catch (e) {
      // If backend fails, we can quietly print or show a subtle snackbar
      print('Reject offer backend error: $e');
    }
  }

  String _getServiceTitle(String type) {
    type = type.toLowerCase();
    if (type == 'nurse') return 'Nurse';
    if (type == 'pathology' || type == 'lab_test' || type == 'lab test' || type == 'labtest') return 'Pathology';
    if (type == 'bloodbank' || type == 'blood bank') return 'Blood Bank';
    if (type == 'ambulance') return 'Ambulance';
    if (type == 'doctor' || type == 'consultation') return 'Doctor';
    return type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : 'Service';
  }

  String _getNearbyProvidersLabel(String type) {
    type = type.toLowerCase();
    if (type == 'nurse') return 'Nurses';
    if (type == 'pathology' || type == 'lab_test' || type == 'lab test' || type == 'labtest') return 'Pathology Labs';
    if (type == 'bloodbank' || type == 'blood bank') return 'Blood Banks';
    if (type == 'ambulance') return 'Ambulances';
    if (type == 'doctor' || type == 'consultation') return 'Doctors';
    return '${_getServiceTitle(type)}s';
  }

  IconData _getServiceIcon(String type) {
    type = type.toLowerCase();
    if (type == 'nurse') return Icons.person;
    if (type == 'doctor' || type == 'consultation') return Icons.person_outline;
    if (type == 'pathology' || type == 'lab_test' || type == 'lab test' || type == 'labtest') return Icons.science;
    if (type == 'bloodbank' || type == 'blood bank') return Icons.bloodtype;
    if (type == 'ambulance') return Icons.local_shipping;
    return Icons.local_hospital;
  }

  @override
  Widget build(BuildContext context) {
    final serviceTitle = _getServiceTitle(widget.serviceType);
    final nearbyLabel = _getNearbyProvidersLabel(widget.serviceType);
    
    // Filter out rejected offers (both from API status and local UI state)
    final activeOffers = _offers.where((o) {
      final offerId = o['_id']?.toString() ?? '';
      final vendorId = o['vendorId'] is Map ? o['vendorId']['_id']?.toString() ?? '' : o['vendorId']?.toString() ?? '';
      final key = offerId.isNotEmpty ? offerId : vendorId;
      
      if (_locallyRejectedOffers.contains(key)) return false;
      return o['status']?.toString().toLowerCase() != 'rejected';
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1C3A),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '$serviceTitle Offers',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Review and approve one offer to book a ${serviceTitle.toLowerCase()} service',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 10,
                color: Colors.white70,
                fontWeight: FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      body: _isLoading && _offers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchBookingDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Section Title Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Offers from Nearby $nearbyLabel',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A1A60),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.shield, color: Colors.green, size: 12),
                                SizedBox(width: 4),
                                Text(
                                  'Secure & Safe',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Offers List
                    if (activeOffers.isEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.hourglass_empty, color: Colors.blue.shade300, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Waiting for offers...',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF152238),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Nearby service providers have been notified and are preparing bids.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: activeOffers.length,
                        itemBuilder: (context, index) {
                          final offer = activeOffers[index];
                          final vendor = offer['vendorId'] ?? {};
                          final vendorName = vendor is Map
                              ? (vendor['fullName'] ?? '${vendor['firstName'] ?? ''} ${vendor['lastName'] ?? ''}'.trim())
                              : 'Service Provider';
                          final locationStr = vendor is Map
                              ? '${vendor['city'] ?? ''}, ${vendor['state'] ?? ''}'.replaceAll(RegExp(r'^, |,$'), '').trim()
                              : 'Location N/A';
                          final profilePic = vendor is Map ? vendor['profilePicture']?.toString() ?? '' : '';
                          final rating = vendor is Map ? vendor['averageRating']?.toString() ?? '4.8' : '4.8';
                          
                          final amount = offer['amount'] ?? 0.0;
                          final note = offer['note']?.toString() ?? '';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Image
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: profilePic.isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(12),
                                                child: Image.network(
                                                  profilePic,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) =>
                                                      Icon(
                                                        _getServiceIcon(widget.serviceType),
                                                        color: const Color(0xFF1565C0),
                                                        size: 24,
                                                      ),
                                                ),
                                              )
                                            : Icon(
                                                _getServiceIcon(widget.serviceType),
                                                color: const Color(0xFF1565C0),
                                                size: 24,
                                              ),
                                      ),
                                      const SizedBox(width: 12),

                                      // Vendor details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    vendorName.isEmpty ? 'Provider' : vendorName,
                                                    style: const TextStyle(
                                                      fontFamily: 'Poppins',
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                      color: Color(0xFF152238),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 4),
                                                const Icon(Icons.verified, color: Colors.green, size: 14),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              locationStr.isEmpty ? 'Jhansi, Uttar Pradesh' : locationStr,
                                              style: const TextStyle(
                                                fontFamily: 'Poppins',
                                                fontSize: 11,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              children: [
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.flash_on, color: Colors.amber, size: 12),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Response within 10 mins',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 10,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.access_time, color: Colors.blue, size: 12),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      'Available 24x7',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        fontSize: 10,
                                                        color: Colors.grey.shade600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Pricing info
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'Total Amount',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            '₹${amount.toString()}',
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const Text(
                                            'Includes all taxes',
                                            style: TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 8,
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Custom Note If Exists
                                if (note.isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade100),
                                    ),
                                    child: Text(
                                      'Note: "$note"',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),

                                const Divider(height: 1),

                                // Action Buttons Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _rejectOffer(offer),
                                        borderRadius: const BorderRadius.only(
                                          bottomLeft: Radius.circular(16),
                                        ),
                                        child: Container(
                                          height: 44,
                                          alignment: Alignment.center,
                                          child: const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.close, color: Colors.red, size: 16),
                                              SizedBox(width: 6),
                                              Text(
                                                'Reject',
                                                style: TextStyle(
                                                  fontFamily: 'Poppins',
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(width: 1, height: 44, color: Colors.grey.shade200),
                                    Expanded(
                                      child: InkWell(
                                        onTap: () => _approveOffer(offer),
                                        borderRadius: const BorderRadius.only(
                                          bottomRight: Radius.circular(16),
                                        ),
                                        child: Container(
                                          height: 44,
                                          alignment: Alignment.center,
                                          child: _approvingOfferId == offer['_id']?.toString()
                                              ? const SizedBox(
                                                  height: 16,
                                                  width: 16,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                                  ),
                                                )
                                              : const Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.check, color: Colors.blue, size: 16),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      'Approve',
                                                      style: TextStyle(
                                                        fontFamily: 'Poppins',
                                                        color: Colors.blue,
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20, top: 12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'How it works?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xFF1565C0),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Approve one offer to confirm your ${serviceTitle.toLowerCase()} booking. Selecting an offer will automatically reject all other offers.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.blue.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
