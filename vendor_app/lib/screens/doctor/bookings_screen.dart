import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'appointment_details_screen.dart';
import 'dart:async';

/// Bookings management screen for doctors - Complete consultation flow
class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

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
      final allBookings = (response['data'] as List?)
          ?.map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];

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
      appBar: AppBar(
        title: const Text('My Bookings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Requested'),
                  if (_requestedBookings.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_requestedBookings.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Accepted'),
                  if (_acceptedBookings.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_acceptedBookings.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Completed'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(_requestedBookings, _isLoadingRequested, 'requested'),
          _buildBookingsList(_acceptedBookings, _isLoadingAccepted, 'accepted'),
          _buildBookingsList(_completedBookings, _isLoadingCompleted, 'completed'),
        ],
      ),
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
              type == 'requested' ? Icons.pending_actions : 
              type == 'accepted' ? Icons.event_available : 
              Icons.check_circle_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type} bookings',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
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
          final booking = bookings[index];
          return _buildBookingCard(booking, type);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking, String type) {
    final patientName = booking.patientDetails?.fullName ?? 'Patient';
    final patientPhone = booking.patientDetails?.phone ?? '';
    
    // Calculate age from dateOfBirth if available
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
    final consultationType = booking.consultationType ?? 'Video Consultation';
    
    Color statusColor;
    String statusLabel;
    bool isCompleted = false;
    
    switch (type) {
      case 'requested':
        statusColor = Colors.orange;
        statusLabel = 'Pending';
        break;
      case 'accepted':
        statusColor = const Color(0xFF1565C0);
        statusLabel = 'Accepted';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusLabel = 'Completed';
        isCompleted = true;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = type.toUpperCase();
    }

    String completedDateStr = '';
    if (isCompleted && booking.scheduledTime != null) {
      final dt = booking.scheduledTime!;
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      completedDateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
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
        onTap: () => _navigateToDetails(booking.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade50,
                    backgroundImage: booking.patientDetails?.profilePicture != null &&
                            booking.patientDetails!.profilePicture!.isNotEmpty
                        ? NetworkImage(booking.patientDetails!.profilePicture!)
                        : AssetImage(patientGender.toLowerCase() == 'female'
                            ? 'assets/images/female_profile.png'
                            : 'assets/images/male_profile.png') as ImageProvider,
                  ),
                  const SizedBox(width: 12),
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          patientName.isNotEmpty ? patientName : 'Patient Name',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF152238),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              '${patientAge > 0 ? "$patientAge Years" : "--"}',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 8),
                            Icon(patientGender.toLowerCase() == 'female' ? Icons.female : Icons.male, size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              patientGender,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.medical_services_outlined, size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              consultationType,
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              '${_formatDate(booking.scheduledTime)} • ${_formatTime(booking.scheduledTime)}',
                              style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
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
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[500]!.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.note, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (type == 'accepted') ...[
              Divider(color: Colors.grey.shade200, height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: () {
                  if (booking.prescription != null) {
                    return ElevatedButton(
                      onPressed: () => _navigateToDetails(booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 36),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Complete Appointment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    );
                  } else if (booking.videoCallCompleted == true) {
                    return ElevatedButton(
                      onPressed: () => _navigateToDetails(booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 36),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Create Prescription', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    );
                  } else {
                    return ElevatedButton(
                      onPressed: () => _navigateToDetails(booking.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 36),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Start Consultation', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    );
                  }
                }(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (dateOnly == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _quickAccept(String bookingId) async {
    try {
      await _apiClient.doctor.acceptAppointment(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment accepted')),
        );
        _loadAllBookings();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _quickReject(String bookingId) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Appointment'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Reason (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason != null) {
      try {
        await _apiClient.doctor.rejectAppointment(bookingId, reason: reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment rejected')),
          );
          _loadAllBookings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
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
