import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vendor_app/screens/home/home_screen.dart';
import 'package:vendor_app/screens/doctor/appointment_details_screen.dart';

class ConsultationSuccessScreen extends StatelessWidget {
  final Map<String, dynamic>? appointment;

  const ConsultationSuccessScreen({
    super.key,
    this.appointment,
  });

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

  @override
  Widget build(BuildContext context) {
    final patient = appointment?['patient'] ?? {};
    final patientName = patient['fullName'] ?? 'Patient';
    final gender = patient['gender'] ?? 'Male';
    final age = _calculateAge(patient['dateOfBirth']);
    final distance = '3.1 km away'; 
    final profilePic = patient['profilePicture'];
    final price = appointment?['price'] ?? appointment?['totalAmount'] ?? 300;

    final String scheduledTimeStr = appointment?['scheduledTime'] ?? appointment?['createdAt'] ?? '';
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
          onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
        ),
        title: const Text(
          'Consultation Completed',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Consultation Completed Successfully',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Thank you for consulting with us.\nWe wish you good health!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                              child: const Icon(Icons.call, color: Colors.green, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Call Time', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey)),
                                Text(timeStr, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        Container(width: 1, height: 32, color: Colors.grey.shade300),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                              child: const Icon(Icons.calendar_today, color: Colors.green, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Date', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey)),
                                Text(dateStr, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Patient details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
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
                          const Text('Patient', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.male, size: 14, color: Colors.black54),
                              const SizedBox(width: 4),
                              Text('$gender  •  $age', style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.black87)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 60, color: Colors.grey.shade200, margin: const EdgeInsets.symmetric(horizontal: 16)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Consultation Fee', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('₹$price', style: const TextStyle(fontFamily: 'Poppins', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.green, size: 12),
                              SizedBox(width: 4),
                              Text('Completed', style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Prescription Uploaded block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        const Icon(Icons.description_outlined, color: Colors.blue, size: 36),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Prescription Uploaded Successfully', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('The prescription has been securely saved and shared with the patient.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Privacy block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.privacy_tip_outlined, color: Colors.green, size: 32),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your Privacy is Our Priority', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Medical records are encrypted and securely stored with us.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.home_outlined, color: Colors.white),
                  label: const Text('Continue to Home', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetailsScreen(
                          appointmentId: appointment?['_id'] ?? appointment?['id'] ?? '',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.receipt_long_outlined, color: Colors.green),
                  label: const Text('View Consultation Details', style: TextStyle(color: Colors.green, fontSize: 15, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Support block
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.headset_mic_outlined, color: Colors.grey.shade700),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Need Help?', style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('Our support team is here to help you.', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
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
}
