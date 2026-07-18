import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'appointment_details_screen.dart';
import 'doctor_active_consultation_screen.dart';

/// Doctor appointments list screen
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  final _apiClient = OnMintApiClient();
  List<dynamic> _appointments = [];
  bool _isLoading = true;
  String _selectedStatus = 'requested';

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      final response = await _apiClient.doctor.getAppointments(
        page: 1,
        limit: 100,
        status: _selectedStatus,
      );
      setState(() {
        List<dynamic> rawAppointments = response['data'] ?? response['items'] ?? [];
        final Set<String> seenIds = {};
        _appointments = rawAppointments.where((app) {
          final id = app['_id']?.toString() ?? app['id']?.toString() ?? '';
          if (id.isEmpty) return true;
          if (seenIds.contains(id)) return false;
          seenIds.add(id);
          return true;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading appointments: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Appointments'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedStatus,
            onSelected: (value) {
              setState(() => _selectedStatus = value);
              _loadAppointments();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'requested',
                child: Text('Requested'),
              ),
              const PopupMenuItem(
                value: 'accepted',
                child: Text('Accepted'),
              ),
              const PopupMenuItem(
                value: 'in_progress',
                child: Text('In Progress'),
              ),
              const PopupMenuItem(
                value: 'completed',
                child: Text('Completed'),
              ),
              const PopupMenuItem(
                value: 'cancelled',
                child: Text('Cancelled'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAppointments,
              child: _appointments.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_busy,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No $_selectedStatus appointments',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _appointments.length,
                      itemBuilder: (context, index) {
                        final appointment = _appointments[index];
                        return _buildAppointmentCard(appointment);
                      },
                    ),
            ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final patient = appointment['patient'] ?? {};
    final scheduledTimeStr = appointment['scheduledTime'] ?? appointment['createdAt'] ?? DateTime.now().toIso8601String();
    final scheduledTime = DateTime.parse(scheduledTimeStr).toLocal();
    final statusRaw = appointment['status']?.toString().toLowerCase() ?? 'requested';
    
    // Get patient details
    String patientName = 'Unknown Patient';
    if (patient is Map) {
      final firstName = patient['firstName'] ?? '';
      final lastName = patient['lastName'] ?? '';
      patientName = '$firstName $lastName'.trim();
      if (patientName.isEmpty) patientName = 'Unknown Patient';
    }
    
    final patientPhoto = patient is Map ? patient['profilePicture']?.toString() ?? '' : '';
    final age = patient is Map ? patient['age'] ?? 35 : 35;
    final gender = patient is Map ? patient['gender'] ?? 'Male' : 'Male';
    final address = appointment['location']?['address'] ?? '';
    final consultationType = appointment['consultationType'] ?? 'Online';

    // Status logic
    Color statusColor;
    String statusLabel;
    bool isPending = false;
    bool isCompleted = false;

    if (statusRaw == 'requested' || statusRaw == 'pending') {
      statusColor = Colors.orange;
      statusLabel = 'Requested';
      isPending = true;
    } else if (statusRaw == 'completed') {
      statusColor = Colors.green;
      statusLabel = 'Completed';
      isCompleted = true;
    } else if (statusRaw == 'cancelled' || statusRaw == 'rejected') {
      statusColor = Colors.red;
      statusLabel = 'Cancelled';
      isCompleted = true;
    } else if (statusRaw == 'accepted') {
      statusColor = Colors.green;
      statusLabel = 'Connected';
    } else {
      statusColor = const Color(0xFF1565C0);
      statusLabel = 'In Progress';
    }

    String completedDateStr = '';
    if (isCompleted && appointment['updatedAt'] != null) {
      final dt = DateTime.tryParse(appointment['updatedAt'].toString());
      if (dt != null) {
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        completedDateStr = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
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
        onTap: () async {
          if (isPending) {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailsScreen(
                  appointmentId: appointment['_id'],
                ),
              ),
            );
            if (result == true) {
              _loadAppointments();
            }
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorActiveConsultationScreen(
                  appointmentId: appointment['_id'],
                ),
              ),
            );
            _loadAppointments();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.shade50,
                backgroundImage: patientPhoto.isNotEmpty 
                    ? NetworkImage(patientPhoto) 
                    : null,
                child: patientPhoto.isEmpty ? Text(
                  patientName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
                ) : null,
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
                          '$age Years',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                        Icon(gender.toLowerCase() == 'female' ? Icons.female : Icons.male, size: 12, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          gender,
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.videocam, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Video Consultation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Right Side (Status + Chevron)
              Flexible(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
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
                            ] else ...[
                              const SizedBox(height: 2),
                              Text(
                                '${scheduledTime.day}/${scheduledTime.month}/${scheduledTime.year}\n${scheduledTime.hour}:${scheduledTime.minute.toString().padLeft(2, '0')}',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Poppins', fontSize: 9, color: Colors.grey.shade600, height: 1.1),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right, color: Colors.black54, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
