import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/screens/home/home_screen.dart';
import 'package:api_client/api_client.dart' as api_client;
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class UserConsultationEndedScreen extends StatelessWidget {
  final String bookingId;
  final String doctorName;
  final int duration; // seconds

  const UserConsultationEndedScreen({
    super.key,
    required this.bookingId,
    required this.doctorName,
    required this.duration,
  });

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')} min';
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMM yyyy').format(now);
    final timeStr = DateFormat('hh:mm a').format(now);
    
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade100, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Top Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Completed on $dateStr',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Doctor Profile Row
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.blue.shade50,
                  child: const Icon(Icons.person, size: 30, color: Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName.isEmpty ? 'Dr. Shubham Singh' : (doctorName.startsWith('Dr') ? doctorName : 'Dr. $doctorName'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF152238),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'MBBS – General Physician', // You can pass actual specialization if available
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),

            // Top Info Row
            Row(
              children: [
                Expanded(child: _buildInfoCard(Icons.calendar_today_outlined, 'Consultation Time', timeStr)),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(Icons.timer_outlined, 'Consultation Duration', _formatDuration(duration))),
                const SizedBox(width: 12),
                Expanded(child: _buildInfoCard(Icons.security, 'Secure &\nPrivate', '')),
              ],
            ),
            const SizedBox(height: 32),

            // Consultation Completed Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9F4),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF28A745), size: 36),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Consultation completed successfully.',
                          style: TextStyle(
                            color: Color(0xFF28A745),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thank you for using Doctor Consultation.',
                          style: TextStyle(
                            color: Colors.grey.shade700,
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
            _buildMenuItem(Icons.description_outlined, 'Consultation Summary', () {}),
            _buildMenuItem(Icons.medical_services_outlined, 'Prescription Ready', () {}),
            
            const SizedBox(height: 16),
            
            // Download Prescription Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fetching prescription...')));
                  try {
                    final _apiClient = api_client.OnMintApiClient();
                    await _apiClient.initialize();
                    final res = await _apiClient.get('/realtime-bookings/$bookingId');
                    final data = res.data['data'];
                    final prescriptionUrl = data['prescriptionUrl'] ?? data['prescription']?['fileUrl'] ?? (data['prescription'] is String ? data['prescription'] : null);
                    
                    if (prescriptionUrl != null && prescriptionUrl.toString().startsWith('http')) {
                      final uri = Uri.parse(prescriptionUrl.toString());
                      if (await url_launcher.canLaunchUrl(uri)) {
                        await url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open prescription link.')));
                        }
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prescription not available yet.')));
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                },
                icon: const Icon(Icons.download, size: 20),
                label: const Text(
                  'Download Prescription',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildMenuItem(Icons.star_outline, 'Rate Your Experience', () {}),
            _buildMenuItem(Icons.help_outline, 'Need Help?', () {}),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              height: 1.2,
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF152238),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF152238), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF152238),
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
