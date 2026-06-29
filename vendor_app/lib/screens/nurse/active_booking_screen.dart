import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ui_components/ui_components.dart';

class ActiveBookingScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic>? bookingData;

  const ActiveBookingScreen({
    super.key,
    required this.bookingId,
    this.bookingData,
  });

  @override
  State<ActiveBookingScreen> createState() => _ActiveBookingScreenState();
}

class _ActiveBookingScreenState extends State<ActiveBookingScreen> {
  final _apiClient = OnMintApiClient();
  bool _isLoading = true;
  Map<String, dynamic>? _bookingDetails;
  bool _isActing = false;

  @override
  void initState() {
    super.initState();
    if (widget.bookingData != null) {
      _bookingDetails = widget.bookingData;
      _isLoading = false;
    } else {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.initialize();
      final response = await _apiClient.nurse.getBookingDetails(widget.bookingId);
      if (mounted) {
        setState(() {
          _bookingDetails = response['data'] ?? response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.showError('Failed to load details');
      }
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isActing = true);
    try {
      await _apiClient.initialize();
      final isRealtime = (_bookingDetails ?? widget.bookingData ?? {})['isRealtimeBooking'] == true || (_bookingDetails ?? widget.bookingData ?? {})['bookingType'] == 'realtime';

      if (isRealtime) {
        await _apiClient.nurse.updateRealtimeBookingStatus(widget.bookingId, newStatus);
      } else {
        if (newStatus == 'completed') {
          await _apiClient.nurse.completeVisit(widget.bookingId);
        } else if (newStatus == 'reached') {
          await _apiClient.nurse.startVisit(widget.bookingId); 
        } else if (newStatus == 'on_the_way') {
          try {
            await _apiClient.nurse.startVisit(widget.bookingId);
          } catch (e) {}
        }
      }
      
      if (mounted) {
        setState(() {
          if (_bookingDetails != null) {
            _bookingDetails!['status'] = newStatus;
          }
        });
        ToastUtils.showSuccess('Status updated to $newStatus');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to update status');
      }
    } finally {
      if (mounted) {
        setState(() => _isActing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_bookingDetails == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 0),
        body: const Center(child: Text('Order not found')),
      );
    }

    final booking = _bookingDetails!;
    final patientData = booking['patient'] ?? booking['patientDetails'] ?? {};
    
    final fullName = patientData['fullName'] ?? '${patientData['firstName'] ?? ''} ${patientData['lastName'] ?? ''}'.trim();
    final displayName = fullName.isEmpty ? 'Umeya Khan' : fullName;
    final age = patientData['age']?.toString() ?? '27';
    final gender = patientData['gender'] ?? 'Female';
    final phone = patientData['phone'] ?? '';
    final profilePicture = patientData['profilePicture']?.toString() ?? '';
    
    final locationData = booking['location'];
    final address = (locationData is Map && locationData['address'] != null) 
        ? locationData['address'] 
        : 'Not specified';

    // Dates
    String dateStr = '13 May 2025';
    String timeStr = '10:00 AM';
    if (booking['createdAt'] != null) {
      final dt = DateTime.tryParse(booking['createdAt'].toString());
      if (dt != null) {
        dateStr = DateFormat('dd MMM yyyy').format(dt);
        timeStr = DateFormat('hh:mm a').format(dt);
      }
    }

    final status = booking['status']?.toString().toLowerCase() ?? 'accepted';
    final fees = booking['fees'] ?? booking['price'] ?? booking['totalAmount'] ?? 300;
    
    final notes = booking['notes'] ?? booking['requirements']?['description'] ?? 'Requires experienced nurse';
    final serviceType = booking['title'] ?? booking['serviceType'] ?? 'Baby & Mother Care';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
          onPressed: () => Navigator.pop(context, true),
        ),
        title: const Text(
          'Nurse Booking',
          style: TextStyle(
            color: Color(0xFF152238),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.headset_mic_outlined, color: Color(0xFF152238)),
            onPressed: () {
              if (phone.isNotEmpty) _makePhoneCall(phone);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchDetails,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  // User / Request Header Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage: profilePicture.isNotEmpty 
                              ? NetworkImage(profilePicture)
                              : AssetImage(gender.toString().toLowerCase() == 'female' ? 'assets/images/female_profile.png' : 'assets/images/male_profile.png') as ImageProvider,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF152238),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(gender.toString().toLowerCase() == 'female' ? Icons.female : Icons.male, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 2),
                                  Text(
                                    gender,
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(width: 4, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$age Years',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Colors.grey, size: 14),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      address,
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w400),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(dateStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.access_time_outlined, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '₹$fees',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.green),
                            ),
                            const Text(
                              'Service Fee',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
  
                  // Booking Details Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.assignment, color: Color(0xFF1565C0), size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Booking Details',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF152238)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRowItem('Service Type', serviceType),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFFF0F0F0), height: 1)),
                        _buildRowItem('Shift', booking['requirements']?['shift'] ?? 'Day Shift'),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFFF0F0F0), height: 1)),
                        _buildRowItem('Patient Age', '$age Years'),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFFF0F0F0), height: 1)),
                        _buildRowItem('Preferred Date', dateStr),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFFF0F0F0), height: 1)),
                        _buildRowItem('Preferred Time', timeStr),
                        const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(color: Color(0xFFF0F0F0), height: 1)),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: Text('Additional Note', style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
                            Expanded(child: Text(notes, textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF152238)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
  
                  // Timeline and Action Buttons
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.timeline, color: Colors.green, size: 16),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Status Tracking',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF152238)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildHorizontalTimeline(status),
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: Color(0xFFE0E0E0)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _buildActionBtn(Icons.phone, 'Call Patient', () {
                              if (phone.isNotEmpty) _makePhoneCall(phone);
                            })),
                            Container(width: 1, height: 40, color: Colors.grey.shade300),
                            Expanded(child: _buildActionBtn(Icons.chat_bubble, 'Chat', () {})),
                            Container(width: 1, height: 40, color: Colors.grey.shade300),
                            Expanded(child: _buildActionBtn(Icons.map, 'Open Map', () {})),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20), // Space for bottom button
                ],
              ),
            ),
          ),
          if (_isActing)
            Container(
              color: Colors.white.withOpacity(0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF0F0F0))),
        ),
        child: SizedBox(
          height: 48,
          child: status == 'completed'
              ? ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text('Completed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              : ElevatedButton.icon(
                  onPressed: () {
                    if (status == 'accepted') {
                      _updateStatus('on_the_way');
                    } else if (status == 'on_the_way') {
                      _updateStatus('reached');
                    } else if (status == 'reached' || status == 'in_progress') {
                      _updateStatus('completed');
                    }
                  },
                  icon: Icon(
                    status == 'accepted' ? Icons.directions_bike : (status == 'on_the_way' ? Icons.location_on : Icons.check),
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    status == 'accepted' ? 'I Am On The Way' : (status == 'on_the_way' ? 'Reached' : 'Mark as Completed'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047CB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
        ),
      ),
    );
  }
  
  Widget _buildRowItem(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF152238)),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF152238)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline(String status) {
    int currentIndex = 0;
    if (status == 'on_the_way') {
      currentIndex = 1;
    } else if (status == 'reached' || status == 'in_progress') {
      currentIndex = 2;
    } else if (status == 'completed') {
      currentIndex = 3;
    }

    // Time mock logic (should be real from booking data ideally)
    String timeAccepted = 'Just Now';
    String timeOnWay = currentIndex >= 1 ? '10:05 AM' : '--:--';
    String timeReached = currentIndex >= 2 ? '10:30 AM' : '--:--';
    String timeComplete = currentIndex >= 3 ? '11:00 AM' : '--:--';

    return Stack(
      children: [
        // Background lines
        Positioned(
          top: 11,
          left: 40,
          right: 40,
          child: Row(
            children: [
              Expanded(child: Container(height: 2, color: 0 < currentIndex ? Colors.green : Colors.grey.shade300)),
              Expanded(child: Container(height: 2, color: 1 < currentIndex ? Colors.green : Colors.grey.shade300)),
              Expanded(child: Container(height: 2, color: 2 < currentIndex ? Colors.green : Colors.grey.shade300)),
            ],
          ),
        ),
        // Nodes
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _buildTimelineNode('Accepted', timeAccepted, 0 <= currentIndex)),
            Expanded(child: _buildTimelineNode('On The Way', timeOnWay, 1 <= currentIndex)),
            Expanded(child: _buildTimelineNode('Reached', timeReached, 2 <= currentIndex)),
            Expanded(child: _buildTimelineNode('Complete', timeComplete, 3 <= currentIndex)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineNode(String label, String timeLabel, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isActive ? Colors.green : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? Colors.green : Colors.green,
              width: 2,
            ),
          ),
          child: isActive
              ? const Icon(Icons.check, color: Colors.white, size: 14)
              : null,
        ),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive ? Colors.green : Colors.grey.shade600,
          ),
        ),
        Text(
          timeLabel,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 9,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
