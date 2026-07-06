import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:url_launcher/url_launcher.dart';
import 'user_consultation_ended_screen.dart';

class UserVideoCallScreen extends StatefulWidget {
  final String bookingId;
  final String doctorName;
  final String? doctorImage;

  const UserVideoCallScreen({
    super.key,
    required this.bookingId,
    required this.doctorName,
    this.doctorImage,
  });

  @override
  State<UserVideoCallScreen> createState() => _UserVideoCallScreenState();
}

class _UserVideoCallScreenState extends State<UserVideoCallScreen>
    with TickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  final _socketService = SocketService();

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  bool _isCameraOff = false;
  bool _isConnecting = true;
  bool _hasError = false;
  bool _isDoctorConnected = false;
  bool _zoomLaunched = false;

  Timer? _timer;
  int _secondsElapsed = 0;

  String? _zoomJoinUrl;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  StreamSubscription? _doctorJoinedSub;
  StreamSubscription? _consultationEndedSub;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.7, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _setupSocketListeners();
    _connectToCall();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _doctorJoinedSub?.cancel();
    _consultationEndedSub?.cancel();
    _socketService.leaveBooking(widget.bookingId);
    super.dispose();
  }

  void _setupSocketListeners() {
    _socketService.joinBooking(widget.bookingId);

    _doctorJoinedSub = _socketService.doctorJoined.listen((data) {
      if (data['bookingId'] == widget.bookingId && mounted) {
        setState(() => _isDoctorConnected = true);
      }
    });

    // Listen for consultation ended by doctor
    _consultationEndedSub = _socketService.consultationEnded.listen((data) {
      if (data['bookingId'] == widget.bookingId && mounted) {
        _navigateToEndedScreen(data['duration']);
      }
    });
  }

  Future<void> _connectToCall() async {
    try {
      // Patient joins using createVideoRoom (marks patient_on_call = true)
      final roomData =
          await _apiClient.patient.joinVideoCall(widget.bookingId);

      if (mounted) {
        setState(() {
          _isConnecting = false;
          _zoomJoinUrl = roomData['joinUrl'];
        });
        _startTimer();

        // Auto-launch Zoom for patient
        _launchZoomMeeting();

        // Check initial status
        _checkCallStatus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect: $e')));
      }
    }
  }

  Future<void> _checkCallStatus() async {
    try {
      final status =
          await _apiClient.patient.getCallStatus(widget.bookingId);
      if (mounted) {
        if (status['doctor_on_call'] == true) {
          setState(() => _isDoctorConnected = true);
        }
        if (status['consultation_ended'] == true) {
          _navigateToEndedScreen(null);
        }
      }
    } catch (_) {}
  }

  Future<void> _launchZoomMeeting() async {
    if (_zoomJoinUrl != null && !_zoomLaunched) {
      _zoomLaunched = true;
      try {
        final uri = Uri.parse(_zoomJoinUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Please install Zoom app to join the meeting')),
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

  void _leaveCall() {
    // Patient can only leave (go back), not end the consultation
    Navigator.pop(context);
  }

  void _navigateToEndedScreen(dynamic duration) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => UserConsultationEndedScreen(
          bookingId: widget.bookingId,
          doctorName: widget.doctorName,
          duration: duration is int ? duration : _secondsElapsed,
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
            // Background
            Container(
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
                          Text('Connecting to doctor...',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 14)),
                          SizedBox(height: 8),
                          Text('Launching Zoom meeting...',
                              style: TextStyle(
                                  color: Colors.white38, fontSize: 12)),
                        ],
                      ),
                    )
                  : _hasError
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 60),
                              const SizedBox(height: 16),
                              const Text('Connection failed',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16)),
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
                          child: _isDoctorConnected
                              ? _buildConnectedView()
                              : _buildWaitingView(),
                        ),
            ),

            // Top bar
            if (!_isConnecting) _buildTopBar(),

            // Timer when connected
            if (!_isConnecting && _isDoctorConnected)
              Positioned(
                top: 56,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: Colors.black45,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_formatDuration(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                ),
              ),

            // PIP self view
            if (!_isConnecting) _buildPipView(),

            // Bottom Controls
            if (!_isConnecting) _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blueGrey.shade800,
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: widget.doctorImage != null && widget.doctorImage!.startsWith('http')
              ? ClipOval(
                  child: Image.network(
                    widget.doctorImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, color: Colors.white38, size: 80),
                  ),
                )
              : const Icon(Icons.person, color: Colors.white38, size: 80),
        ),
        const SizedBox(height: 16),
        Text(widget.doctorName,
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
                  color: Colors.green, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            const Text('In call',
                style: TextStyle(color: Colors.green, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        Text(_formatDuration(),
            style: const TextStyle(
                color: Colors.white54,
                fontSize: 24,
                fontWeight: FontWeight.w300)),
        const SizedBox(height: 16),
        if (_zoomJoinUrl != null)
          TextButton.icon(
            onPressed: () {
              _zoomLaunched = false;
              _launchZoomMeeting();
            },
            icon: const Icon(Icons.videocam, color: Colors.blue, size: 16),
            label: const Text('Rejoin Zoom',
                style: TextStyle(color: Colors.blue, fontSize: 12)),
          ),
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
          ),
          child: widget.doctorImage != null && widget.doctorImage!.startsWith('http')
              ? ClipOval(
                  child: Image.network(
                    widget.doctorImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.person, size: 80, color: Colors.white38),
                  ),
                )
              : const Icon(Icons.person, size: 80, color: Colors.white38),
        ),
        const SizedBox(height: 16),
        Text(widget.doctorName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Waiting for doctor...',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 16),
        if (_zoomJoinUrl != null)
          TextButton.icon(
            onPressed: () {
              _zoomLaunched = false;
              _launchZoomMeeting();
            },
            icon: const Icon(Icons.videocam, color: Colors.blue, size: 16),
            label: const Text('Rejoin Zoom',
                style: TextStyle(color: Colors.blue, fontSize: 12)),
          ),
      ],
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10)),
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
          // LIVE badge when doctor is connected
          if (_isDoctorConnected)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
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
                        spreadRadius: 2)
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color:
                            Colors.green.withOpacity(_pulseAnimation.value),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.greenAccent.withOpacity(0.7),
                              blurRadius: 4,
                              spreadRadius: 1)
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
          if (!_isDoctorConnected)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10)),
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
        child: Center(
          child: _isCameraOff
              ? const Icon(Icons.videocam_off,
                  color: Colors.white38, size: 30)
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Colors.blue, size: 28),
                    SizedBox(height: 4),
                    Text('You',
                        style:
                            TextStyle(color: Colors.white54, fontSize: 10)),
                    Text('(Zoom)',
                        style:
                            TextStyle(color: Colors.white30, fontSize: 8)),
                  ],
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
              Colors.transparent
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
              icon:
                  _isCameraOff ? Icons.videocam_off : Icons.videocam,
              label: _isCameraOff ? 'Cam On' : 'Cam Off',
              isActive: !_isCameraOff,
              onTap: () =>
                  setState(() => _isCameraOff = !_isCameraOff),
            ),
            _buildControl(
              icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_off,
              label: 'Speaker',
              isActive: _isSpeakerOn,
              onTap: () =>
                  setState(() => _isSpeakerOn = !_isSpeakerOn),
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
            // Leave button (patient can only leave, not end)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _leaveCall,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade700,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2)
                      ],
                    ),
                    child: const Icon(Icons.exit_to_app,
                        color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(height: 4),
                const Text('Leave',
                    style:
                        TextStyle(color: Colors.white60, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControl(
      {required IconData icon,
      required String label,
      required bool isActive,
      required VoidCallback onTap}) {
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
                  width: 1),
            ),
            child: Icon(icon,
                color:
                    isActive ? Colors.white : Colors.red.shade300,
                size: 22),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
                color: Colors.white54, fontSize: 9)),
      ],
    );
  }
}
