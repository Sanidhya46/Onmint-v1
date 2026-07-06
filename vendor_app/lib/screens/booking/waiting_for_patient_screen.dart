import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';

class WaitingForPatientScreen extends StatelessWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;

  const WaitingForPatientScreen({
    Key? key,
    required this.bookingId,
    required this.bookingData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final patientData = bookingData['patient'] ?? bookingData['patientDetails'] ?? {};
    String pName = 'Patient';
    if (patientData is Map) {
      pName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    }
    if (pName.isEmpty) pName = bookingData['patientName'] ?? 'Patient';

    // Find the offer date for this vendor
    String sentDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now());
    final offers = bookingData['offers'] as List?;
    if (offers != null && offers.isNotEmpty) {
      final lastOffer = offers.last;
      if (lastOffer['createdAt'] != null) {
        final dt = DateTime.tryParse(lastOffer['createdAt'].toString());
        if (dt != null) {
          sentDateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dt);
        }
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F8FD),
        foregroundColor: const Color(0xFF152238),
        centerTitle: true,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Waiting for Patient',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF152238),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image Graphic
            Image.asset(
              'assets/images/request_send_top_image.png',
              height: 220,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon placeholder if image is missing
                return Container(
                  height: 200,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.access_time_filled, size: 80, color: Color(0xFF0056D2)),
                );
              },
            ),
            const SizedBox(height: 24),

            // Card 1: Summary Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.01),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    icon: Icons.hourglass_empty,
                    iconColor: Colors.deepPurple,
                    bgColor: const Color(0xFFF3E5F5),
                    label: 'Status',
                    value: 'Waiting for Patient',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F3F9)),
                  ),
                  _buildDetailRow(
                    icon: Icons.calendar_month_outlined,
                    iconColor: Colors.blue,
                    bgColor: const Color(0xFFE8F1FF),
                    label: 'Sent On',
                    value: sentDateStr,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Color(0xFFF1F3F9)),
                  ),
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    iconColor: Colors.blue,
                    bgColor: const Color(0xFFE8F1FF),
                    label: 'Requested By',
                    value: pName,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Blue Info Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF5FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, color: Color(0xFF0056D2), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "The patient will review your offer.\nYou'll be notified once they respond.",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFF0056D2),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Contact Support Row Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: InkWell(
                onTap: () {},
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Icon(Icons.phone_in_talk, color: Color(0xFF0056D2), size: 20),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Contact Support',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF152238),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Need help? Call our support team.',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey, size: 20),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Footer check notice
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, color: Colors.indigo.shade400, size: 14),
                const SizedBox(width: 6),
                const Text(
                  'Stay online to get faster responses and better chances.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF152238),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
