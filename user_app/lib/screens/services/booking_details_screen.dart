import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import '../../utils/app_colors.dart';
import '../consultation/video_consultation_screen.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailsScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {
  late final PatientService _patientService;

  Map<String, dynamic>? _booking;
  bool _isLoading = false;
  String? _error;
  bool _showRatingDialog = false;
  int _selectedRating = 0;
  final TextEditingController _reviewController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _patientService = PatientService();
    _loadBookingDetails();
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _loadBookingDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _patientService.getBookingById(widget.bookingId);

      if (mounted) {
        setState(() {
          _booking = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading booking details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final success = await _patientService.rateService(
        bookingId: widget.bookingId,
        rating: _selectedRating,
        review: _reviewController.text.trim().isEmpty
            ? null
            : _reviewController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rating submitted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _showRatingDialog = false;
            _selectedRating = 0;
            _reviewController.clear();
          });
          _loadBookingDetails();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to submit rating'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting rating: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadBookingDetails,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(_error!,
                          style: const TextStyle(color: AppColors.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookingDetails,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _booking == null
                  ? const Center(child: Text('No booking details found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Provider Info
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Service Provider',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: AppColors.primary,
                                        child: Text(
                                          (_booking!['provider']
                                                      ?['firstName'] ??
                                                  'S')
                                              .toString()
                                              .substring(0, 1)
                                              .toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _booking!['doctorName'] ??
                                                  '${_booking!['provider']?['firstName'] ?? ''} ${_booking!['provider']?['lastName'] ?? ''}'
                                                      .trim(),
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              _booking!['provider']?['phone'] ??
                                                  'N/A',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Booking Details
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Booking Details',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _buildDetailRow(
                                    'Service Type',
                                    _booking!['serviceType']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'N/A',
                                  ),
                                  _buildDetailRow(
                                    'Status',
                                    _booking!['status']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'N/A',
                                    valueColor: _getStatusColor(
                                        _booking!['status']?.toString() ?? ''),
                                  ),
                                  _buildDetailRow(
                                    'Scheduled Time',
                                    _booking!['scheduledTime'] != null
                                        ? DateTime.parse(
                                                _booking!['scheduledTime']
                                                    .toString())
                                            .toString()
                                            .split('.')
                                            .first
                                        : 'N/A',
                                  ),
                                  _buildDetailRow(
                                    'Price',
                                    '₹${_booking!['price'] ?? 0}',
                                  ),
                                  _buildDetailRow(
                                    'Payment Status',
                                    _booking!['paymentStatus']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'N/A',
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Location
                          if (_booking!['location'] != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Location',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _booking!['location']['address'] ??
                                                'N/A',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Notes
                          if (_booking!['notes'] != null &&
                              (_booking!['notes'] as String).isNotEmpty) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Notes',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _booking!['notes'],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Video Consultation Button
                          if (_booking!['consultationType']
                                      ?.toString()
                                      .toLowerCase() ==
                                  'video-call' &&
                              ['accepted', 'in_progress'].contains(
                                  _booking!['status']
                                      ?.toString()
                                      .toLowerCase()))
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          VideoConsultationScreen(
                                        bookingId: widget.bookingId,
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.video_call),
                                label: const Text('Join Video Consultation'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF667eea),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                ),
                              ),
                            ),

                          if (_booking!['consultationType']
                                      ?.toString()
                                      .toLowerCase() ==
                                  'video-call' &&
                              ['accepted', 'in_progress'].contains(
                                  _booking!['status']
                                      ?.toString()
                                      .toLowerCase()))
                            const SizedBox(height: 16),

                          // Rating Button
                          if (_booking!['status']?.toString().toLowerCase() ==
                              'completed')
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  setState(() => _showRatingDialog = true);
                                },
                                icon: const Icon(Icons.star),
                                label: const Text('Rate This Service'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    )),
      floatingActionButton: _showRatingDialog
          ? null
          : FloatingActionButton(
              onPressed: _loadBookingDetails,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.refresh),
            ),
      bottomSheet: _showRatingDialog
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rate This Service',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _showRatingDialog = false),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedRating = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.star,
                            size: 40,
                            color: index < _selectedRating
                                ? AppColors.warning
                                : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewController,
                    decoration: const InputDecoration(
                      hintText: 'Write your review (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              setState(() => _showRatingDialog = false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _submitRating,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Submit Rating'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'confirmed':
        return AppColors.success;
      case 'requested':
      case 'pending':
        return AppColors.warning;
      case 'completed':
        return AppColors.info;
      case 'cancelled':
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }
}
