import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:user_app/screens/home/home_screen.dart';
import 'package:api_client/api_client.dart' as api_client;
import 'package:user_app/screens/booking/download_prescription_screen.dart';
import 'package:user_app/screens/booking/order_detail_file.dart';

class UserConsultationEndedScreen extends StatefulWidget {
  final String bookingId;
  final String doctorName;
  final int duration;

  const UserConsultationEndedScreen({
    super.key,
    required this.bookingId,
    required this.doctorName,
    required this.duration,
  });

  @override
  State<UserConsultationEndedScreen> createState() => _UserConsultationEndedScreenState();
}

class _UserConsultationEndedScreenState extends State<UserConsultationEndedScreen> {
  final _apiClient = api_client.OnMintApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _bookingData;
  String _dateStr = '';
  String _timeStr = '';
  String _priceStr = '₹300';

  @override
  void initState() {
    super.initState();
    _loadBookingDetails();
  }

  Future<void> _loadBookingDetails() async {
    try {
      await _apiClient.initialize();
      final res = await _apiClient.get('/realtime-bookings/${widget.bookingId}');
      if (mounted) {
        final data = res.data['data'];
        
        setState(() {
          _bookingData = data;
          
          final scheduledTimeStr = data['scheduledTime'] ?? data['createdAt'] ?? '';
          if (scheduledTimeStr.isNotEmpty) {
            try {
              String cd = scheduledTimeStr;
              if (cd.endsWith('Z')) cd = cd.substring(0, cd.length - 1);
              final dt = DateTime.parse(cd);
              _dateStr = DateFormat('dd MMM yyyy').format(dt);
              _timeStr = DateFormat('hh:mm a').format(dt);
            } catch (e) {
              _dateStr = scheduledTimeStr;
            }
          }
          
          if (data['price'] != null) {
            _priceStr = '₹${data['price']}';
          } else if (data['totalAmount'] != null) {
            _priceStr = '₹${data['totalAmount']}';
          }
          
          _isLoading = false;
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

  void _goHome(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final doctorName = _bookingData?['doctorName'] ?? widget.doctorName;
    final doctorImage = _bookingData?['doctor']?['profilePic'];
    
    // Fallback to simple parse if needed
    final dName = doctorName.isEmpty ? 'Doctor' : (doctorName.startsWith('Dr') ? doctorName : 'Dr. $doctorName');

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
          'Completed Consultation',
          style: TextStyle(
            color: Color(0xFF152238),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent, color: Color(0xFF1565C0)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Success Header Box
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
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Color(0xFF107C41),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Completed',
                    style: TextStyle(
                      color: Color(0xFF107C41),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You have completed the consultation with $dName.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Doctor Card
            Container(
              width: double.infinity,
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
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue.shade50,
                        backgroundImage: doctorImage != null ? NetworkImage(doctorImage) : null,
                        child: doctorImage == null ? const Icon(Icons.person, size: 30, color: Colors.blue) : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF152238),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'MBBS • General Physician',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('Online', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_month, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(_dateStr, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(_timeStr, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _priceStr,
                            style: const TextStyle(
                              color: Color(0xFF107C41),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Consultation Fee',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Recall Consultation Card
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.sync, color: Color(0xFF107C41)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recall Consultation',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Need to talk again?\nYou can reconnect with the doctor.',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.call, size: 16, color: Color(0xFF107C41)),
                    label: const Text('Recall', style: TextStyle(color: Color(0xFF107C41))),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF107C41)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Consultation Summary Timeline
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
                  const Text(
                    'Consultation Summary',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF152238),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF107C41), size: 24),
                            const SizedBox(height: 8),
                            const Text('Accepted', style: TextStyle(color: Color(0xFF107C41), fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(_timeStr, style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(width: 40, height: 2, color: const Color(0xFF107C41)),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF107C41), size: 24),
                            const SizedBox(height: 8),
                            const Text('Consultation\nCompleted', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF107C41), fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(_timeStr, style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(width: 40, height: 2, color: const Color(0xFF107C41)),
                      Expanded(
                        child: Column(
                          children: [
                            const Icon(Icons.check_circle, color: Color(0xFF107C41), size: 24),
                            const SizedBox(height: 8),
                            const Text('Open Prescription', style: TextStyle(color: Color(0xFF107C41), fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(_timeStr, style: const TextStyle(fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryAction(Icons.chat_bubble_outline, 'Chat', 'View messages'),
                      _buildSummaryAction(Icons.person_outline, 'Doctor Details', 'View details'),
                      _buildSummaryAction(Icons.description_outlined, 'Summary', 'View notes'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Bottom Action Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF107C41), size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    'Consultation Completed',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF152238),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Thank you for consulting with the doctor.\nWe hope you feel better soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderDetailFile(bookingId: widget.bookingId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.description_outlined),
                      label: const Text(
                        'Go To Prescription Page',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF107C41),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Security badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shield_outlined, color: Colors.grey.shade700, size: 24),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your call is secure and encrypted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('Do not share any personal information.', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryAction(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey.shade700, size: 24),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 2),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
      ],
    );
  }
}
