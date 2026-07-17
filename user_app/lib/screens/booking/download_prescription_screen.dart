import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/screens/home/home_screen.dart';
import 'package:api_client/api_client.dart' as api_client;
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'dart:async';

class DownloadPrescriptionScreen extends StatefulWidget {
  final String bookingId;
  final String doctorName;
  final int duration;

  const DownloadPrescriptionScreen({
    super.key,
    required this.bookingId,
    required this.doctorName,
    required this.duration,
  });

  @override
  State<DownloadPrescriptionScreen> createState() => _DownloadPrescriptionScreenState();
}

class _DownloadPrescriptionScreenState extends State<DownloadPrescriptionScreen> {
  final _apiClient = api_client.OnMintApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _bookingData;
  String _dateStr = '';
  String _timeStr = '';
  String _completedAtStr = '';
  String? _prescriptionUrl;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted && _prescriptionUrl == null) {
        _checkPrescriptionStatus();
      } else if (_prescriptionUrl != null) {
        _pollingTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPrescriptionStatus() async {
    try {
      final res = await _apiClient.get('/video/call-status/${widget.bookingId}');
      if (mounted && res.data != null && res.data['data'] != null) {
        final data = res.data['data'];
        dynamic presData = data['prescription'];
        String? pUrl;
        
        if (data['prescriptionFileUrl'] != null) {
          pUrl = data['prescriptionFileUrl'];
        } else if (data['prescriptionUrl'] != null) {
          pUrl = data['prescriptionUrl'];
        } else if (presData != null && presData is Map && presData['fileUrl'] != null) {
          pUrl = presData['fileUrl'];
        } else if (presData != null && presData is String) {
          pUrl = presData;
        }

        if (pUrl != null && pUrl.isNotEmpty) {
          setState(() {
            _prescriptionUrl = pUrl;
          });
          _pollingTimer?.cancel();
          return; // found it in call-status
        }
      }
    } catch (_) {}
  }

  Future<void> _loadBookingDetails() async {
    try {
      await _apiClient.initialize();
      // Try realtime-bookings first, if it fails try patient/bookings
      var res;
      try {
        res = await _apiClient.get('/realtime-bookings/${widget.bookingId}');
      } catch (e) {
        res = await _apiClient.get('/patient/bookings/${widget.bookingId}');
      }
      
      if (mounted) {
        final data = res.data['data'] ?? res.data;
        final scheduleDate = data['scheduleDate']?.toString() ?? data['createdAt']?.toString();
        final scheduleTime = data['scheduleTime']?.toString();
        final createdAt = data['createdAt']?.toString();
        
        setState(() {
          _bookingData = data;
          
          if (scheduleDate != null) {
            try {
              String sd = scheduleDate;
              if (sd.endsWith('Z')) sd = sd.substring(0, sd.length - 1);
              final dt = DateTime.parse(sd);
              _dateStr = DateFormat('dd MMM yyyy').format(dt);
            } catch (e) {
              _dateStr = scheduleDate;
            }
          }
          
          if (scheduleTime != null) {
            _timeStr = scheduleTime;
          }

          if (createdAt != null) {
            try {
              String cd = createdAt;
              if (cd.endsWith('Z')) cd = cd.substring(0, cd.length - 1);
              final dt = DateTime.parse(cd);
              _completedAtStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
              if (_timeStr.isEmpty) _timeStr = DateFormat('hh:mm a').format(dt);
            } catch (e) {
              _completedAtStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
            }
          } else {
            _completedAtStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
          }

          dynamic presData = data['prescription'];
          if (data['prescriptionFileUrl'] != null) {
            _prescriptionUrl = data['prescriptionFileUrl'];
          } else if (data['prescriptionUrl'] != null) {
            _prescriptionUrl = data['prescriptionUrl'];
          } else if (presData is Map && presData['fileUrl'] != null) {
            _prescriptionUrl = presData['fileUrl'];
          } else if (presData is String) {
            _prescriptionUrl = presData;
          }
          if (_prescriptionUrl != null) {
            _isLoading = false;
          } else {
            _isLoading = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final doctorName = _bookingData?['doctorName'] ?? widget.doctorName;
    final doctorImage = _bookingData?['doctor']?['profilePic'];
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
          onPressed: () => _goHome(context),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
            color: Color(0xFF152238),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Online Consultation – Doctor',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF152238),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Completed on $_completedAtStr',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),

              // Doctor Profile
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: doctorImage != null ? NetworkImage(doctorImage) : null,
                          child: doctorImage == null ? const Icon(Icons.person, size: 40, color: Colors.blue) : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctorName.isEmpty ? 'Doctor' : (doctorName.startsWith('Dr') ? doctorName : 'Dr. $doctorName'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF152238),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'MBBS – General Physician',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          '4.9',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(230+ Reviews)',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Consultation Details
              _buildDetailRow(Icons.calendar_month_outlined, 'Consultation Date', _dateStr.isNotEmpty ? _dateStr : 'N/A'),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.access_time_outlined, 'Consultation Time', _timeStr.isNotEmpty ? _timeStr : 'N/A'),
              const SizedBox(height: 16),
              _buildDetailRow(Icons.timer_outlined, 'Call Duration', _formatDuration(widget.duration)),
              const SizedBox(height: 24),

              // Success Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF7EE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Consultation completed successfully.',
                            style: TextStyle(
                              color: Color(0xFF2E7D32),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Thank you for consulting with us.',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Menu Items
              _buildActionTile(Icons.description_outlined, 'Consultation Summary', 'View notes and details of your consultation'),
              const SizedBox(height: 12),
              _buildActionTile(Icons.medical_information_outlined, 'Prescription Ready', 'Your prescription is ready to download.'),
              const SizedBox(height: 16),

              if (_prescriptionUrl != null) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _prescriptionUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 150,
                        color: Colors.grey.shade50,
                        child: const Center(
                          child: Icon(Icons.picture_as_pdf, size: 40, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Download Prescription Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_prescriptionUrl != null && _prescriptionUrl.toString().startsWith('http')) {
                      final uri = Uri.parse(_prescriptionUrl.toString());
                      if (await url_launcher.canLaunchUrl(uri)) {
                        await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open prescription link.')));
                        }
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription not uploaded yet wait for some time...')));
                      }
                    }
                  },
                  icon: const Icon(Icons.download, size: 20),
                  label: const Text(
                    'Download Prescription',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0033CC), // Blue matching Image 2
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Bottom Actions
              _buildOutlinedButton(Icons.star_outline, 'Rate Your Experience'),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.headset_mic_outlined, color: Color(0xFF0033CC), size: 24),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Need Help?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Our support team is here to help you.', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          const SizedBox(height: 8),
                          const Text('Contact Support', style: TextStyle(color: Color(0xFF0033CC), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 18),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF0033CC), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  Widget _buildOutlinedButton(IconData icon, String label) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF0033CC),
          side: const BorderSide(color: Color(0xFF0033CC), width: 1.5),
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
