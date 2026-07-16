import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'upload_prescription_screen.dart';

class ConsultationEndedScreen extends StatefulWidget {
  final String bookingId;
  final String patientName;
  final int duration;
  final Map<String, dynamic>? appointment;

  const ConsultationEndedScreen({
    super.key,
    required this.bookingId,
    required this.patientName,
    required this.duration,
    this.appointment,
  });

  @override
  State<ConsultationEndedScreen> createState() =>
      _ConsultationEndedScreenState();
}

class _ConsultationEndedScreenState extends State<ConsultationEndedScreen> {
  DateTime _parseLocalTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return DateTime.now();
    try {
      String t = timeStr;
      if (t.endsWith('Z')) {
        t = t.substring(0, t.length - 1);
      }
      return DateTime.parse(t);
    } catch (e) {
      return DateTime.now();
    }
  }

  void _goToPrescription() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UploadPrescriptionScreen(
          appointmentId: widget.bookingId,
          appointment: widget.appointment,
        ),
      ),
    );
  }

  void _callSupport() async {
    final Uri launchUri = Uri(scheme: 'tel', path: '+1234567890');
    if (await url_launcher.canLaunchUrl(launchUri)) {
      await url_launcher.launchUrl(launchUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.appointment?['patient'] ?? {};
    final patientName = patient['fullName'] ?? widget.patientName;
    final gender = patient['gender'] ?? 'Male';
    final age = _calculateAge(patient['dateOfBirth']);
    final distance = '3.1 km away'; 
    final profilePic = patient['profilePicture'];
    final price = widget.appointment?['price'] ?? widget.appointment?['totalAmount'] ?? 300;

    final String scheduledTimeStr = widget.appointment?['scheduledTime'] ?? widget.appointment?['createdAt'] ?? '';
    final dt = _parseLocalTime(scheduledTimeStr);
    final dateStr = DateFormat('dd MMM yyyy').format(dt);
    final timeStr = DateFormat('hh:mm a').format(dt);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Completed Consultation',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Colors.black),
            onPressed: _callSupport,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Completed Status
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Completed',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'You have completed the consultation with ${patientName.split(' ')[0]}.',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 24),

              // Patient details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade200,
                            image: profilePic != null 
                              ? DecorationImage(image: NetworkImage(profilePic), fit: BoxFit.cover) 
                              : const DecorationImage(image: AssetImage('assets/images/male_profile.png'), fit: BoxFit.cover),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patientName, style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.male, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('$gender  •  $age', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(distance, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(dateStr, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(timeStr, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹$price', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                            const SizedBox(height: 4),
                            const Text('Consultation Fee', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Recall Consultation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.autorenew, color: Colors.green, size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Recall Consultation', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Need to talk again?\nYou can reconnect with the patient.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.call, size: 16, color: Colors.green),
                      label: const Text('Recall', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.green),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Consultation Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Consultation Summary', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    _buildHorizontalTimeline(timeStr),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildActionIcon(Icons.chat_bubble_outline, 'Chat', 'View messages'),
                        _buildActionIcon(Icons.person_outline, 'Patient Details', 'View details'),
                        _buildActionIcon(Icons.notes, 'Summary', 'View notes'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action Block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 12),
                    const Text('Consultation Completed', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Thank you for consulting with the patient.\nWe hope they feel better soon.', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600)),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _goToPrescription,
                        icon: const Icon(Icons.call_end, color: Colors.white, size: 20),
                        label: const Text('Complete Consultation', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Security banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified_user_outlined, color: Colors.grey.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your call is secure and encrypted', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Do not share any personal information.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalTimeline(String timeStr) {
    return Stack(
      children: [
        Positioned(
          top: 11,
          left: 40,
          right: 40,
          child: Row(
            children: [
              Expanded(child: Container(height: 2, color: Colors.green)),
              Expanded(child: Container(height: 2, color: Colors.green)),
            ],
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildTimelineNode('Accepted', timeStr, true)),
            Expanded(child: _buildTimelineNode('Consultation\nCompleted', timeStr, true)),
            Expanded(child: _buildTimelineNode('Uploaded\ndescription', timeStr, true)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineNode(String label, String timeStr, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: isActive ? Colors.green : Colors.grey.shade400, width: 2),
          ),
          child: isActive ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, color: isActive ? Colors.green : Colors.grey.shade600),
        ),
        const SizedBox(height: 2),
        Text(
          timeStr,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  String _calculateAge(dynamic dateOfBirth) {
    if (dateOfBirth == null) return '28 Years';
    try {
      final birthDate = DateTime.parse(dateOfBirth.toString());
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return '$age Years';
    } catch (e) {
      return '28 Years';
    }
  }
}
