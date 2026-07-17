import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'dart:typed_data';

import 'package:vendor_app/screens/doctor/doctor_active_consultation_screen.dart';
import 'package:vendor_app/screens/doctor/upload_prescription_screen.dart' as vendor_app_upload;
import 'package:url_launcher/url_launcher.dart';
import 'prescription_cache.dart';

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
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: Text(
          (_appointment?['status'] == 'requested' || _appointment?['status'] == 'pending') ? 'Consultation Request' : 'Appointment Details',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Poppins'),
        ),
        backgroundColor: const Color(0xFF0052CC), // Darker blue matching the mockup
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0052CC)))
          : _appointment == null
              ? const Center(child: Text('Appointment not found'))
              : Column(
                  children: [
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadAppointment,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildCompactDetails(),
                              const SizedBox(height: 12),
                              if (_appointment!['status'] == 'completed' || _appointment!['status'] == 'accepted')
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
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))
                  ],
                ),
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
    String problem = 'Not provided';
    if (_appointment!['requirements'] is Map) {
      problem = _appointment!['requirements']['description'] ?? _appointment!['notes'] ?? problem;
    } else if (_appointment!['requirements'] is String) {
      problem = _appointment!['requirements'];
    } else if (_appointment!['notes'] != null) {
      problem = _appointment!['notes'];
    }

    final consultationType = _appointment!['consultationType'] ?? 'General Physician';
    
    String addressText = 'Address not provided';
    if (_appointment!['location'] is Map && _appointment!['location']['address'] != null) {
      addressText = _appointment!['location']['address'];
    } else if (_appointment!['location'] is String && _appointment!['location'].toString().isNotEmpty) {
      addressText = _appointment!['location'];
    }

    return Column(
      children: [
        // 1. Request Summary
        _buildSectionCard(
          title: 'Request Summary',
          child: Row(
            children: [
              Container(
                width: 65,
                height: 65,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                  image: patient['profilePicture'] != null 
                    ? DecorationImage(image: NetworkImage(patient['profilePicture']), fit: BoxFit.cover) 
                    : null,
                ),
                child: patient['profilePicture'] == null 
                  ? Image.asset('assets/images/male_profile.png', fit: BoxFit.cover) 
                  : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patientName.isEmpty ? 'Patient' : patientName, 
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF152238), fontFamily: 'Poppins')),
                    const SizedBox(height: 4),
                    Text('${age.replaceAll(" Years", " Years")} / $gender', 
                      style: TextStyle(color: Colors.grey[600], fontSize: 13, fontFamily: 'Poppins')),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.blue.shade700),
                      const SizedBox(width: 6),
                      Text('Request Date & Time', style: TextStyle(color: Colors.blue.shade700, fontSize: 11, fontWeight: FontWeight.w500, fontFamily: 'Poppins')),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('$formattedDate, $formattedTime', 
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF152238), fontFamily: 'Poppins')),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // 2. Patient Details
        _buildSectionCard(
          title: 'Patient Details',
          child: Column(
            children: [
              _buildIconRow(Icons.person_outline, 'Name', patientName.isEmpty ? 'Patient' : patientName),
              _buildDivider(),
              _buildIconRow(Icons.badge_outlined, 'Age / Gender', '${age.replaceAll(" Years", " Years")} / $gender'),
              _buildDivider(),
              _buildIconRow(Icons.location_on_outlined, 'Address', addressText, isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // 3. Consultation Details
        _buildSectionCard(
          title: 'Consultation Details',
          child: Column(
            children: [
              _buildIconRow(Icons.medical_services_outlined, 'Consultation Type', consultationType),
              _buildDivider(),
              _buildIconRow(Icons.description_outlined, 'Reason / Symptoms', problem, isLast: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Request Details
        _buildSectionCard(
          title: 'Request Details',
          child: Column(
            children: [
              _buildIconRow(Icons.calendar_today_outlined, 'Request Date', formattedDate),
              _buildDivider(),
              _buildIconRow(Icons.access_time_outlined, 'Request Time', formattedTime),
              const SizedBox(height: 16),
              
              // Additional Notes Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F5FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF0052CC), size: 18),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Additional Notes', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF152238), fontFamily: 'Poppins')),
                          SizedBox(height: 4),
                          Text(
                            'Once accepted, patient details will be shared with you\nand consultation status can be updated from your panel.',
                            style: TextStyle(fontSize: 11, color: Colors.black54, fontFamily: 'Poppins'),
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

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A60), fontFamily: 'Poppins')),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildIconRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade600),
        const SizedBox(width: 12),
        SizedBox(
          width: 130,
          child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontFamily: 'Poppins')),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Color(0xFF152238), fontFamily: 'Poppins')),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Divider(color: Colors.grey.shade100, height: 1, thickness: 1),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _rejectAppointment,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
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
                      Icon(Icons.close, color: Color(0xFFE52329), size: 20),
                      SizedBox(width: 8),
                      Text('Reject Request', style: TextStyle(color: Color(0xFFE52329), fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
                    ],
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton(
            onPressed: _isProcessing ? null : _acceptAppointment,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xFF4CAF50)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isProcessing
                ? const SizedBox(
                    height: 20, width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50))),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, color: Color(0xFF4CAF50), size: 20),
                      SizedBox(width: 8),
                      Text('Accept Request', style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.w600, fontSize: 14, fontFamily: 'Poppins')),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
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

  String? _getPrescriptionUrl(Map<String, dynamic> data) {
    if (data['prescriptionFileUrl'] != null && data['prescriptionFileUrl'].toString().isNotEmpty) return data['prescriptionFileUrl'].toString();
    if (data['prescriptionUrl'] != null && data['prescriptionUrl'].toString().isNotEmpty) return data['prescriptionUrl'].toString();
    if (data['prescription'] != null) {
      if (data['prescription'] is Map) {
        final p = data['prescription'] as Map;
        if (p['prescriptionFile'] != null && p['prescriptionFile'].toString().isNotEmpty) return p['prescriptionFile'].toString();
        if (p['fileUrl'] != null && p['fileUrl'].toString().isNotEmpty) return p['fileUrl'].toString();
      } else if (data['prescription'].toString().isNotEmpty) {
        return data['prescription'].toString();
      }
    }
    if (data['prescription_url'] != null && data['prescription_url'].toString().isNotEmpty) return data['prescription_url'].toString();
    if (data['report'] != null && data['report'].toString().isNotEmpty) return data['report'].toString();
    if (data['prescriptionImages'] != null && data['prescriptionImages'] is List && (data['prescriptionImages'] as List).isNotEmpty) return data['prescriptionImages'][0].toString();
    if (data['prescriptionFile'] != null && data['prescriptionFile'].toString().isNotEmpty) return data['prescriptionFile'].toString();
    
    // Fallback: deep search for any URL that looks like a prescription
    String? foundUrl;
    void searchMap(Map m) {
      m.forEach((key, value) {
        if (foundUrl != null) return;
        if (value is String) {
          final valLower = value.toLowerCase();
          if (!valLower.contains('profile') && !valLower.contains('zoom') && !valLower.contains('avatar')) {
            if (valLower.startsWith('http') || valLower.contains('uploads/') || valLower.contains('/api/')) {
              if (valLower.contains('prescription') || valLower.contains('report') || valLower.endsWith('.pdf') || valLower.endsWith('.jpg') || valLower.endsWith('.png') || valLower.endsWith('.jpeg')) {
                foundUrl = value;
              }
            } else if (valLower.endsWith('.pdf') || valLower.endsWith('.jpg') || valLower.endsWith('.png') || valLower.endsWith('.jpeg')) {
              foundUrl = value;
            }
          }
        } else if (value is Map) {
          searchMap(value);
        } else if (value is List) {
          for (var item in value) {
            if (item is Map) searchMap(item);
            else if (item is String) {
              final itemLower = item.toLowerCase();
              if (!itemLower.contains('profile') && !itemLower.contains('zoom') && !itemLower.contains('avatar')) {
                if (itemLower.startsWith('http') || itemLower.contains('uploads/') || itemLower.contains('/api/')) {
                  if (itemLower.contains('prescription') || itemLower.contains('report') || itemLower.endsWith('.pdf') || itemLower.endsWith('.png') || itemLower.endsWith('.jpg') || itemLower.endsWith('.jpeg')) {
                    foundUrl = item;
                  }
                } else if (itemLower.endsWith('.pdf') || itemLower.endsWith('.jpg') || itemLower.endsWith('.png') || itemLower.endsWith('.jpeg')) {
                  foundUrl = item;
                }
              }
            }
          }
        }
      });
    }
    searchMap(data);
    
    if (foundUrl != null && !foundUrl!.startsWith('http')) {
      if (!foundUrl!.startsWith('/')) foundUrl = '/$foundUrl';
      foundUrl = 'http://192.168.1.6:5000$foundUrl'; // Fallback base URL based on existing codebase
    }
    
    return foundUrl;
  }

  Widget _buildCompletedActions() {
    final String? pUrl = _getPrescriptionUrl(_appointment!);
    final Uint8List? localBytes = PrescriptionCache.bytes[widget.appointmentId];
    final bool hasPrescription = (pUrl != null && pUrl.isNotEmpty) || localBytes != null;
    final bool isAccepted = _appointment!['status'] == 'accepted';

    return Column(
      children: [
        if (isAccepted && !hasPrescription) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DoctorActiveConsultationScreen(
                      appointmentId: widget.appointmentId,
                    ),
                  ),
                ).then((value) {
                  if (value == true) _loadAppointment();
                });
              },
              icon: const Icon(Icons.video_camera_front, color: Colors.white),
              label: const Text(
                'Start Consultation',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
        if (hasPrescription || !isAccepted)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                if (hasPrescription) {
                  if (pUrl != null && pUrl.toLowerCase().endsWith('.pdf')) {
                    launchUrl(Uri.parse(pUrl), mode: LaunchMode.externalApplication);
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: (pUrl != null && pUrl.isNotEmpty)
                                ? Image.network(
                                    pUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.all(32),
                                      child: const Text('Could not load image', style: TextStyle(color: Colors.black)),
                                    ),
                                  )
                                : (localBytes != null ? Image.memory(
                                    localBytes,
                                    fit: BoxFit.contain,
                                  ) : const SizedBox.shrink()),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.close, size: 20, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              } else {
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
              }
            },
            icon: Icon(hasPrescription ? Icons.description : Icons.upload_file, color: Colors.white),
            label: Text(
              hasPrescription ? 'Uploaded Prescription' : 'Upload Prescription',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: hasPrescription ? Colors.green : const Color(0xFF1565C0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ],
    );
  }
}
