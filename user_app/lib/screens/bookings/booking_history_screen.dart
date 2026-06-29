import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'booking_details_screen.dart';
import '../booking/order_detail_file.dart';
import '../booking/user_unified_tracking_screen.dart';
import '../booking/order_request_screen.dart';

/// Booking history screen for patients
class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({super.key});

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  late TabController _tabController;

  List<Booking> _activeBookings = [];
  List<Booking> _completedBookings = [];
  List<Booking> _cancelledBookings = [];

  bool _isLoadingActive = true;
  bool _isLoadingCompleted = true;
  bool _isLoadingCancelled = true;

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
    await _apiClient.initialize();

    // Load active bookings
    _loadActiveBookings();

    // Load completed bookings
    _loadCompletedBookings();

    // Load cancelled bookings
    _loadCancelledBookings();
  }

  Future<void> _loadActiveBookings() async {
    setState(() => _isLoadingActive = true);
    try {
      final bookings = await _apiClient.patient.getActiveBookings();
      setState(() {
        _activeBookings = bookings;
        _isLoadingActive = false;
      });
    } catch (e) {
      setState(() => _isLoadingActive = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading active bookings: $e')),
        );
      }
    }
  }

  Future<void> _loadCompletedBookings() async {
    setState(() => _isLoadingCompleted = true);
    try {
      final response =
          await _apiClient.patient.getBookings(status: 'completed');
      final bookings = (response['data'] as List?)
              ?.map((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      setState(() {
        _completedBookings = bookings;
        _isLoadingCompleted = false;
      });
    } catch (e) {
      setState(() => _isLoadingCompleted = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading completed bookings: $e')),
        );
      }
    }
  }

  Future<void> _loadCancelledBookings() async {
    setState(() => _isLoadingCancelled = true);
    try {
      final response =
          await _apiClient.patient.getBookings(status: 'cancelled');
      final bookings = (response['data'] as List?)
              ?.map((e) => Booking.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      setState(() {
        _cancelledBookings = bookings;
        _isLoadingCancelled = false;
      });
    } catch (e) {
      setState(() => _isLoadingCancelled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cancelled bookings: $e')),
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
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList(_activeBookings, _isLoadingActive, 'active'),
          _buildBookingsList(
              _completedBookings, _isLoadingCompleted, 'completed'),
          _buildBookingsList(
              _cancelledBookings, _isLoadingCancelled, 'cancelled'),
        ],
      ),
    );
  }

  Widget _buildBookingsList(
      List<Booking> bookings, bool isLoading, String type) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'active'
                  ? Icons.event_busy
                  : type == 'completed'
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
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
      onRefresh: () async {
        if (type == 'active') {
          await _loadActiveBookings();
        } else if (type == 'completed') {
          await _loadCompletedBookings();
        } else {
          await _loadCancelledBookings();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    Color statusColor;
    IconData statusIcon;

    switch (booking.status.toLowerCase()) {
      case 'requested':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        break;
      case 'on_the_way':
        statusColor = Colors.purple;
        statusIcon = Icons.directions_car;
        break;
      case 'in_progress':
        statusColor = Colors.indigo;
        statusIcon = Icons.hourglass_empty;
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
    }

    final providerName = booking.providerDetails?.fullName ?? 'Provider';
    final serviceType = _formatServiceType(booking.serviceType);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final sType = booking.serviceType.toLowerCase();

          if (booking.status.toLowerCase() == 'requested' ||
              booking.status.toLowerCase() == 'pending') {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OrderRequestScreen(
                  bookingId: booking.id,
                  serviceType: booking.serviceType,
                ),
              ),
            );
            if (result == true) {
              _loadBookings();
            }
            return;
          }

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                if (sType == 'nurse' || sType == 'ambulance' || sType == 'pathology' || sType == 'lab_test' || sType == 'lab test' || sType == 'doctor' || sType == 'consultation') {
                  return OrderDetailFile(bookingId: booking.id);
                } else if (sType == 'bloodbank' || sType == 'blood bank') {
                  return UserUnifiedTrackingScreen(bookingId: booking.id, serviceType: 'bloodbank');
                }
                return OrderDetailFile(bookingId: booking.id);
              },
            ),
          );
          if (result == true) {
            _loadBookings();
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          providerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          serviceType,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatStatus(booking.status),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(booking.scheduledTime),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(booking.scheduledTime),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              if (booking.price > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.currency_rupee,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '₹${booking.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if (booking.status == 'completed' && booking.canBeRated) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showRatingDialog(booking),
                  icon: const Icon(Icons.star, size: 18),
                  label: const Text('Rate Service'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 36),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatServiceType(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'doctor':
        return 'Doctor Consultation';
      case 'nurse':
        return 'Nurse Service';
      case 'ambulance':
        return 'Ambulance Service';
      case 'pharmacist':
      case 'pharmacy':
        return 'Medicine Order';
      case 'pathology':
        return 'Lab Test';
      case 'bloodbank':
        return 'Blood Request';
      default:
        return serviceType;
    }
  }

  String _formatStatus(String status) {
    return status.replaceAll('_', ' ').toUpperCase();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _showRatingDialog(Booking booking) async {
    int rating = 5;
    final reviewController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Rate Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('How was your experience?'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    onPressed: () {
                      setState(() => rating = index + 1);
                    },
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reviewController,
                decoration: const InputDecoration(
                  labelText: 'Review (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      try {
        await _apiClient.patient.rateBooking(
          booking.id,
          rating: rating,
          review:
              reviewController.text.isNotEmpty ? reviewController.text : null,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Rating submitted successfully')),
          );
          _loadBookings();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error submitting rating: $e')),
          );
        }
      }
    }
  }
}
