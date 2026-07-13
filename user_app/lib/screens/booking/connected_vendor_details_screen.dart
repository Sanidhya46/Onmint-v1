import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/screens/booking/booking_details_full_page.dart';
import 'package:user_app/screens/profile/help_support_screen.dart';
import '../../config/app_config.dart';

class ConnectedVendorDetailsScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const ConnectedVendorDetailsScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  State<ConnectedVendorDetailsScreen> createState() =>
      _ConnectedVendorDetailsScreenState();
}

class _ConnectedVendorDetailsScreenState
    extends State<ConnectedVendorDetailsScreen> {
  final _apiClient = OnMintApiClient();
  bool _isLoading = false;
  Map<String, dynamic>? _bookingDetails;

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/realtime-bookings/${widget.bookingId}');
      final responseData = response.data is Map ? response.data : {};
      final data = responseData['data'] ?? responseData;
      if (mounted) {
        setState(() {
          _bookingDetails = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fallback to widget data if API call fails
        _bookingDetails = widget.bookingData;
      }
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri url = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  void _openWhatsApp(String phoneNumber) async {
    // Standardize phone number for whatsapp
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');
    if (!cleanNumber.startsWith('91') && cleanNumber.length == 10) {
      cleanNumber = '91$cleanNumber';
    }
    
    final Uri appUrl = Uri.parse('whatsapp://send?phone=$cleanNumber');
    final Uri webUrl = Uri.parse('https://wa.me/$cleanNumber');
    
    try {
      if (await canLaunchUrl(appUrl)) {
        await launchUrl(appUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch WhatsApp')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching WhatsApp: $e')),
      );
    }
  }

  String _getProfilePictureUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = AppConfig.apiBaseUrl;
    final uri = Uri.tryParse(base);
    if (uri != null) {
      final hostUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      final cleanPath = path.startsWith('/') ? path : '/$path';
      return '$hostUrl$cleanPath';
    }
    return path;
  }

  void _showBookingDetailsModal(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final address = booking['address'] ?? booking['location']?['address'] ?? 'Not specified';
        final name = booking['name'] ?? 'Not specified';
        final phone = booking['phone'] ?? 'Not specified';
        final notes = booking['notes'] ?? 'None';
        
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.assignment, color: Color(0xFF1A1A60)),
                  SizedBox(width: 8),
                  Text(
                    'Full Booking Details',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A60),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildModalRow('Patient Name', name),
              _buildModalRow('Contact Phone', phone),
              _buildModalRow('Service Address', address),
              _buildModalRow('Patient Note', notes),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A60),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getServiceTypeText(dynamic serviceTypeStr) {
    if (serviceTypeStr == null) return 'Service';
    final st = serviceTypeStr.toString().toLowerCase();
    if (st == 'nurse') return 'Home Care Nursing';
    if (st == 'ambulance') return 'Ambulance';
    if (st == 'bloodbank') return 'Blood Bank';
    if (st == 'pharmacist') return 'Pharmacist';
    return 'Pathology Lab Test';
  }

  @override
  Widget build(BuildContext context) {
    final booking = _bookingDetails ?? widget.bookingData;
    final isNurse = booking['serviceType']?.toString().toLowerCase() == 'nurse';
    
    // Vendor profile data
    final vendor = booking['acceptedProvider'] ?? booking['provider'] ?? {};
    final vendorName = vendor is Map
        ? (vendor['fullName'] ?? '${vendor['firstName'] ?? ''} ${vendor['lastName'] ?? ''}'.trim())
        : 'Service Provider';
    final experience = vendor is Map ? (vendor['experience']?.toString() ?? '5') : '5';
    final age = vendor is Map ? (vendor['age']?.toString() ?? '30') : '30';
    final gender = vendor is Map ? (vendor['gender']?.toString() ?? 'Female') : 'Female';
    final phone = vendor is Map ? (vendor['phone']?.toString() ?? '') : '';
    final licenseNumber = vendor is Map ? (vendor['licenseNumber']?.toString() ?? 'UPMCI/2022/45678') : 'UPMCI/2022/45678';
    final ownerName = vendor is Map ? '${vendor['firstName'] ?? 'Amit'} ${vendor['lastName'] ?? 'Verma'}' : 'Amit Verma';
    
    final city = vendor is Map ? (vendor['city']?.toString() ?? 'Jhansi') : 'Jhansi';
    final state = vendor is Map ? (vendor['state']?.toString() ?? 'Uttar Pradesh') : 'Uttar Pradesh';
    final pincode = vendor is Map ? (vendor['pincode']?.toString() ?? '284001') : '284001';
    final locationText = 'Location: $city, $state - $pincode';
    
    final profilePic = vendor is Map ? (vendor['profilePicture']?.toString() ?? '') : '';

    final amount = booking['totalAmount'] ?? booking['price'] ?? 0.0;
    
    String formattedDate = 'Immediate';
    final dateStr = booking['preferredDate'] ?? booking['createdAt'];
    if (dateStr != null) {
      final dt = DateTime.tryParse(dateStr.toString());
      if (dt != null) {
        formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A1A60),
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Connected',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: Color(0xFF1A1A60),
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.check_circle, color: Colors.blue, size: 16),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 1: Provider Profile Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF1F5F9), width: 1.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: profilePic.isNotEmpty
                                    ? Image.network(
                                        _getProfilePictureUrl(profilePic),
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Icon(
                                          isNurse ? Icons.person : (booking['serviceType']?.toString().toLowerCase() == 'ambulance' ? Icons.directions_car : Icons.local_hospital),
                                          color: const Color(0xFF2563EB),
                                          size: 36,
                                        ),
                                      )
                                    : Icon(
                                        isNurse ? Icons.person : (booking['serviceType']?.toString().toLowerCase() == 'ambulance' ? Icons.directions_car : Icons.local_hospital),
                                        color: const Color(0xFF2563EB),
                                        size: 36,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                            fontSize: 16,
                                            color: Color(0xFF0F2147),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.verified, color: Colors.green, size: 10),
                                            SizedBox(width: 2),
                                            Text(
                                              'Verified',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Poppins',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  if (isNurse) ...[
                                    _buildProfileRowItem(Icons.star_outline, 'Experience', '$experience Years  •  Age: $age Years'),
                                    _buildProfileRowItem(Icons.phone, 'Mobile Number', phone.isEmpty ? 'N/A' : phone),
                                    _buildProfileRowItem(Icons.badge, 'Licence Number', licenseNumber),
                                  ] else ...[
                                    _buildProfileRowItem(Icons.person, 'Owner Name', ownerName),
                                    _buildProfileRowItem(Icons.phone, 'Mobile Number', phone.isEmpty ? 'N/A' : phone),
                                    _buildProfileRowItem(Icons.badge, 'Licence Number', licenseNumber),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Location Container
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on, color: Color(0xFF2563EB), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: Color(0xFF2563EB),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$city, $state - $pincode',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11.5,
                                        color: Colors.grey,
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
                  ),
                  const SizedBox(height: 16),

                  // Quick Actions Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.phone_in_talk,
                          label: 'Call',
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEFF6FF),
                          onTap: () => _makePhoneCall(phone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickActionCard(
                          customIconWidget: Image.network(
                            'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6b/WhatsApp.svg/150px-WhatsApp.svg.png',
                            width: 32,
                            height: 32,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.chat, color: Color(0xFF25D366), size: 32),
                          ),
                          label: 'WhatsApp',
                          color: const Color(0xFF25D366),
                          bgColor: const Color(0xFFE8F5E9),
                          onTap: () => _openWhatsApp(phone),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildQuickActionCard(
                          icon: Icons.calendar_month,
                          label: 'Booking Details',
                          color: const Color(0xFF2563EB),
                          bgColor: const Color(0xFFEFF6FF),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingDetailsFullPage(booking: booking),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Card 3: Important Notice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade100, width: 1.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.error_outline, color: Colors.red, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Notice',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Omnint only connects users with vendors. All discussions, payments and service terms are between the user and the vendor.',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10.5,
                                  color: Colors.black54,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 4: Payment Details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Details',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1A1A60),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.green, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Payment Mode: Direct to Vendor. Customer will pay after service completion.',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 5: Booking Details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
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
                            Icon(Icons.assignment_outlined, color: Colors.grey.shade600, size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              'Booking Details',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1A1A60),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildBookingDetailRow('Service Type', _getServiceTypeText(booking['serviceType'])),
                        _buildBookingDetailRow('Offered Amount', '₹${amount.toString()}'),
                        _buildBookingDetailRow('Booking Date & Time', formattedDate, isLast: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Card 6: Need Help?
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.headset_mic_outlined, color: Colors.blue, size: 18),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need Help?',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: Color(0xFF1A1A60),
                                  ),
                                ),
                                Text(
                                  "Contact Support: We're here to help you.",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 10,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer (green)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade100),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.shield_outlined, color: Colors.green, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Your safety is our priority',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Do not share your personal details with the vendor. Contact support if you face any issue.',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: Colors.green.shade700,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.grey, size: 18),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF1A1A60),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileRowItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF2563EB)),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              fontFamily: 'Poppins',
            ),
          ),
          const Spacer(),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    IconData? icon,
    Widget? customIconWidget,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              customIconWidget ?? Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: Color(0xFF0F2147),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.bold)),
          Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF1A1A60), fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
