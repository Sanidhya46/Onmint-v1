import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/app_colors.dart';

class PathologyBookingDetailsScreen extends StatefulWidget {
  final String bookingId;
  final bool isRealtimeBooking;

  const PathologyBookingDetailsScreen({
    super.key,
    required this.bookingId,
    this.isRealtimeBooking = false,
  });

  @override
  State<PathologyBookingDetailsScreen> createState() => _PathologyBookingDetailsScreenState();
}

class _PathologyBookingDetailsScreenState extends State<PathologyBookingDetailsScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _booking;
  bool _isLoading = true;
  bool _isProcessing = false;
  String _currentStage = 'requested';

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      
      final data = await _apiClient.pathology.getBookingDetails(widget.bookingId);
      
      setState(() {
        _booking = data;
        _currentStage = data['status'] ?? 'requested';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ToastUtils.showError('Error loading booking: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = _booking?['patient'] ?? {};
    final patientName = patient['fullName'] ?? patient['firstName'] != null
        ? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim()
        : 'Patient';
    final isRequested = _currentStage == 'requested';

    return Scaffold(
      backgroundColor: isRequested ? Colors.white : const Color(0xFFF7F9FD),
      appBar: AppBar(
        backgroundColor: isRequested ? AppColors.pathology : Colors.white,
        foregroundColor: isRequested ? Colors.white : const Color(0xFF152238),
        elevation: isRequested ? 0 : 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isRequested ? Colors.white : const Color(0xFF152238)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: isRequested 
            ? const Text('Lab Test Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.handshake, color: Color(0xFF2E7D32), size: 18),
                  const SizedBox(width: 6),
                  Text(
                    'Connected with $patientName',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF152238),
                    ),
                  ),
                ],
              ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _booking == null
              ? const Center(child: Text('Booking not found'))
              : _currentStage == 'requested'
                  ? _buildRequestDetailsScreen()
                  : _buildProgressScreen(),
    );
  }

  Widget _buildRequestDetailsScreen() {
    final patient = _booking!['patient'] ?? {};
    final patientName = patient['fullName'] ?? 'Patient';
    final testType = _booking!['testType'] ?? 'Lab Test';
    final price = _booking!['fees'] ?? _booking!['price'] ?? 300;
    final age = patient['age'] ?? 35;
    final gender = patient['gender'] ?? 'Male';
    final address = patient['address'] ?? 'Address not provided';
    final notes = _booking!['notes'] ?? 'No notes';

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRequestSummary(patientName, gender, age),
          const SizedBox(height: 20),
          _buildPatientDetails(patientName, age, gender, address),
          const SizedBox(height: 20),
          _buildLabTestDetails(testType, notes, price),
          const SizedBox(height: 30),
          _buildAcceptRejectButtons(),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Once accepted, details will be shared with patient',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestSummary(String name, String gender, int age) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.blue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$gender • $age Years',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientDetails(String name, int age, String gender, String address) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Name', name),
          const Divider(height: 32),
          _buildDetailRow('Age / Gender', '$age Years / $gender'),
          const Divider(height: 32),
          _buildDetailRow('Address', address),
        ],
      ),
    );
  }

  Widget _buildLabTestDetails(String testType, String notes, int price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lab Test Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildDetailRow('Test Type', testType),
          const Divider(height: 32),
          _buildDetailRow('Fee', '₹$price'),
          const Divider(height: 32),
          _buildDetailRow('Notes', notes),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAcceptRejectButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _rejectBooking,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red, width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _acceptBooking,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Accept',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressScreen() {
    final patient = _booking!['patient'] ?? {};
    final patientName = patient['fullName'] ?? 'Patient';
    final testType = _booking!['testType'] ?? 'Lab Test';
    final price = _booking!['fees'] ?? _booking!['price'] ?? 300;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
      child: Column(
        children: [
          _buildProgressCard(patientName, testType, price),
          const SizedBox(height: 24),
          _buildProgressTracker(),
          const SizedBox(height: 24),
          _buildMainActionButton(),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String name, String testType, int price) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text('Test: $testType', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 12),
          Text(
            '₹$price',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00B894),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            _currentStage.toUpperCase(),
            style: const TextStyle(fontSize: 14, color: Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }

  Widget _buildMainActionButton() {
    String buttonText = 'Update Status';
    
    if (_currentStage == 'accepted') {
      buttonText = 'Mark as On The Way';
    } else if (_currentStage == 'on_the_way') {
      buttonText = 'Mark Sample Collected';
    } else if (_currentStage == 'sample_collected') {
      buttonText = 'Upload Report';
    }

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _handleMainAction,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.pathology,
        ),
        child: _isProcessing
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Future<void> _acceptBooking() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.pathology.acceptBooking(widget.bookingId);
      if (mounted) {
        ToastUtils.showSuccess('Booking accepted!');
        setState(() {
          _currentStage = 'accepted';
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Error: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectBooking() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.pathology.rejectBooking(widget.bookingId, reason: 'Rejected by technician');
      if (mounted) {
        ToastUtils.showSuccess('Booking rejected');
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Error: $e');
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleMainAction() async {
    setState(() => _isProcessing = true);
    try {
      if (_currentStage == 'accepted') {
        await _apiClient.pathology.updateBookingStatus(widget.bookingId, 'on_the_way');
        setState(() => _currentStage = 'on_the_way');
        ToastUtils.showSuccess('Marked as On The Way');
      } else if (_currentStage == 'on_the_way') {
        await _apiClient.pathology.updateBookingStatus(widget.bookingId, 'sample_collected');
        setState(() => _currentStage = 'sample_collected');
        ToastUtils.showSuccess('Sample collected');
      } else if (_currentStage == 'sample_collected') {
        final ImagePicker picker = ImagePicker();
        final XFile? file = await picker.pickImage(source: ImageSource.gallery);
        
        if (file != null) {
          if (kIsWeb) {
            final bytes = await file.readAsBytes();
            await _apiClient.pathology.uploadReportFileBytes(widget.bookingId, bytes, file.name);
          } else {
            await _apiClient.pathology.uploadReportFile(widget.bookingId, file.path!);
          }
          setState(() => _currentStage = 'completed');
          ToastUtils.showSuccess('Report uploaded');
        }
      }
      setState(() => _isProcessing = false);
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Error: $e');
        setState(() => _isProcessing = false);
      }
    }
  }
}
