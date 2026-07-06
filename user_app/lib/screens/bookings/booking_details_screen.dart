import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import 'review_booking_screen.dart';
import '../doctors/doctor_categories_screen.dart';
import '../services/nurses_screen.dart';
import '../booking/ambulance_booking_screen.dart';
import '../booking/blood_request_screen.dart';
import '../booking/lab_test_booking_screen.dart';
import '../booking/user_active_consultation_screen.dart';

/// Booking details screen for patients
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
  final _apiClient = OnMintApiClient();
  Booking? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      final booking =
          await _apiClient.patient.getBookingDetails(widget.bookingId);
      setState(() {
        _booking = booking;
        _isLoading = false;
      });
      
      // Automatic redirect to live consultation if in progress
      if (_booking?.status == 'in_progress') {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserActiveConsultationScreen(
                  bookingId: widget.bookingId,
                ),
              ),
            );
          });
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    }
  }

  Future<void> _cancelBooking() async {
    final reason = await _showCancelDialog();
    if (reason == null) return;

    setState(() => _isProcessing = true);
    try {
      await _apiClient.patient.cancelBooking(widget.bookingId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _joinVideoCall() {
    if (_booking == null) return;

    // Check if we have a direct video call link from backend
    if (_booking!.videoCallLink != null &&
        _booking!.videoCallLink!.isNotEmpty) {
      // Use external video call link
      _showVideoCallDialog(_booking!.videoCallLink!);
    } else {
      // Navigate to video consultation screen
      Navigator.pushNamed(
        context,
        '/video-consultation',
        arguments: {
          'bookingId': widget.bookingId,
          'patientName': 'Patient', // You can get this from user profile
          'doctorName': _booking!.providerDetails?.fullName ?? 'Doctor',
        },
      );
    }
  }

  void _showVideoCallDialog(String videoCallLink) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.videocam, color: Colors.blue),
            const SizedBox(width: 8),
            const Text('Join Video Call'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Your video consultation is ready to begin.'),
              const SizedBox(height: 12),
              Text(
                'Doctor: ${_booking!.providerDetails?.fullName ?? 'Doctor'}',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Booking ID: ${_booking!.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Open external video call link
              final uri = Uri.parse(videoCallLink);
              try {
                if (await canLaunchUrl(uri)) {
                  await launchUrl(
                    uri,
                    mode: LaunchMode.externalApplication,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening video call in browser...'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                } else {
                  throw 'Could not launch URL';
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Could not open video call: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.videocam),
            label: const Text('Join Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String? _resolvePrescriptionUrl(dynamic prescriptionData) {
    if (prescriptionData == null) return null;

    if (prescriptionData is Map) {
      final fileUrl = prescriptionData['prescriptionFile']?.toString();
      if (fileUrl != null && fileUrl.isNotEmpty) {
        return _resolveAssetUrl(fileUrl);
      }
      return null;
    }

    final value = prescriptionData.toString().trim();
    if (value.isEmpty) return null;

    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.contains('amazonaws.com')) {
      return value;
    }

    if (value.endsWith('.pdf') ||
        value.endsWith('.png') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.startsWith('/')) {
      return _resolveAssetUrl(value);
    }

    return null;
  }

  bool _hasPrescriptionFile(dynamic prescriptionData) {
    return _resolvePrescriptionUrl(prescriptionData) != null;
  }

  String _resolveAssetUrl(String urlStr) {
    final trimmed = urlStr.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    String base = AppConfig.apiBaseUrl;
    if (base.endsWith('/api/v1')) {
      base = base.substring(0, base.length - 7);
    }
    if (trimmed.startsWith('/')) {
      return '$base$trimmed';
    }
    return '$base/$trimmed';
  }

  void _viewPrescription() {
    if (_booking?.prescription == null) return;

    final prescriptionData = _booking!.prescription;
    final fileUrl = _resolvePrescriptionUrl(prescriptionData);

    if (fileUrl != null) {
      _launchDownloadUrl(fileUrl);
      return;
    }

    if (prescriptionData is Map) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Prescription'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Doctor: ${_booking!.providerDetails?.fullName ?? 'N/A'}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (prescriptionData['diagnosis'] != null) ...[
                  const Text('Diagnosis',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(prescriptionData['diagnosis'].toString()),
                  const SizedBox(height: 12),
                ],
                if (prescriptionData['advice'] != null)
                  Text(prescriptionData['advice'].toString()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Prescription'),
        content: SingleChildScrollView(
          child: Text(prescriptionData.toString()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _launchDownloadUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening prescription for download...'), backgroundColor: Colors.cyan),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open prescription')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<String?> _showCancelDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason for cancellation',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_booking == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking Details')),
        body: const Center(child: Text('Booking not found')),
      );
    }

    if (_booking!.serviceType.toLowerCase() == 'doctor') {
      return _buildDoctorConsultationUI();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Details'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
                        const SizedBox(height: 20),
                        // Add horizontal status tracking for doctor consultations
                        if (_booking!.serviceType.toLowerCase() == 'doctor')
                          _buildStatusTracker(),
                        if (_booking!.serviceType.toLowerCase() == 'doctor')
                          const SizedBox(height: 20),
                        _buildSection('Provider Information', [
                          _buildInfoRow('Name',
                              _booking!.providerDetails?.fullName ?? 'N/A'),
                          _buildInfoRow('Phone',
                              _booking!.providerDetails?.phone ?? 'N/A'),
                          _buildInfoRow('Service',
                              _formatServiceType(_booking!.serviceType)),
                          if (_booking!.providerDetails?.specialization != null)
                            _buildInfoRow('Specialization',
                                _booking!.providerDetails!.specialization!),
                          if (_booking!.providerDetails?.experience != null)
                            _buildInfoRow('Experience',
                                '${_booking!.providerDetails!.experience} years'),
                          if (_booking!.providerDetails?.rating != null)
                            _buildInfoRow('Rating',
                                '${_booking!.providerDetails!.rating}/5 ⭐'),
                        ]),
                        const SizedBox(height: 20),
                        _buildSection('Booking Details', [
                          _buildInfoRow(
                              'Date', _formatDate(_booking!.scheduledTime)),
                          _buildInfoRow(
                              'Time', _formatTime(_booking!.scheduledTime)),
                          _buildInfoRow(
                              'Status', _formatStatus(_booking!.status)),
                          _buildInfoRow('Booking ID', _booking!.id),
                          if (_booking!.consultationType != null)
                            _buildInfoRow(
                                'Consultation Type',
                                _booking!.consultationType!
                                    .replaceAll('_', ' ')
                                    .toUpperCase()),
                          if (_booking!.price > 0)
                            _buildInfoRow('Amount',
                                '₹${_booking!.price.toStringAsFixed(2)}'),
                          if (_booking!.urgency != null)
                            _buildInfoRow(
                                'Urgency', _booking!.urgency!.toUpperCase()),
                        ]),
                        if (_booking!.location.address != null) ...[
                          const SizedBox(height: 20),
                          _buildSection('Location', [
                            Text(_booking!.location.address!),
                          ]),
                        ],
                        if (_booking!.notes != null &&
                            _booking!.notes!.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildSection('Notes', [
                            Text(_booking!.notes!),
                          ]),
                        ],

                        // Show lab report if available (for pathology bookings)
                        if (_booking!.serviceType.toLowerCase() ==
                                'pathology' &&
                            _booking!.report != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.cyan.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.cyan.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.description,
                                        color: Colors.cyan, size: 24),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Lab Report Ready',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.cyan,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.picture_as_pdf,
                                              color: Colors.red, size: 32),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Test Report.pdf',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Report uploaded on ${_formatDate(DateTime.now())}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: () => _viewReport(),
                                              icon: const Icon(Icons.visibility,
                                                  size: 16),
                                              label: const Text('View Report'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.cyan,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () =>
                                                  _downloadReport(),
                                              icon: const Icon(Icons.download,
                                                  size: 16),
                                              label: const Text('Download'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.cyan,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 12),
                                              ),
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
                        ],

                        // Prescription Section
                        if (_booking!.status.toLowerCase() == 'completed') ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _hasPrescriptionFile(_booking!.prescription)
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: _hasPrescriptionFile(_booking!.prescription)
                                      ? Colors.green.withOpacity(0.3)
                                      : Colors.orange.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                        _hasPrescriptionFile(_booking!.prescription)
                                            ? Icons.receipt_long
                                            : Icons.hourglass_empty,
                                        color: _hasPrescriptionFile(_booking!.prescription)
                                            ? Colors.green
                                            : Colors.orange,
                                        size: 24),
                                    const SizedBox(width: 12),
                                    Text(
                                      _hasPrescriptionFile(_booking!.prescription)
                                          ? 'Prescription Available'
                                          : 'Prescription on the way',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: _booking!.prescription != null ? Colors.green : Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (!_hasPrescriptionFile(_booking!.prescription))
                                  const Text(
                                    'The doctor is preparing your prescription. It will be available here soon.',
                                    style: TextStyle(fontSize: 14, color: Colors.black87),
                                  )
                                else
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                                    child: Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Your digital prescription is ready to be downloaded or viewed.',
                                            style: TextStyle(fontSize: 14, color: Colors.black87),
                                          ),
                                        ),
                                        ElevatedButton.icon(
                                          onPressed: () => _viewPrescription(),
                                          icon: const Icon(Icons.file_download, size: 16),
                                          label: const Text('View and Download'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons for Doctor Consultations
                        if (_booking!.serviceType.toLowerCase() ==
                            'doctor') ...[
                          if (_booking!.status.toLowerCase() == 'accepted') ...[
                            // Show video call button for video consultations (only if not completed)
                            if ((_booking!.consultationType?.toLowerCase() ==
                                        'video_call' ||
                                    _booking!.consultationType?.toLowerCase() ==
                                        'video-call' ||
                                    _booking!.consultationType?.toLowerCase() ==
                                        'video call') &&
                                _booking!.videoCallCompleted != true) ...[
                              ElevatedButton.icon(
                                onPressed: () => _joinVideoCall(),
                                icon: const Icon(Icons.videocam),
                                label: const Text('Join Video Call'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Show message if video call is completed
                            if ((_booking!.consultationType?.toLowerCase() ==
                                        'video_call' ||
                                    _booking!.consultationType?.toLowerCase() ==
                                        'video-call' ||
                                    _booking!.consultationType?.toLowerCase() ==
                                        'video call') &&
                                _booking!.videoCallCompleted == true) ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Video consultation completed. Waiting for prescription...',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Information for in-person consultations
                            if (_booking!.consultationType?.toLowerCase() ==
                                    'in_person' ||
                                _booking!.consultationType?.toLowerCase() ==
                                    'in-person') ...[
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.green.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.location_on,
                                        color: Colors.green),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your appointment is confirmed. Please visit the doctor at the scheduled time.',
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                          ],

                          if (_booking!.status.toLowerCase() ==
                              'in_progress') ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, color: Colors.blue),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _booking!.serviceType.toLowerCase() ==
                                              'doctor'
                                          ? '🏥 Doctor Prescription Arriving Soon...'
                                          : 'Service is in progress. Please wait for completion.',
                                      style: TextStyle(
                                        color: Colors.blue[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (_booking!.status.toLowerCase() == 'completed' &&
                              _booking!.prescription != null) ...[
                            ElevatedButton.icon(
                              onPressed: () => _viewPrescription(),
                              icon: const Icon(Icons.receipt_long),
                              label: const Text('View Prescription'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Review button for completed appointments
                          if (_booking!.status.toLowerCase() ==
                              'completed') ...[
                            ElevatedButton.icon(
                              onPressed: () => _showReviewScreen(),
                              icon: const Icon(Icons.star_outline),
                              label: const Text('Review Appointment'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 50),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ],

                        if (_booking!.canBeCancelled) ...[
                          ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _cancelBooking,
                            icon: const Icon(Icons.cancel),
                            label: const Text('Cancel Booking'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatusTracker() {
    final serviceType = _booking!.serviceType.toLowerCase();
    final currentStatus = _booking!.status.toLowerCase();

    // Define status stages per service type
    List<Map<String, dynamic>> steps = [];

    switch (serviceType) {
      case 'pathology':
      case 'lab':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'sample_collected',
            'label': 'Sample Collected',
            'icon': Icons.local_hospital
          },
          {
            'status': 'report_ready',
            'label': 'Report Ready',
            'icon': Icons.description
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
        break;
      case 'pharmacist':
      case 'pharmacy':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'in_progress',
            'label': 'Preparing',
            'icon': Icons.local_pharmacy
          },
          {
            'status': 'on_the_way',
            'label': 'Out for Delivery',
            'icon': Icons.two_wheeler
          },
          {'status': 'completed', 'label': 'Delivered', 'icon': Icons.done_all},
        ];
        break;
      case 'ambulance':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'on_the_way',
            'label': 'On the Way',
            'icon': Icons.directions_car
          },
          {
            'status': 'in_progress',
            'label': 'Arrived',
            'icon': Icons.location_on
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
        break;
      case 'bloodbank':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'in_progress',
            'label': 'Preparing',
            'icon': Icons.bloodtype
          },
          {
            'status': 'on_the_way',
            'label': 'Ready for Pickup',
            'icon': Icons.local_hospital
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
        break;
      case 'nurse':
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'on_the_way',
            'label': 'On the Way',
            'icon': Icons.directions_car
          },
          {
            'status': 'in_progress',
            'label': 'In Progress',
            'icon': Icons.medical_services
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
        break;
      default: // doctor
        steps = [
          {'status': 'requested', 'label': 'Requested', 'icon': Icons.send},
          {
            'status': 'accepted',
            'label': 'Accepted',
            'icon': Icons.check_circle
          },
          {
            'status': 'in_progress',
            'label': 'In Progress',
            'icon': Icons.medical_services
          },
          {'status': 'completed', 'label': 'Completed', 'icon': Icons.done_all},
        ];
    }

    int currentIndex =
        steps.indexWhere((step) => step['status'] == currentStatus);
    if (currentIndex == -1) currentIndex = 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Track',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final stepWidth = constraints.maxWidth / steps.length;
              return Stack(
                children: [
                  // Connecting line
                  Positioned(
                    top: 20, // Center of the 40px circle
                    left: stepWidth / 2,
                    right: stepWidth / 2,
                    child: Container(
                      height: 2,
                      color: Colors.grey[300],
                    ),
                  ),
                  // Progress line (blue)
                  if (currentIndex > 0)
                    Positioned(
                      top: 20,
                      left: stepWidth / 2,
                      width: stepWidth * currentIndex,
                      child: Container(
                        height: 2,
                        color: Colors.blue,
                      ),
                    ),
                  // Steps
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: steps.asMap().entries.map((entry) {
                      final index = entry.key;
                      final step = entry.value;
                      final isActive = index <= currentIndex;
                      final isCurrent = index == currentIndex;

                      return Expanded(
                        child: Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.blue : Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isActive ? Colors.blue : Colors.grey[300]!,
                                  width: isCurrent ? 3 : 2,
                                ),
                              ),
                              child: Icon(
                                step['icon'] as IconData,
                                color: isActive ? Colors.white : Colors.grey[400],
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              step['label'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    isCurrent ? FontWeight.bold : FontWeight.normal,
                                color: isActive ? Colors.blue : Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (_booking!.status.toLowerCase()) {
      case 'requested':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        statusText = 'Waiting for confirmation';
        break;
      case 'accepted':
        statusColor = Colors.blue;
        statusIcon = Icons.check_circle;
        statusText = 'Booking confirmed';
        break;
      case 'on_the_way':
        statusColor = Colors.purple;
        statusIcon = Icons.directions_car;
        statusText = 'Provider is on the way';
        break;
      case 'in_progress':
        statusColor = Colors.indigo;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Service in progress';
        break;
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Service completed';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Booking cancelled';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info;
        statusText = _booking!.status;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatStatus(_booking!.status),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
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

  Widget _buildPrescriptionDetails(Map<String, dynamic> prescription) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Diagnosis
        if (prescription['diagnosis'] != null) ...[
          const Text(
            'Diagnosis:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prescription['diagnosis'].toString(),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
        ],

        // Medicines
        if (prescription['medicines'] != null &&
            prescription['medicines'] is List) ...[
          const Text(
            'Medicines:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          ...((prescription['medicines'] as List).map((medicine) {
            if (medicine is Map<String, dynamic>) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['name']?.toString() ?? 'Medicine',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (medicine['dosage'] != null ||
                        medicine['frequency'] != null ||
                        medicine['duration'] != null)
                      Text(
                        '${medicine['dosage'] ?? ''} - ${medicine['frequency'] ?? ''} - ${medicine['duration'] ?? ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
              );
            }
            return Text('• ${medicine.toString()}');
          }).toList()),
          const SizedBox(height: 12),
        ],

        // Advice
        if (prescription['advice'] != null &&
            prescription['advice'].toString().isNotEmpty) ...[
          const Text(
            'Doctor\'s Advice:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            prescription['advice'].toString(),
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
        ],

        // Tests
        if (prescription['tests'] != null &&
            prescription['tests'] is List &&
            (prescription['tests'] as List).isNotEmpty) ...[
          const Text(
            'Recommended Tests:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 4),
          ...((prescription['tests'] as List)
              .map((test) => Text('• ${test.toString()}'))),
          const SizedBox(height: 12),
        ],

        // Created date
        if (prescription['createdAt'] != null) ...[
          Text(
            'Prescribed on: ${_formatDate(DateTime.parse(prescription['createdAt'].toString()))}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  void _showReviewScreen() {
    if (_booking == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewBookingScreen(
          bookingId: widget.bookingId,
          providerName: _booking!.providerDetails?.fullName ?? 'Provider',
          serviceType: _booking!.serviceType,
        ),
      ),
    ).then((result) {
      if (result == true) {
        // Reload booking details after review submission
        _loadBooking();
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }

  void _viewReport() async {
    if (_booking?.report == null) return;

    final reportUrl = _booking!.report!;
    final fullUrl = reportUrl.startsWith('http')
        ? reportUrl
        : 'http://localhost:5000$reportUrl';

    try {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open report')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening report: $e')),
        );
      }
    }
  }

  void _downloadReport() async {
    if (_booking?.report == null) return;

    final reportUrl = _booking!.report!;
    final fullUrl = reportUrl.startsWith('http')
        ? reportUrl
        : 'http://localhost:5000$reportUrl';

    try {
      final uri = Uri.parse(fullUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening report in browser for download...'),
              backgroundColor: Colors.cyan,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not download report')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading report: $e')),
        );
      }
    }
  }

  void _rescheduleAppointment() {
    if (_booking == null) return;
    final type = _booking!.serviceType.toLowerCase();
    switch (type) {
      case 'doctor':
      case 'consultation':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DoctorCategoriesScreen()),
        );
        break;
      case 'nurse':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NursesScreen()),
        );
        break;
      case 'ambulance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AmbulanceBookingScreen()),
        );
        break;
      case 'bloodbank':
      case 'blood bank':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BloodRequestScreen()),
        );
        break;
      case 'pathology':
      case 'lab_test':
      case 'lab test':
      case 'labtest':
      default:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LabTestBookingScreen()),
        );
        break;
    }
  }

  Widget _buildDoctorConsultationUI() {
    final status = _booking!.status.toLowerCase();
    final isCompleted = status == 'completed';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.verified_user_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (status == 'accepted') _buildDoctorAcceptedBanner(),
              if (status == 'in_progress') _buildDoctorInProgressBanner(),
              if (status == 'completed') _buildDoctorCompletedBanner(),
              const SizedBox(height: 20),
              
              const Text('Online Consultation – Doctor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                '${status == 'completed' ? 'Completed on' : 'Accepted on'} ${_formatDate(_booking!.updatedAt ?? DateTime.now())}, ${_formatTime(_booking!.updatedAt ?? DateTime.now())}', 
                style: TextStyle(color: Colors.grey[600], fontSize: 12)
              ),
              const SizedBox(height: 12),
              
              _buildDoctorProfileCard(status),
              const SizedBox(height: 12),
              
              if (status == 'accepted') ...[
                _buildConsultationConfirmedCard(),
                const SizedBox(height: 12),
                _buildWhatsNextSection(isAccepted: true),
              ],

              if (status == 'in_progress') ...[
                _buildPrescriptionStatusSection(
                  hasPrescription: _hasPrescriptionFile(_booking!.prescription),
                ),
              ],

              if (status == 'completed') ...[
                _buildConsultationSummaryTile(),
                const SizedBox(height: 12),
                _buildPrescriptionStatusSection(
                  hasPrescription: _hasPrescriptionFile(_booking!.prescription),
                ),
                if (_hasPrescriptionFile(_booking!.prescription)) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _viewPrescription(),
                    icon: const Icon(Icons.download, color: Colors.white),
                    label: const Text(
                      'View and Download',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D47A1),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.star_outline, color: Color(0xFF0D47A1)),
                  label: const Text('Rate Your Experience', style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                    side: const BorderSide(color: Color(0xFF0D47A1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 24),
                _buildNeedHelpSection(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: status == 'accepted' ? _buildDoctorBottomActions() : null,
    );
  }

  Widget _buildDoctorAcceptedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Accept Your Consultation', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Your consultation request has been accepted. You're all set for your appointment.", style: TextStyle(color: Colors.green[800], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorInProgressBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.videocam, color: Color(0xFF1565C0), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Consultation In Progress', style: TextStyle(color: Color(0xFF1565C0), fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text("Your consultation is currently active. Join the call if you haven't already.", style: TextStyle(color: Colors.blue[800], fontSize: 13)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _joinVideoCall(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1565C0)),
            child: const Text('Join', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Consultation completed successfully.', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text("Thank you for consulting with us.", style: TextStyle(color: Colors.green[800], fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorProfileCard(String status) {
    final doctor = _booking!.providerDetails;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage: doctor?.profilePicture != null ? NetworkImage(doctor!.profilePicture!) : null,
                  onBackgroundImageError: (e, s) {},
                  child: doctor?.profilePicture == null ? const Icon(Icons.person, size: 28) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doctor?.fullName ?? 'Doctor', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 4),
                      Text('MBBS - ${doctor?.specialization ?? 'General Physician'}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text('${doctor?.rating ?? '4.9'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(width: 4),
                          Text('(230+ Reviews)', style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(color: const Color(0xFFE8EAF6), borderRadius: BorderRadius.circular(4)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.verified, color: Color(0xFF3F51B5), size: 12),
                            SizedBox(width: 4),
                            Text('Verified Doctor', style: TextStyle(color: Color(0xFF3F51B5), fontSize: 10, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (status == 'completed') ...[
            _buildInfoRowDoc(Icons.calendar_today_outlined, 'Consultation Date', _formatDate(_booking!.scheduledTime)),
            const Divider(height: 1),
            _buildInfoRowDoc(Icons.access_time_outlined, 'Consultation Time', _formatTime(_booking!.scheduledTime)),
            const Divider(height: 1),
            _buildInfoRowDoc(Icons.timer_outlined, 'Call Duration', '05:24'), // Mock duration as we don't have it in model
          ] else ...[
            _buildInfoRowDoc(Icons.work_outline, 'Experience', '${doctor?.experience ?? '8+'} Years'),
            const Divider(height: 1),
            _buildInfoRowDoc(Icons.medical_services_outlined, 'Specialization', doctor?.specialization ?? 'General Physician'),
            const Divider(height: 1),
            _buildInfoRowDoc(Icons.calendar_today_outlined, 'Consultation Date', _formatDate(_booking!.scheduledTime)),
            const Divider(height: 1),
            _buildInfoRowDoc(Icons.access_time_outlined, 'Consultation Time', _formatTime(_booking!.scheduledTime)),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRowDoc(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF1565C0), size: 18),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildConsultationConfirmedCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 12),
              ),
              const SizedBox(width: 8),
              const Text('Consultation Confirmed', style: TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.access_time, color: Colors.black54, size: 14),
              const SizedBox(width: 6),
              const Text('Consultation Time:', style: TextStyle(color: Colors.black54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(_formatTime(_booking!.scheduledTime), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(
            '${_booking!.providerDetails?.fullName ?? 'The doctor'} will connect with you at the scheduled time.',
            style: const TextStyle(color: Colors.black87, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildWhatsNextSection({bool isAccepted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("What's Next?",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                isAccepted
                    ? 'Join the video call at your scheduled time. Your prescription will appear here after the consultation.'
                    : 'We will notify you once the doctor is assigned.',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              _buildWhatsNextChecklist(isAccepted: isAccepted),
            ],
          ),
        ),
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: const Color(0xFFE8EAF6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.assignment, color: Color(0xFF9FA8DA), size: 24),
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.all(1),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWhatsNextChecklist({required bool isAccepted}) {
    final steps = isAccepted
        ? const [
            'Doctor accepted your request',
            'Join consultation at scheduled time',
            'Prescription will be shared after consult',
          ]
        : const [
            'Request submitted',
            'Doctor assignment pending',
            'Consultation confirmation',
          ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final isDone = isAccepted ? entry.key <= 0 : entry.key == 0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: [
              Icon(
                isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: isDone ? const Color(0xFF2E7D32) : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDone ? Colors.black87 : Colors.grey[600],
                    fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPrescriptionStatusSection({required bool hasPrescription}) {
    final title = hasPrescription
        ? 'Prescription Available'
        : 'Prescription on the way';
    final subtitle = hasPrescription
        ? 'Your digital prescription is ready to view and download.'
        : 'The doctor is preparing your prescription. It will be available here soon.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasPrescription
            ? Colors.green.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasPrescription
              ? Colors.green.withOpacity(0.25)
              : Colors.orange.withOpacity(0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasPrescription ? Icons.receipt_long : Icons.hourglass_empty,
                color: hasPrescription ? Colors.green : Colors.orange,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasPrescription ? Colors.green : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.3),
          ),
          if (hasPrescription) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _viewPrescription(),
                icon: const Icon(Icons.file_download, size: 18),
                label: const Text('View and Download'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0D47A1),
                  side: const BorderSide(color: Color(0xFF0D47A1)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConsultationSummaryTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.assignment_outlined, color: Color(0xFF1565C0)),
        ),
        title: const Text('Consultation Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('View notes and details of your consultation', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {}, // TODO: Show summary
      ),
    );
  }

  Widget _buildPrescriptionReadyTile() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFE8F5E9), borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.receipt_long_outlined, color: Color(0xFF2E7D32)),
        ),
        title: const Text('Prescription Ready', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('Your prescription is ready to download.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () => _viewPrescription(),
      ),
    );
  }

  Widget _buildNeedHelpSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: const Icon(Icons.headset_mic_outlined, color: Color(0xFF1565C0)),
        title: const Text('Need Help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Our support team is here to help you.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            const SizedBox(height: 4),
            const Text('Contact Support', style: TextStyle(color: Color(0xFF1565C0), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {},
      ),
    );
  }

  Widget _buildDoctorBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: _buildActionColumn(Icons.calendar_today, 'Reschedule', _rescheduleAppointment),
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            Expanded(
              child: _buildActionColumn(Icons.close, 'Cancel\nAppointment', () => _cancelBooking(), color: Colors.red),
            ),
            Container(width: 1, height: 40, color: Colors.grey[300]),
            Expanded(
              child: _buildActionColumn(Icons.headset_mic_outlined, 'Contact\nSupport', () {}, color: const Color(0xFF1565C0)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionColumn(IconData icon, String label, VoidCallback onTap, {Color color = Colors.black87}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
