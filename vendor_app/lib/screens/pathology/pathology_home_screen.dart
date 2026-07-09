import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'lab_test_request_details_screen.dart';
import 'lab_test_booking_screen.dart';
import 'pathology_bookings_screen.dart';
import '../../config/app_colors.dart';
import '../../config/app_config.dart';
import 'fill_price_labtest_screen.dart';
import '../booking/waiting_for_patient_screen.dart';
import '../home/widgets/active_booking_floating_widget.dart';
import 'dart:async';

class PathologyHomeScreen extends StatefulWidget {
  const PathologyHomeScreen({super.key});

  @override
  State<PathologyHomeScreen> createState() => _PathologyHomeScreenState();
}

class _PathologyHomeScreenState extends State<PathologyHomeScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _dashboardData;
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _activeBookings = [];
  bool _isLoading = true;
  bool _showAllRequests = false;
  static bool _mockDataHandled = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadDashboard();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    if (_dashboardData == null) {
      setState(() => _isLoading = true);
    }
    try {
      await _apiClient.initialize();

      final dashboardFuture = _apiClient.pathology.getDashboard();
      final allBookingsFuture = _apiClient.pathology.getBookings(limit: 100);

      final results = await Future.wait([dashboardFuture, allBookingsFuture]);

      final data = results[0];
      final bookingsResponse = results[1];

      if (mounted) {
        setState(() {
          _dashboardData = data;
          
          final bookingsList = bookingsResponse['data'] ?? bookingsResponse;
          
          List<Map<String, dynamic>> allBookings = [];
          if (bookingsList is List) {
            allBookings.addAll(bookingsList.map((e) => Map<String, dynamic>.from(e)));
          }

          // Sort bookings: requested first, then active, then completed
          // Active = anything not requested, completed, rejected, cancelled
          int getPriority(String status) {
            final s = status.toLowerCase();
            if (s == 'requested' || s == 'pending') return 0;
            if (s == 'completed' || s == 'cancelled' || s == 'rejected') return 2;
            if (s == 'offer_send' || s == 'offer_sent') return 3; // ignored
            return 1; // active (accepted, on_the_way, sample_collected)
          }

          allBookings.sort((a, b) {
            final pA = getPriority(a['status']?.toString() ?? '');
            final pB = getPriority(b['status']?.toString() ?? '');
            if (pA != pB) return pA.compareTo(pB);
            
            final timeA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime(0);
            final timeB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime(0);
            return timeB.compareTo(timeA); // newest first
          });

          final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
          _pendingBookings = allBookings.where((b) {
            final status = b['status']?.toString().toLowerCase() ?? '';
            if (status == 'offer_send' || status == 'offer_sent') return false;
            final isPending = getPriority(status) == 0;
            if (!isPending) return false;
            
            bool hasOffered = b['hasOffered'] == true;
            final offers = b['offers'] as List?;
            bool isRejectedByMe = false;
            if (offers != null) {
              hasOffered = hasOffered || offers.any((o) {
                if (currentUserId == null) return false;
                final vId = o is Map ? (o['vendorId'] ?? o['vendor'] ?? o['vendor_id']) : null;
                bool isMyOffer = vId == currentUserId || (vId is Map && (vId['_id'] == currentUserId || vId['id'] == currentUserId));
                if (isMyOffer && o is Map && o['status'] == 'rejected') isRejectedByMe = true;
                return isMyOffer;
              });
            }
            if (isRejectedByMe) return false;
            if (hasOffered) return false;
            
            return true;
          }).toList();
          _activeBookings = allBookings.where((b) {
            final status = b['status']?.toString().toLowerCase() ?? '';
            if (status == 'offer_send' || status == 'offer_sent') return false;
            return getPriority(status) == 1;
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Fallback for UI demonstration if API fails or is not implemented
        _dashboardData = {
          'todayRequests': 12,
          'accepted': 8,
          'completed': 5,
        };
        _pendingBookings = [];
        _activeBookings = [];
        int _completedCount = 0;
        _isLoading = false;
      }
    }
  }

  int get _completedCount {
    if (_dashboardData == null) return 0;
    return _dashboardData?['totalTests'] ?? _dashboardData?['completed'] ?? 0;
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
      backgroundColor: const Color(0xFFF4F6FB),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadDashboard,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                        color: Color(0xFF0D47A1), // Dark blue from image
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(24),
                          bottomRight: Radius.circular(24),
                        ),
                      ),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20),
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
                                  image: user?.profilePicture != null && user!.profilePicture!.isNotEmpty
                                      ? DecorationImage(
                                          image: NetworkImage(user!.profilePicture!),
                                          fit: BoxFit.cover,
                                          onError: (exception, stackTrace) {
                                            // Handle invalid image URL
                                          },
                                        )
                                      : null,
                                ),
                                child: (user?.profilePicture == null || user!.profilePicture!.isEmpty)
                                    ? const Icon(Icons.person, size: 44, color: Color(0xFF0D47A1))
                                    : null,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user?.fullName ?? 'Shubham Singh',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    const Text(
                                      '( Lab Technician )',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
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

                    // Stats card
                    Positioned(
                      bottom: 0,
                      left: 20,
                      right: 20,
                      child: Container(
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _buildStatItem(
                              '${_pendingBookings.length}',
                              "Pending",
                            ),
                            _buildDivider(),
                            _buildStatItem(
                              '${_activeBookings.length}',
                              "Accepted",
                            ),
                            _buildDivider(),
                            _buildStatItem(
                              '${_completedCount}',
                              "Completed",
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── LAB TEST REQUESTS HEADER ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    const Text(
                      'Lab Test Requests',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF152238),
                        letterSpacing: 0.1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_pendingBookings.where((b) => (b['status']?.toString().toLowerCase() ?? '') == 'requested').length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllRequests = !_showAllRequests;
                        });
                      },
                      child: Text(
                        _showAllRequests ? 'View Less' : 'View All',
                        style: const TextStyle(
                          color: Color(0xFF0D47A1),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ─── BOOKING CARDS ─────────────────────────────────────────
              if (_pendingBookings.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Center(
                    child: Text(
                      'No bookings available right now.',
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

              const SizedBox(height: 16),

                          ],
                        ),
                      ),
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // ─── MANAGE BANNER ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
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
                              size: 52, color: const Color(0xFF0D47A1)),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0D47A1),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: const Text(
                            'Manage Your\nConsultations Easily',
                            style: TextStyle(
                              fontSize: 15,
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
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0D47A1),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Active Service Widget
          if (_activeBookings.isNotEmpty || _pendingBookings.isNotEmpty)
            Positioned(
              bottom: 24,
              right: 24,
              child: Builder(
                builder: (context) {
                  final targetBookingData = _activeBookings.isNotEmpty
                      ? _activeBookings.first
                      : _pendingBookings.first;
                  return ActiveBookingFloatingWidget(
                    serviceType: 'lab_test',
                    bookingDetails: targetBookingData,
                    onTap: () {
                      if (_activeBookings.length > 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PathologyBookingsScreen(),
                          ),
                        );
                        return;
                      }

                      final targetBookingId = targetBookingData['_id'].toString();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LabTestBookingScreen(
                            bookingId: targetBookingId,
                            bookingData: targetBookingData,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
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
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF152238),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
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
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final patientData = booking['patient'];
    String patientName = 'Patient';
    String patientAgeGender = '35 Years / Male';
    String? patientImage;

    if (patientData is Map) {
      patientName = patientData['fullName'] ??
          '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
      patientImage = patientData['profilePicture'];
      if (patientData['age'] != null && patientData['gender'] != null) {
        patientAgeGender = '${patientData['age']} Years / ${patientData['gender']}';
      }
    }

    String timeStr = '06:45 PM';
    if (booking['scheduledTime'] != null) {
      final dt = DateTime.tryParse(booking['scheduledTime'].toString());
      if (dt != null) {
        final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        timeStr = '${h.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} $period';
      }
    }

    String testName = 'CBC (Complete Blood Count)';
    if (booking['tests'] != null && booking['tests'] is List && booking['tests'].isNotEmpty) {
      testName = booking['tests'][0]['name'] ?? testName;
    }

    final fees = (booking['fees'] ?? booking['price'] ?? 300);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
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
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF152238),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.access_time, size: 13, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      testName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF152238),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            patientAgeGender,
                            style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Price hidden for vendor apps
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (booking['status']?.toString().toLowerCase() == 'requested' || booking['status']?.toString().toLowerCase() == 'pending') 
                      ? Colors.orange.withOpacity(0.1) 
                      : (booking['status']?.toString().toLowerCase() == 'completed' ? Colors.green.withOpacity(0.1) : const Color(0xFF1565C0).withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  booking['status']?.toString().toUpperCase() ?? 'PENDING',
                  style: TextStyle(
                    fontSize: 9,
                    color: (booking['status']?.toString().toLowerCase() == 'requested' || booking['status']?.toString().toLowerCase() == 'pending')
                        ? Colors.orange
                        : (booking['status']?.toString().toLowerCase() == 'completed' ? Colors.green : const Color(0xFF1565C0)),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // View Details button
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                final bookingId = booking['_id'] ?? booking['id'] ?? 'dummy_id';
                final status = booking['status']?.toString().toLowerCase() ?? '';
                final isPending = status == 'requested' || status == 'pending';
                
                Widget targetScreen;
                if (isPending) {
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

                  final currentUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id;
                  final offers = booking['offers'] as List?;
                  bool hasOffered = booking['hasOffered'] == true;
                  bool isRejectedByMe = false;
                  if (offers != null) {
                    hasOffered = hasOffered || offers.any((o) {
                      if (currentUserId == null) return false;
                      final vId = o is Map ? (o['vendorId'] ?? o['vendor'] ?? o['vendor_id']) : null;
                      bool isMyOffer = vId == currentUserId || (vId is Map && (vId['_id'] == currentUserId || vId['id'] == currentUserId));
                      if (isMyOffer && o is Map && o['status'] == 'rejected') isRejectedByMe = true;
                      return isMyOffer;
                    });
                  }

                  if (AppConfig.useNewFlow && hasOffered && !isRejectedByMe) {
                    targetScreen = WaitingForPatientScreen(bookingId: bookingId, bookingData: booking);
                  } else if (AppConfig.useNewFlow && isMatchingLocation) {
                    targetScreen = FillPriceLabtestScreen(bookingId: bookingId, bookingData: booking);
                  } else {
                    targetScreen = LabTestRequestDetailsScreen(bookingId: bookingId, bookingData: booking);
                  }
                } else {
                  targetScreen = LabTestBookingScreen(bookingId: bookingId, bookingData: booking);
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => targetScreen,
                  ),
                ).then((result) {
                  if (result == true && bookingId == '649b5c3e7b1a2c3f1d4e5f6a') {
                    _mockDataHandled = true;
                  }
                  _loadDashboard();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
