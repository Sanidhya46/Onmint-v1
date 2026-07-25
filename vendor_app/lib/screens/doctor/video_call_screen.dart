import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'consultation_ended_screen.dart';

class VideoCallScreen extends StatefulWidget {
  final String bookingId;
  final String patientName;
  final String? patientImage;
  final Map<String, dynamic>? appointment;

  const VideoCallScreen({
    super.key,
    required this.bookingId,
    required this.patientName,
    this.patientImage,
    this.appointment,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen>
    with TickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  final _socketService = SocketService();

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOff = false;
  bool _isConnecting = true;
  bool _hasError = false;
  bool _isPatientConnected = false;
  bool _isEndingCall = false;
  bool _zoomLaunched = false;

  Timer? _timer;
  int _secondsElapsed = 0;

  String? _zoomStartUrl;
  String? _zoomJoinUrl;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription? _patientJoinedSub;
  StreamSubscription? _consultationEndedSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _setupSocketListeners();
    _connectToCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _patientJoinedSub?.cancel();
    _consultationEndedSub?.cancel();
    _socketService.leaveBooking(widget.bookingId);
    super.dispose();
  }

  void _setupSocketListeners() {
    // Join booking room for WebSocket updates
    _socketService.joinBooking(widget.bookingId);

    // Listen for patient joining
    _patientJoinedSub = _socketService.patientJoined.listen((data) {
      if (data['bookingId'] == widget.bookingId && mounted) {
        setState(() => _isPatientConnected = true);
      }
    });

    // Listen for consultation ended (in case it's triggered elsewhere)
    _consultationEndedSub = _socketService.consultationEnded.listen((data) {
      if (data['bookingId'] == widget.bookingId && mounted) {
        _navigateToEndedScreen();
      }
    });
  }

  Future<void> _connectToCall() async {
    try {
      // Start consultation via API (sets doctor_on_call = true)
      await _apiClient.doctor.startConsultation(widget.bookingId);

      // Create/get video room to get Zoom URLs
      final roomData = await _apiClient.doctor.createVideoRoom(widget.bookingId);

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _zoomStartUrl = roomData['startUrl'];
          _zoomJoinUrl = roomData['joinUrl'];
        });
        _startTimer();

        // Auto-launch Zoom meeting for doctor (host)
        _launchZoomMeeting();

        // Check initial call status
        _checkCallStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect: $e')),
        );
      }
    }
  }

  Future<void> _checkCallStatus() async {
    try {
      final status = await _apiClient.doctor.getCallStatus(widget.bookingId);
      if (mounted && status['patient_on_call'] == true) {
        setState(() => _isPatientConnected = true);
      }
    } catch (_) {}
  }

  Future<void> _launchZoomMeeting() async {
    final url = _zoomStartUrl ?? _zoomJoinUrl;
    if (url != null && !_zoomLaunched) {
      _zoomLaunched = true;
      try {
        final uri = Uri.parse(url);
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening Zoom: $e')),
          );
        }
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String _formatDuration() {
    int minutes = _secondsElapsed ~/ 60;
    int seconds = _secondsElapsed % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _endCall() async {
    if (_isEndingCall) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Consultation'),
        content: const Text(
          'Are you sure you want to end this consultation? This will disconnect both you and the patient.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Call', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isEndingCall = true);

    try {
      // Complete the consultation via API
      await _apiClient.doctor.completeConsultation(widget.bookingId);
      _navigateToEndedScreen();
    } catch (e) {
      if (mounted) {
        setState(() => _isEndingCall = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to end call: $e')),
        );
      }
    }
  }

  void _navigateToEndedScreen() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ConsultationEndedScreen(
          bookingId: widget.bookingId,
          patientName: widget.patientName,
          duration: _secondsElapsed,
          appointment: widget.appointment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117),
      body: SafeArea(
        child: Stack(
          children: [
            // Main background with camera/avatar view
            _buildMainView(),

            // Top bar with status indicators
            if (!_isConnecting) _buildTopBar(),

            // Timer when connected
            if (!_isConnecting && _isPatientConnected)
              Positioned(
                top: 56,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _formatDuration(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // PIP self view (camera preview)
            if (!_isConnecting) _buildPipView(),

            // Bottom Controls
            if (!_isConnecting) _buildBottomControls(),

            // Ending overlay
            if (_isEndingCall) _buildEndingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1A1D27),
      child: _isConnecting
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text('Starting consultation...',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  SizedBox(height: 8),
                  Text('Launching Zoom meeting...',
                      style: TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 60),
                      const SizedBox(height: 16),
                      const Text('Connection failed',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _isConnecting = true;
                            _hasError = false;
                          });
                          _connectToCall();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Center(
                  child: _isPatientConnected
                      ? _buildConnectedView()
                      : _buildWaitingView(),
                ),
    );
  }

  Widget _buildConnectedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Patient avatar/video placeholder
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueGrey.shade800,
            image: widget.patientImage != null &&
                    widget.patientImage!.startsWith('http')
                ? DecorationImage(
                    image: NetworkImage(widget.patientImage!),
                    fit: BoxFit.cover,
                  )
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: widget.patientImage == null ||
                  !widget.patientImage!.startsWith('http')
              ? const Icon(Icons.person, size: 80, color: Colors.white38)
              : null,
        ),
        const SizedBox(height: 16),
        Text(widget.patientName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            const Text('Connected • In call',
                style: TextStyle(color: Colors.green, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _formatDuration(),
          style: const TextStyle(
              color: Colors.white54, fontSize: 24, fontWeight: FontWeight.w300),
        ),
        const SizedBox(height: 16),
        if (_zoomStartUrl != null || _zoomJoinUrl != null)
          _buildZoomLinkWidget((_zoomStartUrl ?? _zoomJoinUrl)!),
      ],
    );
  }

  Widget _buildWaitingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueGrey.shade800,
            image: widget.patientImage != null &&
                    widget.patientImage!.startsWith('http')
                ? DecorationImage(
                    image: NetworkImage(widget.patientImage!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.patientImage == null ||
                  !widget.patientImage!.startsWith('http')
              ? const Icon(Icons.person, size: 80, color: Colors.white38)
              : null,
        ),
        const SizedBox(height: 16),
        Text(widget.patientName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Waiting for patient to join...',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 16),
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.blue.shade300,
          ),
        ),
        const SizedBox(height: 16),
        if (_zoomStartUrl != null || _zoomJoinUrl != null)
          _buildZoomLinkWidget((_zoomStartUrl ?? _zoomJoinUrl)!),
      ],
    );
  }

  Widget _buildZoomLinkWidget(String url) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.6), width: 1.5),
      ),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(url);
          try {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } catch (_) {
            await launchUrl(uri, mode: LaunchMode.platformDefault);
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.video_call, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  'Zoom Meeting Link (Tap to Start/Join)',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SelectableText(
              url,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Zoom link copied to clipboard!'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.withOpacity(0.5)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.copy, color: Colors.blue, size: 14),
                    SizedBox(width: 6),
                    Text(
                      'Copy Link',
                      style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.w600),
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

  Widget _buildTopBar() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: const Row(
              children: [
                Icon(Icons.lock, color: Colors.green, size: 12),
                SizedBox(width: 5),
                Text('End-to-end Encrypted',
                    style: TextStyle(color: Colors.white, fontSize: 11)),
              ],
            ),
          ),
          const Spacer(),
          // LIVE badge when patient is connected
          if (_isPatientConnected)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.green.withOpacity(0.6), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green
                          .withOpacity(0.3 * _pulseAnimation.value),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(_pulseAnimation.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withOpacity(0.7),
                            blurRadius: 4,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text('LIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1)),
                  ],
                ),
              ),
            ),
          if (!_isPatientConnected)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Text(_formatDuration(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildPipView() {
    return Positioned(
      right: 16,
      bottom: 110,
      child: Container(
        width: 90,
        height: 120,
        decoration: BoxDecoration(
          color: const Color(0xFF2C3044),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _isCameraOff
              ? const Center(
                  child: Icon(Icons.videocam_off,
                      color: Colors.white38, size: 30),
                )
              : const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam, color: Colors.blue, size: 28),
                      SizedBox(height: 4),
                      Text('You',
                          style: TextStyle(color: Colors.white54, fontSize: 10)),
                      Text('(Zoom)',
                          style: TextStyle(color: Colors.white30, fontSize: 8)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withOpacity(0.85),
              Colors.transparent,
            ],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControl(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              label: _isMuted ? 'Unmute' : 'Mute',
              isActive: !_isMuted,
              onTap: () => setState(() => _isMuted = !_isMuted),
            ),
            _buildControl(
              icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: _isCameraOff ? 'Cam On' : 'Cam Off',
              isActive: !_isCameraOff,
              onTap: () => setState(() => _isCameraOff = !_isCameraOff),
            ),
            _buildControl(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
              label: 'Speaker',
              isActive: _isSpeakerOn,
              onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
            ),
            _buildControl(
              icon: Icons.videocam,
              label: 'Zoom',
              isActive: true,
              onTap: () {
                _zoomLaunched = false;
                _launchZoomMeeting();
              },
            ),
            // End Call (only doctor can end)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: const Icon(Icons.call_end,
                        color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('End',
                    style: TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEndingOverlay() {
    return Container(
      color: Colors.black87,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 16),
            Text('Ending consultation...',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildControl({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.08),
              border: Border.all(
                color: isActive
                    ? Colors.white30
                    : Colors.red.withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Icon(icon,
                color: isActive ? Colors.white : Colors.red.shade300,
                size: 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}
