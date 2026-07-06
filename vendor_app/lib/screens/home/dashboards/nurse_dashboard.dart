import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../widgets/active_booking_floating_widget.dart';
import '../../nurse/booking_details_screen_enhanced.dart';
import '../../nurse/active_booking_screen.dart';
import '../../nurse/bookings_screen.dart';
import '../../../config/app_config.dart';
import '../../nurse/fill_price_nurse_screen.dart';

class NurseDashboard extends StatefulWidget {
  const NurseDashboard({super.key});

  @override
  State<NurseDashboard> createState() => _NurseDashboardState();
}

class _NurseDashboardState extends State<NurseDashboard> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _pendingBookings = [];
  bool _isLoading = true;
  bool _showAllRequests = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();

      final dashboardFuture = _apiClient.nurse.getDashboard();
      final regularBookingsFuture = _apiClient.nurse.getBookings(status: 'requested');
      final realtimeBookingsFuture = _apiClient.nurse.getRealtimeBookings(status: 'pending');

      final results = await Future.wait(
          [dashboardFuture, regularBookingsFuture, realtimeBookingsFuture]);

      final data = results[0];
      final regularBookingsResponse = results[1];
      final realtimeBookingsResponse = results[2];

      if (mounted) {
        setState(() {
          _dashboardData = data;

          final regularBookings =
              regularBookingsResponse['data'] ?? regularBookingsResponse;
          final realtimeBookings =
              realtimeBookingsResponse['data'] ?? realtimeBookingsResponse;

          List<Map<String, dynamic>> allBookings = [];

          if (regularBookings is List) {
            allBookings.addAll(
                regularBookings.map((e) => Map<String, dynamic>.from(e)));
          }

          List realtimeList = [];
          if (realtimeBookings is List) {
            realtimeList = realtimeBookings;
          } else if (realtimeBookings is Map && realtimeBookings['bookings'] is List) {
            realtimeList = realtimeBookings['bookings'];
          }

          if (realtimeList.isNotEmpty) {
            allBookings.addAll(realtimeList.map((e) => {
                  ...Map<String, dynamic>.from(e),
                  'isRealtimeBooking': true,
                }));
          }

          final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
          _pendingBookings = allBookings
              .where((b) {
                final status =
                    b['status']?.toString().toLowerCase() ?? '';
                if (status == 'offer_send' || status == 'offer_sent') return false;
                final isPending = status == 'requested' || status == 'pending';
                if (!isPending) return false;

                bool hasOffered = b['hasOffered'] == true;
                final offers = b['offers'] as List?;
                if (offers != null && currentUserId != null) {
                  hasOffered = hasOffered || offers.any((o) {
                    final vId = o['vendorId'];
                    return vId == currentUserId || (vId is Map && vId['_id'] == currentUserId);
                  });
                }
                if (hasOffered) return false;
                return true;
              })
              .toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.showError('Failed to load dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // ─── BLUE HEADER + STATS CARD ──────────────────────────────
                      SizedBox(
                        height: 250,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Blue header
                            Container(
                              width: double.infinity,
                              height: 200,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(24),
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                              child: SafeArea(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      left: 24, right: 24, bottom: 20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Circular profile image
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                              color: Colors.white.withOpacity(0.8),
                                              width: 2.5),
                                          image: user?.profilePicture != null
                                              ? DecorationImage(
                                                  image: NetworkImage(
                                                      user!.profilePicture!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: user?.profilePicture == null
                                            ? const Icon(Icons.person,
                                                size: 44, color: Colors.blue,)
                                            : null,
                                      ),
                                      const SizedBox(width: 18),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              user?.fullName ?? 'Nurse',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            const Text(
                                              'Certified Nurse Provider',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            // Pinned white stats card overlapping bottom
                            Positioned(
                              bottom: -15,
                              left: 24,
                              right: 24,
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.shade900.withOpacity(0.08),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    _buildStatItem(
                                        '${_pendingBookings.length}',
                                        'Pending'),
                                    Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.grey.shade200),
                                    _buildStatItem(
                                        '${_dashboardData?['activeBookings'] ?? 0}',
                                        'Active'),
                                    Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.grey.shade200),
                                    _buildStatItem(
                                        '${_dashboardData?['completedBookings'] ?? 0}',
                                        'Completed'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Section Title row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            const Text(
                              'Pending Request',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF152238),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (_pendingBookings.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_pendingBookings.length}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.blue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            if (_pendingBookings.length > 1)
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showAllRequests = !_showAllRequests;
                                  });
                                },
                                child: Text(
                                  _showAllRequests ? 'View Less' : 'View All',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ─── BOOKING CARDS ─────────────────────────────────────────
                      if (_pendingBookings.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              'No requests right now.',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: _pendingBookings
                                .take(_showAllRequests ? _pendingBookings.length : 1)
                                .map((b) => _buildBookingCard(b))
                                .toList(),
                          ),
                        ),
                      const Spacer(),

                      // ─── Pinned MANAGE BANNER at the bottom ────────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 5, 20, 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8EEF9),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          child: Icon(Icons.assignment_outlined,
                                              size: 52,
                                              color: const Color(0xFF1565C0)),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            width: 30,
                                            height: 30,
                                            decoration: const BoxDecoration(
                                              color: Colors.blue,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.add,
                                                size: 18, color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerLeft,
                                          child: const Text(
                                            'Manage Your\nConsultations Easily',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF152238),
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Check your requests, track consultations, and manage your progress all in one place.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade600,
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue,
                                      )),
                                  const SizedBox(width: 4),
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue,
                                      )),
                                  const SizedBox(width: 4),
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.blue,
                                      )),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 36,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final patientData = booking['patient'];
    String patientName = 'Patient';
    String? patientImage;

    if (patientData is Map) {
      patientName = patientData['fullName'] ??
          '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'
              .trim();
      patientImage = patientData['profilePicture'];
    }

    // Time
    String timeStr = '';
    if (booking['scheduledTime'] != null) {
      final dt = DateTime.tryParse(booking['scheduledTime'].toString());
      if (dt != null) {
        final h = dt.hour > 12
            ? dt.hour - 12
            : (dt.hour == 0 ? 12 : dt.hour);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        timeStr =
            '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
      }
    }

    final notes = booking['notes']?.toString() ?? 'Medical Emergency';
    final fees = (booking['fees'] ?? booking['price'] ?? 300);
    final address = booking['location']?['address'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient avatar
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                  image: DecorationImage(
                    image: (patientImage != null && patientImage.isNotEmpty)
                        ? NetworkImage(patientImage)
                        : AssetImage((patientData is Map && patientData['gender']?.toString().toLowerCase() == 'female')
                            ? 'assets/images/female_profile.png'
                            : 'assets/images/male_profile.png') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            patientName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF152238),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (timeStr.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.access_time,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 3),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notes,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 12, color: Colors.grey),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  address.isNotEmpty ? address : '3.1 km away',
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹$fees',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.blue,
                              ),
                            ),
                            const Text(
                              'Consultation Fee',
                              style: TextStyle(
                                  fontSize: 9, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // View Details button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                final bookingId =
                    booking['_id'] ?? booking['id'] ?? '';
                final statusRaw = booking['status']?.toString().toLowerCase() ?? '';
                
                Widget targetScreen;
                if (statusRaw == 'requested' || statusRaw == 'pending') {
                  final user = context.read<AuthProvider>().currentUser;
                  final userCity = user?.city?.trim().toLowerCase() ?? '';
                  final userState = user?.state?.trim().toLowerCase() ?? '';
                  
                  final bookingCity = booking['city']?.toString().trim().toLowerCase() ?? '';
                  final bookingState = booking['state']?.toString().trim().toLowerCase() ?? '';
                  
                  final cleanUserCity = userCity.replaceAll(RegExp(r'\s+'), '');
                  final cleanUserState = userState.replaceAll(RegExp(r'\s+'), '');
                  final cleanBookingCity = bookingCity.replaceAll(RegExp(r'\s+'), '');
                  final cleanBookingState = bookingState.replaceAll(RegExp(r'\s+'), '');

                  final isMatchingLocation = (cleanBookingCity.isEmpty && cleanBookingState.isEmpty) ||
                      (cleanUserCity.isNotEmpty && cleanUserState.isNotEmpty &&
                       cleanBookingCity == cleanUserCity &&
                       cleanBookingState == cleanUserState);

                  if (AppConfig.useNewFlow && isMatchingLocation) {
                    targetScreen = FillPriceNurseScreen(
                      bookingId: bookingId,
                      bookingData: booking,
                    );
                  } else {
                    targetScreen = BookingDetailsScreenEnhanced(
                      bookingId: bookingId,
                      bookingData: booking,
                    );
                  }
                } else {
                  targetScreen = BookingDetailsScreenEnhanced(
                    bookingId: bookingId,
                    bookingData: booking,
                  );
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => targetScreen,
                  ),
                ).then((_) => _loadDashboard());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
