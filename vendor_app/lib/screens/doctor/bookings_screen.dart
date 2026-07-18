import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'appointment_details_screen.dart';
import 'dart:async';

/// Bookings management screen for doctors - Complete consultation flow
import 'doctor_main_screen.dart';
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key, this.isTab = true});
  final bool isTab;

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  late TabController _tabController;
  
  List<Booking> _requestedBookings = [];
  List<Booking> _acceptedBookings = [];
  List<Booking> _completedBookings = [];
  
  bool _isLoadingRequested = true;
  bool _isLoadingAccepted = true;
  bool _isLoadingCompleted = true;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllBookings();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) _loadAllBookings();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllBookings() async {
    if (_requestedBookings.isEmpty && _acceptedBookings.isEmpty && _completedBookings.isEmpty) {
      setState(() {
        _isLoadingRequested = true;
        _isLoadingAccepted = true;
        _isLoadingCompleted = true;
      });
    }

    try {
      await _apiClient.initialize();
      final response = await _apiClient.doctor.getAppointments(page: 1, limit: 100);
      var allBookings = (response['data'] as List?)
          ?.map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];

      // Deduplicate bookings by ID
      final Set<String> seenIds = {};
      allBookings.retainWhere((b) {
        if (b.id == null || b.id.isEmpty) return true;
        if (seenIds.contains(b.id)) return false;
        seenIds.add(b.id);
        return true;
      });

      allBookings.sort((a, b) {
        return b.createdAt.compareTo(a.createdAt);
      });

      setState(() {
        _requestedBookings = allBookings.where((b) {
          final s = b.status?.toLowerCase() ?? '';
          return s == 'requested' || s == 'pending';
        }).toList();
        _acceptedBookings = allBookings.where((b) {
          final s = b.status?.toLowerCase() ?? '';
          return s == 'accepted' || s == 'confirmed' || s == 'scheduled';
        }).toList();
        _completedBookings = allBookings.where((b) {
          final s = b.status?.toLowerCase() ?? '';
          return s == 'completed' || s == 'cancelled' || s == 'rejected';
        }).toList();

        _isLoadingRequested = false;
        _isLoadingAccepted = false;
        _isLoadingCompleted = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingRequested = false;
        _isLoadingAccepted = false;
        _isLoadingCompleted = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: !widget.isTab ? IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const DoctorMainScreen()),
                (route) => false,
              );
            }
          },
        ) : null,
        centerTitle: true,
        title: const Text('My Booking', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins')),
        iconTheme: const IconThemeData(color: Colors.black),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue.shade700,
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: Colors.blue.shade700,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontFamily: 'Poppins', fontSize: 14),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'In Progress'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllTab(),
          _buildBookingsList([..._requestedBookings, ..._acceptedBookings], _isLoadingRequested || _isLoadingAccepted, 'in_progress'),
          _buildBookingsList(_completedBookings, _isLoadingCompleted, 'completed'),
        ],
      ),
    );
  }

  Widget _buildAllTab() {
    if (_isLoadingRequested || _isLoadingAccepted || _isLoadingCompleted) {
      return const Center(child: CircularProgressIndicator());
    }

    final inProgress = [..._requestedBookings, ..._acceptedBookings];
    final completed = _completedBookings;

    return RefreshIndicator(
      onRefresh: _loadAllBookings,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
          if (inProgress.isNotEmpty) ...[
            _buildSectionHeader('In Progress', inProgress.length, Colors.blue.shade50, Colors.blue.shade700),
            const SizedBox(height: 12),
            ...inProgress.map((b) => _buildBookingCard(b, 'in_progress')),
            const SizedBox(height: 24),
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionHeader('Completed', completed.length, Colors.green.shade50, Colors.green.shade700),
            const SizedBox(height: 12),
            ...completed.map((b) => _buildBookingCard(b, 'completed')),
          ],
          if (inProgress.isEmpty && completed.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(top: 100),
                child: Text('No bookings available', style: TextStyle(color: Colors.grey)),
              ),
            ),
          const SizedBox(height: 24),
          if (inProgress.isNotEmpty || completed.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0F5FF),
                  foregroundColor: Colors.blue.shade700,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('View All Bookings', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Poppins')),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color badgeBgColor, Color badgeTextColor) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF152238), fontFamily: 'Poppins'),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: badgeBgColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(color: badgeTextColor, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingsList(List<Booking> bookings, bool isLoading, String type) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'in_progress' ? Icons.pending_actions : Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No  bookings',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAllBookings,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          return _buildBookingCard(bookings[index], type);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, String type) {
    final patientName = booking.patientDetails?.fullName ?? 'Patient';
    
    int patientAge = 0;
    if (booking.patientDetails?.dateOfBirth != null) {
      final birthDate = booking.patientDetails!.dateOfBirth!;
      final today = DateTime.now();
      patientAge = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        patientAge--;
      }
    }
    
    final patientGender = booking.patientDetails?.gender ?? 'Male';
    
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;
    bool isCompleted = type == 'completed' || (booking.status?.toLowerCase() == 'completed');
    bool isRequested = booking.status?.toLowerCase() == 'requested' || booking.status?.toLowerCase() == 'pending';
    
    if (isCompleted) {
      statusBgColor = const Color(0xFFE8F5E9);
      statusTextColor = const Color(0xFF4CAF50);
      statusLabel = 'Completed';
    } else if (isRequested) {
      statusBgColor = const Color(0xFFFFF4E5);
      statusTextColor = const Color(0xFFFF9800);
      statusLabel = 'Requested';
    } else {
      statusBgColor = const Color(0xFFF0F5FF);
      statusTextColor = const Color(0xFF1565C0);
      statusLabel = 'In Progress';
    }

    String completedDateStr = '';
    if (booking.status == 'completed') {
      DateTime? completedDate;
      if (booking.rawData != null && booking.rawData!['endTime'] != null) {
        completedDate = DateTime.tryParse(booking.rawData!['endTime'].toString());
      }
      if (completedDate == null && booking.rawData != null && booking.rawData!['updatedAt'] != null) {
        completedDate = DateTime.tryParse(booking.rawData!['updatedAt'].toString());
      }
      completedDate ??= booking.createdAt; // Fallback to createdAt if nothing else

      completedDateStr = 'Completed on\n${completedDate.day.toString().padLeft(2, '0')}/${completedDate.month.toString().padLeft(2, '0')}/${completedDate.year}';
    } else {
      completedDateStr = 'Requested on\n${booking.createdAt.day.toString().padLeft(2, '0')}/${booking.createdAt.month.toString().padLeft(2, '0')}/${booking.createdAt.year}';
    }
    
    String addressText = booking.location.address ?? 'Address not provided';

    // Sometimes backend address is literally formatted as "Instance of 'Address'" due to bug
    if (addressText.contains('Instance of') || addressText.contains('Instance of \'Address\'')) {
      if (booking.patientDetails != null && booking.patientDetails!.address != null) {
         addressText = booking.patientDetails!.address!.toString();
      } else if (booking.rawData != null && booking.rawData!['location'] != null && booking.rawData!['location'] is Map) {
         final locMap = booking.rawData!['location'] as Map;
         if (locMap['address'] is Map) {
           final addrMap = locMap['address'] as Map;
           addressText = '${addrMap['street'] ?? ''}, ${addrMap['city'] ?? ''}, ${addrMap['state'] ?? ''}'.trim().replaceAll(RegExp(r'^,+|,+$'), '');
         }
      } else {
         addressText = 'Address not provided';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToDetails(booking.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                  image: booking.patientDetails?.profilePicture != null && booking.patientDetails!.profilePicture!.isNotEmpty
                      ? DecorationImage(image: NetworkImage(booking.patientDetails!.profilePicture!), fit: BoxFit.cover)
                      : DecorationImage(image: AssetImage(patientGender.toLowerCase() == 'female' ? 'assets/images/female_profile.png' : 'assets/images/male_profile.png'), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 16),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName.isNotEmpty ? patientName : 'Patient Name',
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF152238)),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          '$patientAge Years',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade700),
                        ),
                        const SizedBox(width: 8),
                        Text('|', style: TextStyle(color: Colors.grey.shade400)),
                        const SizedBox(width: 8),
                        Icon(patientGender.toLowerCase() == 'female' ? Icons.female : Icons.male, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          patientGender,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            addressText,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade700, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Status Badge & Arrow
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: statusTextColor, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.black, size: 20),
                    ],
                  ),
                  if (completedDateStr.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.only(right: 28), // align with badge left
                      child: Text(
                        completedDateStr,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey.shade600, height: 1.2),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(String bookingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppointmentDetailsScreen(
          appointmentId: bookingId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadAllBookings();
      }
    });
  }
}
