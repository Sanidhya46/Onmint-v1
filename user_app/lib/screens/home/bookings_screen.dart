import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import '../../config/app_colors.dart';

class BookingsScreen extends StatefulWidget {
  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen>
    with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  late TabController _tabController;
  List<Booking> _bookings = [];
  bool _isLoading = true;
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final filters = ['all', 'requested', 'completed', 'cancelled'];
      setState(() => _currentFilter = filters[_tabController.index]);
      _loadBookings();
    }
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);

    try {
      await _apiClient.initialize();
      final result = await _apiClient.patient.getBookings(
        status: _currentFilter == 'all' ? null : _currentFilter,
      );

      setState(() {
        _bookings = (result['bookings'] as List?)
                ?.map((e) => Booking.fromJson(e))
                .toList() ??
            [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ToastUtils.showError('Failed to load bookings');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: SafeArea(top: false, bottom: true, child: RefreshIndicator(
        onRefresh: _loadBookings,
        child: _isLoading
            ? const LoadingWidget(message: 'Loading bookings...')
            : _bookings.isEmpty
                ? EmptyStateWidget(
                    icon: Icons.calendar_today_outlined,
                    title: 'No Bookings',
                    message: _currentFilter == 'all'
                        ? 'You haven\'t made any bookings yet'
                        : 'No $_currentFilter bookings found',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return _buildBookingCard(booking);
                    },
                  ),
      )),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildServiceIcon(booking.serviceType),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getServiceTitle(booking.serviceType),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (booking.providerDetails != null)
                          Text(
                            booking.providerDetails!.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildStatusChip(booking.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(booking.scheduledTime),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time,
                      size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Text(
                    _formatTime(booking.scheduledTime),
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
              if (booking.location.address != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.location.address!,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${booking.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Row(
                    children: [
                      if (booking.canBeCancelled)
                        TextButton(
                          onPressed: () => _cancelBooking(booking),
                          child: const Text('Cancel'),
                        ),
                      if (booking.canBeRated)
                        ElevatedButton(
                          onPressed: () => _rateBooking(booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Rate'),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceIcon(String serviceType) {
    IconData icon;
    Color color;

    switch (serviceType.toLowerCase()) {
      case 'doctor':
        icon = Icons.medical_services;
        color = AppColors.doctor;
        break;
      case 'nurse':
        icon = Icons.local_hospital;
        color = AppColors.nurse;
        break;
      case 'ambulance':
        icon = Icons.local_shipping;
        color = AppColors.ambulance;
        break;
      case 'pharmacy':
        icon = Icons.medication;
        color = AppColors.pharmacy;
        break;
      case 'bloodbank':
        icon = Icons.bloodtype;
        color = AppColors.bloodbank;
        break;
      case 'pathology':
        icon = Icons.science;
        color = AppColors.pathology;
        break;
      default:
        icon = Icons.medical_services;
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    String label;

    switch (status.toLowerCase()) {
      case 'requested':
        color = AppColors.warning;
        label = 'Requested';
        break;
      case 'accepted':
        color = AppColors.info;
        label = 'Accepted';
        break;
      case 'on_the_way':
        color = AppColors.info;
        label = 'On the Way';
        break;
      case 'in_progress':
        color = AppColors.info;
        label = 'In Progress';
        break;
      case 'completed':
        color = AppColors.success;
        label = 'Completed';
        break;
      case 'cancelled':
        color = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        color = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  String _getServiceTitle(String serviceType) {
    switch (serviceType.toLowerCase()) {
      case 'doctor':
        return 'Doctor Consultation';
      case 'nurse':
        return 'Nursing Service';
      case 'ambulance':
        return 'Ambulance Service';
      case 'pharmacy':
        return 'Medicine Order';
      case 'bloodbank':
        return 'Blood Request';
      case 'pathology':
        return 'Lab Test';
      default:
        return serviceType;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]}, ${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _getServiceTitle(booking.serviceType),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildStatusChip(booking.status),
              const Divider(height: 32),
              if (booking.providerDetails != null) ...[
                _buildDetailRow('Provider', booking.providerDetails!.fullName),
                _buildDetailRow('Phone', booking.providerDetails!.phone),
              ],
              _buildDetailRow('Date', _formatDate(booking.scheduledTime)),
              _buildDetailRow('Time', _formatTime(booking.scheduledTime)),
              if (booking.location.address != null)
                _buildDetailRow('Location', booking.location.address!),
              if (booking.notes != null)
                _buildDetailRow('Notes', booking.notes!),
              _buildDetailRow('Price', '₹${booking.price.toStringAsFixed(0)}'),
              if (booking.cancellationReason != null)
                _buildDetailRow(
                    'Cancellation Reason', booking.cancellationReason!),
              const SizedBox(height: 24),
              if (booking.canBeCancelled)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _cancelBooking(booking);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Cancel Booking'),
                  ),
                ),
              if (booking.canBeRated)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _rateBooking(booking);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Rate Service'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelBooking(Booking booking) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to cancel this booking?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for cancellation',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ToastUtils.showError('Please provide a reason');
                return;
              }

              Navigator.pop(context);

              try {
                await _apiClient.patient.cancelBooking(
                  booking.id,
                  reason: reasonController.text.trim(),
                );
                ToastUtils.showSuccess('Booking cancelled successfully');
                _loadBookings();
              } catch (e) {
                ToastUtils.showError('Failed to cancel booking');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  void _rateBooking(Booking booking) {
    int rating = 0;
    final reviewController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
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
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: AppColors.warning,
                      size: 32,
                    ),
                    onPressed: () {
                      setDialogState(() => rating = index + 1);
                    },
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
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (rating == 0) {
                  ToastUtils.showError('Please select a rating');
                  return;
                }

                Navigator.pop(context);

                try {
                  await _apiClient.patient.rateBooking(
                    booking.id,
                    rating: rating,
                    review: reviewController.text.trim().isEmpty
                        ? null
                        : reviewController.text.trim(),
                  );
                  ToastUtils.showSuccess('Thank you for your feedback!');
                  _loadBookings();
                } catch (e) {
                  ToastUtils.showError('Failed to submit rating');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
