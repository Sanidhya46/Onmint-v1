import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

/// Video call screen using native Flutter UI (no WebView)
class VideoCallScreen extends StatefulWidget {
  final String meetingId;
  final String userName;
  final String? bookingId;

  const VideoCallScreen({
    super.key,
    required this.meetingId,
    required this.userName,
    this.bookingId,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _apiClient = ApiClient();
  bool _isLoading = true;
  bool _isInitializing = true;
  String? _errorMessage;
  Map<String, dynamic>? _videoRoomData;

  @override
  void initState() {
    super.initState();
    _initializeVideoCall();
  }

  Future<void> _initializeVideoCall() async {
    setState(() => _isInitializing = true);
    
    try {
      await _apiClient.loadToken();
      
      if (widget.bookingId != null) {
        try {
          final roomData = await _apiClient.post('/video/room', data: {
            'bookingId': widget.bookingId!,
            'role': 'host',
          });
          
          if (roomData.data['success'] == true) {
            setState(() {
              _videoRoomData = roomData.data['data'];
              _isInitializing = false;
              _isLoading = false;
            });
          } else {
            throw Exception(roomData.data['message'] ?? 'Failed to create video room');
          }
        } catch (e) {
          print('Video room API failed: $e');
          setState(() {
            _videoRoomData = null;
            _isInitializing = false;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = null;
          _isInitializing = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error in _initializeVideoCall: $e');
      setState(() {
        _errorMessage = null;
        _isInitializing = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _endVideoCall() async {
    if (widget.bookingId != null) {
      try {
        // End the video call
        final response = await _apiClient.post('/video/end/${widget.bookingId}', data: {});
        if (response.data['success'] == true) {
          debugPrint('Video call ended successfully');
          
          // Update booking to mark video call as completed
          try {
            await _apiClient.post('/doctor/appointments/${widget.bookingId}/video-completed', data: {});
            debugPrint('Booking updated with video call completion');
          } catch (e) {
            debugPrint('Error updating booking: $e');
            // Continue anyway, video call was ended
          }
        }
      } catch (e) {
        debugPrint('Error ending video call: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isInitializing
            ? _buildInitializingView()
            : _errorMessage != null
                ? _buildErrorView()
                : _buildSimpleVideoCallUI(),
      ),
    );
  }

  Widget _buildInitializingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 24),
          Text(
            'Initializing video call...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to start video call',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unknown error',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleVideoCallUI() {
    final hasVideoData = _videoRoomData != null && _videoRoomData!.isNotEmpty;
    final joinUrl = _videoRoomData?['joinUrl'] as String?;
    
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3), width: 2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.videocam, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    '🏥 Video Consultation Active',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Doctor: ${widget.userName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  if (widget.bookingId != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Booking ID: ${widget.bookingId}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            if (hasVideoData && _videoRoomData!.containsKey('participants')) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(height: 12),
                    const Text(
                      '✅ Video Room Created',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Doctor', _videoRoomData!['participants']?['doctor']?['name'] ?? widget.userName),
                    _buildInfoRow('Patient', _videoRoomData!['participants']?['patient']?['name'] ?? 'Patient'),
                    _buildInfoRow('Meeting ID', _videoRoomData!['meetingId']?.toString() ?? 'N/A'),
                    _buildInfoRow('Status', _videoRoomData!['appointmentDetails']?['status'] ?? 'Ready'),
                  ],
                ),
              ),
              
              // Join URL Button
              if (joinUrl != null && joinUrl.isNotEmpty) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Show dialog with join URL
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Row(
                          children: [
                            Icon(Icons.videocam, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Join Video Call'),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Click the link below to start the video consultation:'),
                            const SizedBox(height: 16),
                            SelectableText(
                              joinUrl,
                              style: const TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Note: The link will open in a new window.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);
                              // Open URL in new window/browser
                              final uri = Uri.parse(joinUrl);
                              try {
                                await launchUrl(
                                  uri,
                                  mode: LaunchMode.externalApplication,
                                );
                              } catch (err) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Could not open: $joinUrl'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open Link'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.videocam, size: 28),
                  label: const Text('Start Video Call', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                    minimumSize: const Size(double.infinity, 60),
                  ),
                ),
              ],
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 32),
                    SizedBox(height: 12),
                    Text(
                      '📞 Consultation Ready',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You are now connected to the video consultation.\nThe patient can join using their booking details.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isInitializing = true;
                    });
                    _initializeVideoCall();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Connection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('End Call'),
                        content: const Text('Are you sure you want to end this video call?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('End Call'),
                          ),
                        ],
                      ),
                    );

                    if (result == true) {
                      await _endVideoCall();
                      if (mounted) {
                        Navigator.pop(context);
                      }
                    }
                  },
                  icon: const Icon(Icons.call_end),
                  label: const Text('End Consultation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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

  @override
  void dispose() {
    _endVideoCall();
    super.dispose();
  }
}
