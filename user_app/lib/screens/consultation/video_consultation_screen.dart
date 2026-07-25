import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoConsultationScreen extends StatefulWidget {
  final String bookingId;

  const VideoConsultationScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<VideoConsultationScreen> createState() =>
      _VideoConsultationScreenState();
}

class _VideoConsultationScreenState extends State<VideoConsultationScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _meetingConfig;
  final _apiClient = ApiClient(); // Use ApiClient directly

  @override
  void initState() {
    super.initState();
    _loadMeetingDetails();
  }

  Future<void> _loadMeetingDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _apiClient.loadToken();

      // Try to get video call link from booking details first
      try {
        final onMintClient = OnMintApiClient();
        await onMintClient.initialize();
        final booking =
            await onMintClient.patient.getBookingDetails(widget.bookingId);

        // Check if booking has video call link from backend
        if (booking.videoCallLink != null &&
            booking.videoCallLink!.isNotEmpty) {
          // Store video link for display
          setState(() {
            _meetingConfig = {'videoCallLink': booking.videoCallLink};
            _isLoading = false;
          });
          return;
        }
      } catch (e) {
        print('Could not get booking details: $e');
      }

      // Fallback: Try to create/get video room
      try {
        final response = await _apiClient.post('/video/room', data: {
          'bookingId': widget.bookingId,
          'role': 'patient', // Patient role
        });

        if (response.data['success'] == true) {
          setState(() {
            _meetingConfig = response.data['data'];
            _isLoading = false;
          });
        } else {
          throw Exception(
              response.data['message'] ?? 'Failed to create video room');
        }
      } catch (e) {
        print('Video room creation failed: $e');
        // Final fallback: Show simple video call interface
        setState(() {
          _errorMessage = null;
          _isLoading = false;
          _meetingConfig = {}; // Empty config to show simple UI
        });
      }
    } catch (e) {
      print('Error in _loadMeetingDetails: $e');
      setState(() {
        _errorMessage = null; // Don't show error, use fallback
        _isLoading = false;
        _meetingConfig = {}; // Empty config to show simple UI
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _buildVideoCallUI(),
      ),
    );
  }

  Widget _buildVideoCallUI() {
    return Stack(
      children: [
        // 1. Fullscreen Doctor View
        Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[900], // Mock background
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person, size: 100, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Waiting for doctor video...',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
              if (_meetingConfig != null && _meetingConfig!.containsKey('joinUrl'))
                Padding(
                  padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                  child: InkWell(
                    onTap: () async {
                      final url = _meetingConfig!['joinUrl'].toString();
                      final uri = Uri.parse(url);
                      try {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } catch (_) {
                        await launchUrl(uri, mode: LaunchMode.platformDefault);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.blue, width: 1),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_call, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Zoom Meeting Link (Tap to Open)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            _meetingConfig!['joinUrl'].toString(),
                            style: const TextStyle(color: Colors.lightBlueAccent, decoration: TextDecoration.underline),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            ],
          ),
        ),

        // 2. Top Bar Overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back & Info
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dr. Shubham Singh',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Row(
                              children: List.generate(4, (index) => Container(
                                margin: const EdgeInsets.only(right: 2),
                                width: 3,
                                height: 8 + (index * 2).toDouble(),
                                color: Colors.greenAccent,
                              )),
                            ),
                            const SizedBox(width: 6),
                            const Text('Good Connection', style: TextStyle(color: Colors.white, fontSize: 10)),
                            const SizedBox(width: 8),
                            const Text('05:23', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // PiP View (Patient)
              Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  image: const DecorationImage(
                    image: NetworkImage('https://via.placeholder.com/100x140'), // Mock patient view
                    fit: BoxFit.cover,
                  ),
                ),
                child: const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(4.0),
                    child: Icon(Icons.mic_off, color: Colors.red, size: 16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Bottom Controls Overlay
        Positioned(
          bottom: 30,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
              ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(Icons.chat_bubble_outline, Colors.white),
                _buildControlButton(Icons.videocam_outlined, Colors.white),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                  ),
                ),
                _buildControlButton(Icons.mic_none, Colors.white),
                _buildControlButton(Icons.cameraswitch_outlined, Colors.white),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
