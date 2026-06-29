import 'package:flutter/material.dart';

class ActiveServiceTrackingScreen extends StatelessWidget {
  final String serviceType; // 'ambulance', 'doctor', 'nurse', 'lab_test'
  final Map<String, dynamic> bookingDetails;

  const ActiveServiceTrackingScreen({
    super.key,
    required this.serviceType,
    required this.bookingDetails,
  });

  String get _title {
    switch (serviceType) {
      case 'ambulance':
        return 'Ambulance';
      case 'doctor':
      case 'consultation':
        return 'Doctor';
      case 'nurse':
        return 'Nurse';
      case 'lab_test':
      case 'lab test':
      case 'labtest':
      case 'pathology':
        return 'Lab Test';
      case 'bloodbank':
      case 'blood bank':
        return 'Blood Bank';
      default:
        return 'Service';
    }
  }

  String get _providerName {
    switch (serviceType) {
      case 'ambulance':
        return 'ambulance provider';
      case 'doctor':
      case 'consultation':
        return 'doctor';
      case 'nurse':
        return 'nurse provider';
      case 'lab_test':
      case 'lab test':
      case 'labtest':
      case 'pathology':
        return 'lab partner';
      case 'bloodbank':
      case 'blood bank':
        return 'blood bank';
      default:
        return 'provider';
    }
  }

  Color get _themeColor {
    switch (serviceType) {
      case 'ambulance':
      case 'bloodbank':
      case 'blood bank':
        return Colors.red;
      case 'doctor':
      case 'consultation':
      case 'nurse':
        return Colors.blue;
      case 'lab_test':
      case 'lab test':
      case 'labtest':
      case 'pathology':
        return Colors.teal;
      default:
        return const Color(0xFF0D47A1);
    }
  }

  Widget _getServiceImage() {
    // Attempting to use network placeholders or generic icons matching the images
    switch (serviceType) {
      case 'ambulance':
        return const Icon(Icons.airport_shuttle, size: 80, color: Colors.red);
      case 'doctor':
      case 'consultation':
        return const Icon(Icons.person, size: 80, color: Colors.blue);
      case 'nurse':
        return const Icon(Icons.local_hospital, size: 80, color: Colors.blue);
      case 'lab_test':
      case 'lab test':
      case 'labtest':
      case 'pathology':
        return const Icon(Icons.science, size: 80, color: Colors.teal);
      case 'bloodbank':
      case 'blood bank':
        return const Icon(Icons.bloodtype, size: 80, color: Colors.red);
      default:
        return const Icon(Icons.medical_services, size: 80, color: Colors.blue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status =
        bookingDetails['status']?.toString().toLowerCase() ?? 'pending';
    final isAccepted = status != 'pending' && status != 'requested';

    String statusTitle = 'Request Sent Successfully';
    String statusSubtitle =
        'We are waiting for a $_providerName to accept\nyour request.';
    String bottomStatus = 'Waiting for $_providerName to accept';

    if (status == 'accepted') {
      statusTitle = 'Request Accepted';
      statusSubtitle = 'Your $_providerName has accepted the request.';
      bottomStatus = 'Accepted by $_providerName';
    } else if (status == 'on_the_way') {
      statusTitle = 'Provider On The Way';
      statusSubtitle = 'Your $_providerName is on the way to your location.';
      bottomStatus = 'Provider is arriving soon';
    } else if (status == 'sample_collected') {
      statusTitle = 'Sample Collected';
      statusSubtitle = 'Your sample has been collected successfully.';
      bottomStatus = 'Processing sample...';
    } else if (status == 'reached' ||
        (serviceType == 'ambulance' && status == 'in_progress')) {
      statusTitle =
          serviceType == 'ambulance' ? 'At Pickup Point' : 'Provider Reached';
      statusSubtitle = serviceType == 'ambulance'
          ? 'Ambulance has reached the pickup location.'
          : 'Your $_providerName has arrived at your location.';
      bottomStatus = serviceType == 'ambulance'
          ? 'Ambulance arrived'
          : 'Provider has arrived';
    } else if (status == 'completed') {
      statusTitle = 'Service Completed';
      statusSubtitle = 'The service has been completed successfully.';
      bottomStatus = 'Completed';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF4A148C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Booking',
          style: TextStyle(
            color: Color(0xFF152238),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined,
                color: Color(0xFF4A148C)),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          children: [
            // Title & Date
            Row(
              children: [
                Text(
                  _title,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: _themeColor),
                ),
                const Text(
                  ' Booking',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF152238)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Requested on 12 May 2025, 11:20 AM',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Animated Status Image Area
            SizedBox(
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Rotating outline effect (simplified for this screen, complex is in home screen)
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _themeColor.withOpacity(0.2), width: 2),
                    ),
                  ),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _themeColor.withOpacity(0.5), width: 1.5),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        isAccepted ? Icons.check : Icons.hourglass_top,
                        color: isAccepted ? Colors.green : Colors.blue,
                        size: 24,
                      ),
                    ),
                  ),
                  // Main Image
                  _getServiceImage(),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Text(
              statusTitle,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF152238)),
            ),
            const SizedBox(height: 4),
            Text(
              statusSubtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: Colors.grey.shade600, height: 1.3),
            ),

            const SizedBox(height: 12),

            // Booking Details Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 2)),
                ],
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Booking Details',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF152238))),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                      Icons.person_outline, 'Patient Name', 'Ali Raza'),
                  _buildDivider(),
                  _buildDetailRow(
                      Icons.phone_outlined, 'Phone Number', '+92 300 1234567'),
                  _buildDivider(),
                  if (serviceType != 'ambulance') ...[
                    _buildDetailRow(
                        Icons.calendar_today_outlined, 'Age', '45 Years'),
                    _buildDivider(),
                  ],
                  if (serviceType == 'lab_test') ...[
                    _buildDetailRow(Icons.science_outlined, 'Test Name',
                        'CBC (Complete Blood Count)'),
                    _buildDivider(),
                  ],
                  _buildDetailRow(Icons.location_on_outlined, 'Location',
                      'Gulshan-e-Iqbal, Karachi'),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Bottom Action Cards
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionRow(
                      Icons.hourglass_empty,
                      'Status',
                      bottomStatus,
                      isAccepted ? Colors.green : Colors.blue,
                    ),
                    const SizedBox(height: 8),
                    _buildActionRow(
                      Icons.notifications_none,
                      'We will notify you',
                      'Once a $_providerName accepts your request',
                      Colors.black87,
                    ),
                    const SizedBox(height: 8),
                    _buildActionRow(
                      Icons.headset_mic_outlined,
                      'Need help?',
                      'You can contact support anytime',
                      Colors.black87,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 12),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF152238)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
    );
  }

  Widget _buildActionRow(
      IconData icon, String title, String subtitle, Color titleColor) {
    return Row(
      children: [
        Icon(icon, size: 22, color: Colors.blue),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: titleColor),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ],
    );
  }
}
