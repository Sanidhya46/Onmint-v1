import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ui_components/ui_components.dart';
import "../booking/user_active_consultation_screen.dart";
import 'package:api_client/api_client.dart';
import 'package:user_app/screens/booking/doctor_request_sent_screen.dart';
import '../../config/app_colors.dart';
import '../booking/user_unified_tracking_screen.dart';
import 'pharmacist_order_tracking_screen.dart';
import '../booking/order_request_screen.dart';
import '../booking/order_detail_file.dart';
import '../booking/service_offers_screen.dart';
import '../booking/connected_vendor_details_screen.dart';
import 'package:user_app/config/app_config.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  late TabController _tabController;

  List<Map<String, dynamic>> _allBookings = [];
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _inProgressBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (_allBookings.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      await _apiClient.initialize();
      // Fetch all bookings
      final response = await _apiClient.patient.getBookings(page: 1, limit: 100);

      if (mounted) {
        setState(() {
          List<Map<String, dynamic>> newBookings = [];
          if (response is Map && response['success'] == true && response['data'] is List) {
            newBookings = List<Map<String, dynamic>>.from(response['data'] as List);
          } else if (response is List) {
            newBookings = List<Map<String, dynamic>>.from(response as List);
          }

          _allBookings = newBookings;
          
          // Sort newest first
          _allBookings.sort((a, b) {
            final timeA = DateTime.tryParse(a['createdAt']?.toString() ?? a['scheduledTime']?.toString() ?? '') ?? DateTime(0);
            final timeB = DateTime.tryParse(b['createdAt']?.toString() ?? b['scheduledTime']?.toString() ?? '') ?? DateTime(0);
            return timeB.compareTo(timeA);
          });

          _pendingBookings = [];
          _inProgressBookings = [];
          _completedBookings = [];

          for (var b in _allBookings) {
            final status = b['status']?.toString().toLowerCase() ?? '';
            if (status == 'cancelled' || status == 'rejected' || status == 'expired') {
              continue; // Do not show cancelled bookings
            } else if (status == 'requested' || status == 'pending') {
              _pendingBookings.add(b);
            } else if (status == 'completed') {
              _completedBookings.add(b);
            } else {
              _inProgressBookings.add(b);
            }
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.showError('Failed to load bookings');
      }
    }
  }

  void _viewBookingDetails(Map<String, dynamic> request) {
    final serviceType = request['serviceType'] ?? 'Unknown';
    final bookingId = request['_id']?.toString() ?? request['id']?.toString() ?? '';
    final status = request['status']?.toString().toLowerCase() ?? '';
    
    bool isPharmacy = serviceType.toLowerCase() == 'pharmacist' || 
                      serviceType.toLowerCase() == 'pharmacy' || 
                      serviceType.toLowerCase() == 'medicine' ||
                      (request['medicines'] != null && (request['medicines'] as List).isNotEmpty);

    if (status == 'requested' || status == 'pending' || status == 'waiting for pharmacist') {
      if (isPharmacy) {
        Navigator.pushNamed(
          context,
          '/pharmacist-tracking?id=$bookingId'
        ).then((_) => _loadBookings());
      } else if (serviceType.toLowerCase() == 'doctor' || serviceType.toLowerCase() == 'consultation') {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorRequestSentScreen(
              bookingId: bookingId,
              bookingData: request,
            ),
          ),
        ).then((_) => _loadBookings());
      } else {
        final hasOffers = request['offers'] is List && (request['offers'] as List).isNotEmpty;
        final isSupportedService = serviceType.toLowerCase() == 'nurse' || 
                                   serviceType.toLowerCase() == 'labtest' || 
                                   serviceType.toLowerCase() == 'pathology' ||
                                   serviceType.toLowerCase() == 'doctor' ||
                                   serviceType.toLowerCase() == 'consultation' ||
                                   serviceType.toLowerCase() == 'ambulance' ||
                                   serviceType.toLowerCase() == 'bloodbank' ||
                                   serviceType.toLowerCase() == 'blood bank';

        if (AppConfig.useNewFlow && isSupportedService && hasOffers) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ServiceOffersScreen(
                bookingId: bookingId,
                serviceType: serviceType,
                bookingData: request,
              ),
            ),
          ).then((_) => _loadBookings());
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderRequestScreen(
                bookingId: bookingId,
                bookingData: request,
                serviceType: serviceType,
              ),
            ),
          ).then((_) => _loadBookings());
        }
      }
    } else {
      if (isPharmacy) {
        Navigator.pushNamed(
          context,
          '/pharmacist-tracking?id=$bookingId'
        ).then((_) => _loadBookings());
      } else {
        final isVendorService = serviceType.toLowerCase() == 'nurse' || 
                             serviceType.toLowerCase() == 'labtest' || 
                             serviceType.toLowerCase() == 'pathology' ||
                             serviceType.toLowerCase() == 'ambulance' ||
                             serviceType.toLowerCase() == 'bloodbank';
        final isConnectedState = status == 'accepted' || status == 'on_the_way' || status == 'in_progress';

        if (AppConfig.useNewFlow && isVendorService && isConnectedState) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ConnectedVendorDetailsScreen(
                bookingId: bookingId,
                bookingData: request,
              ),
            ),
          ).then((_) => _loadBookings());
        } else if (serviceType.toLowerCase() == 'doctor' || serviceType.toLowerCase() == 'consultation') {
          if (status == 'in_progress') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserActiveConsultationScreen(
                  bookingId: bookingId,
                ),
              ),
            ).then((_) => _loadBookings());
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDetailFile(
                  bookingId: bookingId,
                ),
              ),
            ).then((_) => _loadBookings());
          }
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserUnifiedTrackingScreen(
                bookingId: bookingId,
                serviceType: serviceType,
              ),
            ),
          ).then((_) => _loadBookings());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF152238),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined),
            onPressed: () {},
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1565C0),
          indicatorWeight: 3,
          labelColor: const Color(0xFF1565C0),
          unselectedLabelColor: Colors.grey.shade500,
          labelStyle: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadBookings,
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildAllTab(),
                        _buildList(_inProgressBookings, 'In Progress'),
                        _buildList(_completedBookings, 'Completed'),
                      ],
                    ),
                  ),
                ],
              ),
            )),
    );
  }

  Widget _buildAllTab() {
    if (_allBookings.isEmpty) {
      return const Center(child: Text('No bookings found.', style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        if (_pendingBookings.isNotEmpty) _buildSectionHeader('Pending', _pendingBookings.length, Colors.orange),
        ..._pendingBookings.map((b) => _buildBookingCard(b)),
        if (_inProgressBookings.isNotEmpty) _buildSectionHeader('In Progress', _inProgressBookings.length, const Color(0xFF1565C0)),
        ..._inProgressBookings.map((b) => _buildBookingCard(b)),
        if (_completedBookings.isNotEmpty) _buildSectionHeader('Completed', _completedBookings.length, Colors.green),
        ..._completedBookings.map((b) => _buildBookingCard(b)),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list, String type) {
    if (list.isEmpty) {
      return Center(child: Text('No $type bookings.', style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildBookingCard(list[index]),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> request) {
    final providerData = request['provider'] ?? request['acceptedProvider'] ?? {};
    String pName = 'Provider';
    if (providerData is Map) {
      pName = providerData['fullName'] ?? '${providerData['firstName'] ?? ''} ${providerData['lastName'] ?? ''}'.trim();
      if (pName.isEmpty) pName = providerData['businessName'] ?? 'Provider';
    }
    
    final providerPhoto = (providerData is Map) ? providerData['profilePicture']?.toString() ?? providerData['logo']?.toString() ?? '' : '';
    
    final serviceType = request['serviceType'] ?? 'Unknown';
    final statusRaw = request['status']?.toString().toLowerCase() ?? '';
    final bookingId = request['_id']?.toString() ?? request['id']?.toString() ?? '';
    final dateStr = request['scheduledTime'] ?? request['createdAt'];

    Color statusColor;
    String statusLabel;
    bool isCompleted = false;

    bool isMedicineOffersPending = false;
    if (serviceType.toString().toLowerCase() == 'medicine') {
      final offersList = request['offers'];
      final isPrescr = request['isPrescriptionBased'] == true;
      if (isPrescr && offersList is List && offersList.isNotEmpty) {
        if (statusRaw == 'requested' || statusRaw == 'pending' || statusRaw == 'waiting for pharmacist') {
          isMedicineOffersPending = true;
        }
      }
    }

    if (isMedicineOffersPending) {
      statusColor = Colors.orange;
      statusLabel = 'Approve';
    } else if (statusRaw == 'requested' || statusRaw == 'pending') {
      final offersList = request['offers'];
      if (offersList is List && offersList.isNotEmpty) {
        statusColor = Colors.orange;
        statusLabel = 'Offer Received';
      } else {
        statusColor = Colors.orange;
        statusLabel = 'Pending';
      }
    } else if (statusRaw == 'accepted') {
      statusColor = const Color(0xFF1565C0);
      statusLabel = 'Accepted';
    } else if (statusRaw == 'completed') {
      statusColor = Colors.green;
      statusLabel = 'Completed';
      isCompleted = true;
    } else if (statusRaw == 'cancelled' || statusRaw == 'rejected' || statusRaw == 'expired') {
      statusColor = Colors.red;
      statusLabel = 'Cancelled';
      isCompleted = true;
    } else {
      statusColor = const Color(0xFF1565C0);
      statusLabel = 'In Progress';
    }

    String completedDateStr = '';
    if (isCompleted && request['updatedAt'] != null) {
      final dt = DateTime.tryParse(request['updatedAt'].toString());
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final timeStr = DateFormat('hh:mm a').format(dt.toLocal());
        completedDateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year} • $timeStr';
      }
    } else if (dateStr != null) {
      final dt = DateTime.tryParse(dateStr.toString());
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final timeStr = DateFormat('hh:mm a').format(dt.toLocal());
        completedDateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year} • $timeStr';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _viewBookingDetails(request);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: providerPhoto.isNotEmpty 
                    ? NetworkImage(providerPhoto) 
                    : null,
                child: providerPhoto.isEmpty 
                    ? Icon(_getServiceIcon(serviceType), color: _getServiceColor(serviceType), size: 24)
                    : null,
              ),
              const SizedBox(width: 12),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      pName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF152238),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(_getServiceIcon(serviceType), size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          serviceType.toUpperCase(),
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    if (completedDateStr.isNotEmpty && !isCompleted) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              completedDateStr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right Side (Status + Chevron)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isCompleted && completedDateStr.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Completed on\n$completedDateStr',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Colors.grey.shade600, height: 1.1),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: Colors.black54, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getServiceColor(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'doctor': return AppColors.doctor;
      case 'nurse': return AppColors.nurse;
      case 'pathology': return AppColors.pathology;
      case 'ambulance': return AppColors.ambulance;
      case 'bloodbank': return AppColors.bloodbank;
      case 'pharmacist': return AppColors.pharmacist;
      default: return AppColors.primary;
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'doctor': return Icons.local_hospital;
      case 'nurse': return Icons.healing;
      case 'pathology': return Icons.science;
      case 'ambulance': return Icons.local_shipping;
      case 'bloodbank': return Icons.bloodtype;
      case 'pharmacist': return Icons.local_pharmacy;
      default: return Icons.medical_services;
    }
  }
}
