import 'package:flutter/material.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

/// Video consultation screen using Jitsi Meet
/// Supports doctor-patient video calls
class VideoCallScreen extends StatefulWidget {
  final String meetingId;
  final String userName;
  final String? userEmail;
  final bool isAudioMuted;
  final bool isVideoMuted;

  const VideoCallScreen({
    super.key,
    required this.meetingId,
    required this.userName,
    this.userEmail,
    this.isAudioMuted = false,
    this.isVideoMuted = false,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final _jitsiMeet = JitsiMeet();
  bool _isJoining = true;

  @override
  void initState() {
    super.initState();
    _joinMeeting();
  }

  Future<void> _joinMeeting() async {
    try {
      var options = JitsiMeetConferenceOptions(
        room: widget.meetingId,
        serverURL:
            'https://meet.jit.si', // Use your own Jitsi server if available
        configOverrides: {
          "startWithAudioMuted": widget.isAudioMuted,
          "startWithVideoMuted": widget.isVideoMuted,
          "subject": "OnMint Healthcare Consultation",
        },
        featureFlags: {
          "unsaferoomwarning.enabled": false,
          "prejoinpage.enabled": false,
          "chat.enabled": true,
          "recording.enabled": false,
          "live-streaming.enabled": false,
          "meeting-name.enabled": true,
          "call-integration.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: widget.userName,
          email: widget.userEmail,
        ),
      );

      // Add event listeners
      var listener = JitsiMeetEventListener(
        conferenceJoined: (url) {
          debugPrint("Conference joined: $url");
          setState(() => _isJoining = false);
        },
        conferenceTerminated: (url, error) {
          debugPrint("Conference terminated: $url, error: $error");
          Navigator.of(context).pop();
        },
        conferenceWillJoin: (url) {
          debugPrint("Conference will join: $url");
        },
        participantJoined: (email, name, role, participantId) {
          debugPrint("Participant joined: $name");
        },
        participantLeft: (participantId) {
          debugPrint("Participant left: $participantId");
        },
        audioMutedChanged: (muted) {
          debugPrint("Audio muted: $muted");
        },
        videoMutedChanged: (muted) {
          debugPrint("Video muted: $muted");
        },
        endpointTextMessageReceived: (senderId, message) {
          debugPrint("Message received from $senderId: $message");
        },
        screenShareToggled: (participantId, sharing) {
          debugPrint("Screen share toggled: $sharing");
        },
        chatMessageReceived: (senderId, message, isPrivate, timestamp) {
          debugPrint("Chat message: $message");
        },
        chatToggled: (isOpen) {
          debugPrint("Chat toggled: $isOpen");
        },
        participantsInfoRetrieved: (participantsInfo) {
          debugPrint("Participants info: $participantsInfo");
        },
        readyToClose: () {
          debugPrint("Ready to close");
          Navigator.of(context).pop();
        },
      );

      await _jitsiMeet.join(options, listener);
    } catch (e) {
      debugPrint("Error joining meeting: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join meeting: $e')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(top: false, bottom: true, child: _isJoining
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Joining consultation...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Meeting ID: ${widget.meetingId}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink()), // Jitsi will take over the screen
    );
  }

  @override
  void dispose() {
    _jitsiMeet.hangUp();
    super.dispose();
  }
}
