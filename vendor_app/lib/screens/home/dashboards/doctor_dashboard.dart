import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:api_client/api_client.dart';
import '../../doctor/appointment_details_screen.dart';

class DoctorDashboard extends StatefulWidget {
  const DoctorDashboard({super.key});

  @override
  State<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends State<DoctorDashboard> {
  final _apiClient = OnMintApiClient();
  DashboardStats? _dashboardData;
  List<Booking> _pendingAppointments = [];
  bool _isLoading = true;
  bool _showAllRequests = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (_dashboardData == null) {
      setState(() => _isLoading = true);
    }
    try {
      await _apiClient.initialize();
      if (!_apiClient.isAuthenticated) {
        throw Exception('Not authenticated. Please login again.');
      }
      final dashboardData = await _apiClient.doctor.getDashboard();
      final appointments =
          await _apiClient.doctor.getAppointments();
      setState(() {
        _dashboardData = dashboardData;
        final allBookings = (appointments['data'] as List?)
                ?.map((e) => Booking.fromJson(e as Map<String, dynamic>))
                .toList() ?? [];
        _pendingAppointments = allBookings.where((b) {
          final s = b.status?.toLowerCase() ?? '';
          if (s == 'offer_send' || s == 'offer_sent') return false;
          return s == 'requested' || s == 'pending';
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
      setState(() => _isLoading = false);
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── BLUE HEADER + STATS CARD ──────────────────────────────
                      SizedBox(
                        height: 260,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Blue header
                            Container(
                              width: double.infinity,
                              height: 220,
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
                                      left: 24, right: 24, bottom: 40),
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
                                              'Dr ${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.3,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              user?.specialization ?? 'General Physician',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w400,
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
                            // Pinned stats card
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
                                      '${_pendingAppointments.length}', 
                                      'Requests'
                                    ),
                                    _buildDivider(),
                                    _buildStatItem(
                                      '${_dashboardData?.activeVisits ?? 0}', 
                                      'Active'
                                    ),
                                    _buildDivider(),
                                    _buildStatItem(
                                      '${_dashboardData?.completedBookings ?? _dashboardData?.totalVisits ?? 0}', 
                                      'Completed'
                                    ),
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
                              'Consultation Requests',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF152238),
                                  letterSpacing: 0.1),
                            ),
                            const SizedBox(width: 8),
                            if (_pendingAppointments.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${_pendingAppointments.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            if (_pendingAppointments.length > 1)
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
                      const SizedBox(height: 16),

                      // ─── CONSULTATION CARDS ────────────────────────────────────
                      if (_pendingAppointments.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Center(
                            child: Text(
                              'No new consultation requests.',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                          itemCount: (!_showAllRequests && _pendingAppointments.length > 1)
                              ? 1
                              : _pendingAppointments.length,
                          itemBuilder: (context, index) {
                            return _buildPatientCard(_pendingAppointments[index]);
                          },
                        ),
                      const Spacer(),

                      // ─── MANAGE CONSULTATIONS BANNER ───────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 18),
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
                                              size: 52, color: const Color(0xFF1565C0)),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                          color: Colors.blue)),
                                  const SizedBox(width: 4),
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue)),
                                  const SizedBox(width: 4),
                                  Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.blue)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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

  // ─── STAT ITEM ───────────────────────────────────────────────────────────
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

  // ─── PATIENT CARD ────────────────────────────────────────────────────────
  Widget _buildPatientCard(Booking appointment) {
    final patientName =
        appointment.patientDetails?.fullName ?? 'Patient';
    final timeStr = _formatTime(appointment.scheduledTime);
    final symptoms = appointment.notes?.isNotEmpty == true
        ? appointment.notes!
        : 'Fever, Cough, Headache';
    final price = appointment.price;
    final patientImage = appointment.patientDetails?.profilePicture;

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
                  image: patientImage != null
                      ? DecorationImage(
                          image: NetworkImage(patientImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name + Time row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          patientName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF152238),
                          ),
                        ),
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
                    // Symptoms in blue
                    Text(
                      symptoms,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 5),
                    // Location + Price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 3),
                            Text(
                              appointment.location.address ?? '3.1 km away',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(0)}',
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
          // View Details button - shorter height
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppointmentDetailsScreen(
                        appointmentId: appointment.id),
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

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
