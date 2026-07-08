import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';

import 'package:vendor_app/screens/doctor/doctor_active_consultation_screen.dart';
import 'package:vendor_app/screens/doctor/upload_prescription_screen.dart' as vendor_app_upload;

class AppointmentDetailsScreen extends StatefulWidget {
  final String appointmentId;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<AppointmentDetailsScreen> createState() => _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _appointment;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadAppointment();
  }

  Future<void> _loadAppointment() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiClient.doctor.getAppointmentDetails(widget.appointmentId);
      setState(() {
        _appointment = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('404') || errorMsg.contains('not found')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This appointment is no longer available.')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading appointment: $e')),
          );
        }
      }
    }
  }

  Future<void> _acceptAppointment() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.doctor.acceptAppointment(widget.appointmentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment accepted')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorActiveConsultationScreen(
              appointmentId: widget.appointmentId,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('404') ||
            errorMsg.contains('409') ||
            errorMsg.contains('410') ||
            errorMsg.contains('not found') ||
            errorMsg.contains('already been accepted') ||
            errorMsg.contains('expired')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This appointment has already been accepted or is no longer available.')),
          );
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _rejectAppointment() async {
    setState(() => _isProcessing = true);
    try {
      await _apiClient.doctor.rejectAppointment(
        widget.appointmentId,
        reason: 'Provider busy',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment rejected')),
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

  @override
  Widget build(BuildContext context) {
    final showActionButtons = _appointment != null &&
        (_appointment!['status'] == 'requested' || _appointment!['status'] == 'pending');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Booking Request Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)))
          : _appointment == null
              ? const Center(child: Text('Appointment not found'))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadAppointment,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCompactDetails(),
                            const SizedBox(height: 12),
                            if (_appointment!['status'] == 'completed')
                              _buildCompletedActions(),
                          ],
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
      bottomNavigationBar: showActionButtons
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: _buildActionButtons(),
              ),
            )
          : null,
    );
  }

  Widget _buildCompactDetails() {
    final patient = _appointment!['patient'] ?? {};
    final patientName = patient['fullName'] ?? '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final gender = patient['gender'] ?? 'Male';
    final age = _calculateAge(patient['dateOfBirth']);
    final dateStr = _appointment!['createdAt'] ?? _appointment!['scheduledTime'];
    final formattedDate = _formatDate(dateStr);
    final formattedTime = _formatTime(dateStr);
    final problem = _appointment!['requirements']?['description'] ?? _appointment!['notes'] ?? 'Fever, Cold';
    final consultationType = _appointment!['consultationType'] ?? 'General Physician';
    
    String addressText = 'H-101, Shanti Nagar,\nGovindpuram, Ghaziabad,\nUttar Pradesh - 201013';
    if (_appointment!['location']?['address'] != null) {
      addressText = _appointment!['location']['address'];
    }

    return Column(
      children: [
        // 1. Request Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF152238))),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                      image: patient['profilePicture'] != null ? DecorationImage(image: NetworkImage(patient['profilePicture']), fit: BoxFit.cover) : null,
                    ),
                    child: patient['profilePicture'] == null ? const Icon(Icons.person, color: Colors.blue, size: 36) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patientName.isEmpty ? 'Patient' : patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                        const SizedBox(height: 4),
                        Text('${age.replaceAll(" Years", " Years")} / $gender', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0xFFF0F0F0)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text('Request Date & Time', style: TextStyle(color: Colors.blue.shade700, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  Text('$formattedDate, $formattedTime', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        
        // 2. Patient Details
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Patient Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF152238))),
              const SizedBox(height: 10),
              _buildIconRow(Icons.person_outline, 'Name', patientName.isEmpty ? 'Patient' : patientName),
              _buildDivider(),
              _buildIconRow(Icons.contact_page_outlined, 'Age / Gender', '${age.replaceAll(" Years", " Years")} / $gender'),
              _buildDivider(),
              _buildIconRow(Icons.location_on_outlined, 'Address', addressText),
            ],
          ),
        ),
        const SizedBox(height: 10),
        
        // 3. Consultation Details
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Consultation Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF152238))),
              const SizedBox(height: 10),
              _buildIconRow(Icons.medical_services_outlined, 'Consultation Type', consultationType),
              _buildDivider(),
              _buildIconRow(Icons.description_outlined, 'Reason / Symptoms', problem),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 4. Request Details
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF152238))),
              const SizedBox(height: 10),
              _buildIconRow(Icons.calendar_today_outlined, 'Request Date', formattedDate),
              _buildDivider(),
              _buildIconRow(Icons.access_time_outlined, 'Request Time', formattedTime),
              const SizedBox(height: 10),
              
              // Additional Notes Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Additional Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF152238))),
                          SizedBox(height: 4),
                          Text(
                            'Once accepted, patient details will be shared with you and consultation status can be updated from your panel.',
                            style: TextStyle(fontSize: 11, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIconRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1565C0)),
          const SizedBox(width: 12),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 12,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, top: 6),
      child: Divider(color: Colors.grey[200], height: 1),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _rejectAppointment,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFE52329)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFE52329))),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.close, color: Color(0xFFE52329), size: 18),
                          SizedBox(width: 8),
                          Text('Reject Request', style: TextStyle(color: Color(0xFFE52329), fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _acceptAppointment,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF43A047)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF43A047))),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Color(0xFF43A047), size: 18),
                          SizedBox(width: 8),
                          Text('Accept Request', style: TextStyle(color: Color(0xFF43A047), fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  String _formatDateFull(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '${date.day} ${months[date.month - 1]}\n${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return 'N/A';
    }
  }

  String _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return 'N/A';
    try {
      final birthDate = DateTime.parse(dateOfBirth.toString());
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return '$age Years';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildCompletedActions() {
    return Column(
      children: [
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => vendor_app_upload.UploadPrescriptionScreen(
                    appointmentId: widget.appointmentId,
                    appointment: _appointment,
                  ),
                ),
              ).then((value) {
                if (value == true) {
                  _loadAppointment();
                }
              });
            },
            icon: const Icon(Icons.upload_file, color: Colors.white),
            label: const Text(
              'Upload Prescription',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}
