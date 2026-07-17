import 'dart:async';
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:intl/intl.dart';
import 'package:vendor_app/screens/doctor/create_prescription_screen.dart';
import 'package:vendor_app/screens/doctor/upload_prescription_screen.dart';
import 'package:vendor_app/screens/doctor/video_call_screen.dart';
import 'package:vendor_app/screens/doctor/consultation_ended_screen.dart';

class DoctorActiveConsultationScreen extends StatefulWidget {
  final String appointmentId;

  const DoctorActiveConsultationScreen({
    super.key,
    required this.appointmentId,
  });

  @override
  State<DoctorActiveConsultationScreen> createState() => _DoctorActiveConsultationScreenState();
}

class _DoctorActiveConsultationScreenState extends State<DoctorActiveConsultationScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _appointment;
  bool _isLoading = true;
  
  Timer? _timer;
  int _secondsElapsed = 0;
  
  bool _isStartNowSelected = true;
  bool _scheduleLocked = false;
  List<DateTime> _scheduleDates = [];
  DateTime? _selectedScheduleDate;
  String _selectedScheduleTime = '10:00 AM';
  bool _isConfirming = false;

  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _apiClient.initialize();
    _loadAppointment();
    _startPolling();
    
    DateTime now = DateTime.now();
    for (int i=0; i<7; i++) {
      _scheduleDates.add(now.add(Duration(days: i)));
    }
    _selectedScheduleDate = _scheduleDates[0];
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pollAppointment();
    });
  }

  Future<void> _pollAppointment() async {
    try {
      final res = await _apiClient.get('/realtime-bookings/${widget.appointmentId}');
      if (mounted) {
        final data = res.data['data'];
        if (data == null) return;
        setState(() {
          _appointment = data;
          if (_appointment!['status'] == 'in_progress') {
            _startTimer();
          }
        });
      }
    } catch (e) {
      // Ignore polling errors
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppointment() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiClient.get('/realtime-bookings/${widget.appointmentId}');
      if (mounted) {
        setState(() {
          _appointment = res.data['data'];
          _isLoading = false;
          if (_appointment!['status'] == 'in_progress') {
            _startTimer();
          }
          if (_appointment!['scheduleDate'] != null && _appointment!['scheduleTime'] != null) {
            _scheduleLocked = true;
            _isStartNowSelected = false;
            _selectedScheduleDate = DateTime.tryParse(_appointment!['scheduleDate']) ?? _scheduleDates[0];
            _selectedScheduleTime = _appointment!['scheduleTime'];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startTimer() {
    if (_timer != null && _timer!.isActive) return;
    if (_appointment?['startTime'] != null) {
      final startTime = DateTime.tryParse(_appointment!['startTime']);
      if (startTime != null) {
        _secondsElapsed = DateTime.now().difference(startTime).inSeconds;
      }
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _secondsElapsed++);
    });
  }

  String _formatDuration(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startConsultation() async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      await _apiClient.post('/video/start-consultation', data: {'bookingId': widget.appointmentId});
      if (mounted) {
        Navigator.pop(context);
        await Navigator.push(context, MaterialPageRoute(builder: (context) => VideoCallScreen(
          bookingId: widget.appointmentId,
          patientName: '${_appointment?['patient']?['firstName'] ?? ''} ${_appointment?['patient']?['lastName'] ?? ''}',
          patientImage: _appointment?['patient']?['profilePicture'],
          appointment: _appointment,
        )));
        _loadAppointment();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start consultation: $e')));
      }
    }
  }

  Future<void> _reconsult() async {
    await Navigator.push(context, MaterialPageRoute(builder: (context) => VideoCallScreen(
      bookingId: widget.appointmentId,
      patientName: '${_appointment?['patient']?['firstName'] ?? ''} ${_appointment?['patient']?['lastName'] ?? ''}',
      patientImage: _appointment?['patient']?['profilePicture'],
      appointment: _appointment,
    )));
  }

  Future<void> _endConsultation() async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
      await _apiClient.post('/video/complete-consultation', data: {'bookingId': widget.appointmentId});
      if (mounted) {
        Navigator.pop(context);
        _timer?.cancel();
        _loadAppointment();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to end consultation: $e')));
      }
    }
  }

  Future<void> _confirmSchedule() async {
    setState(() => _isConfirming = true);
    try {
      String isoDate = DateFormat('yyyy-MM-dd').format(_selectedScheduleDate!);
      
      await _apiClient.doctor.scheduleAppointment(widget.appointmentId, isoDate, _selectedScheduleTime);
      if (mounted) {
        setState(() {
          _scheduleLocked = true;
          _isStartNowSelected = true;
          _isConfirming = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Schedule confirmed successfully! You can now start the consultation.')));
        _loadAppointment();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isConfirming = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to schedule: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(backgroundColor: Color(0xFFF4F7FF), body: Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))));
    }

    if (_appointment == null) {
      return Scaffold(appBar: AppBar(), body: const Center(child: Text('Consultation not found')));
    }

    final status = _appointment!['status'] ?? 'accepted';

    if (status == 'completed') {
      return UploadPrescriptionScreen(appointmentId: widget.appointmentId, appointment: _appointment);
    }
    
    // Fallback UI for in_progress status, keeping it minimal to allow finishing the call
    if (status == 'in_progress') {
       return Scaffold(
         appBar: AppBar(title: const Text('In Consultation')),
         body: Center(
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Text('In Consultation', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
               SizedBox(height: 16),
               ElevatedButton(onPressed: _reconsult, child: Text('Rejoin Call')),
               SizedBox(height: 16),
               ElevatedButton(onPressed: _endConsultation, style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: Text('End Consultation')),
             ],
           )
         )
       );
    }

    // This is the accepted status UI (Image 2)
    final patient = _appointment!['patient'] ?? {};
    final fullName = '${patient['firstName'] ?? ''} ${patient['lastName'] ?? ''}'.trim();
    final gender = patient['gender'] ?? 'Male';
    final age = patient['age'] ?? '35 Years';
    final problem = _appointment!['requirements']?['description'] ?? _appointment!['notes'] ?? 'Fever (Constipation, Bloating)';
    final consultationType = _appointment!['consultationType'] ?? 'Online Consultation';
    
    String formattedDate = '12 May 2025, 11:20 AM';
    if (_appointment!['createdAt'] != null) {
      final d = DateTime.tryParse(_appointment!['createdAt']);
      if (d != null) formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(d.toLocal());
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E3A8A)), onPressed: () => Navigator.pop(context)),
        title: const Column(
          children: [
            Text('Consultation Options', style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Choose how you want to consult with the patient', style: TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.security, color: Color(0xFF1E3A8A)), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(radius: 28, backgroundColor: Colors.blue.shade50, backgroundImage: patient['profilePicture'] != null ? NetworkImage(patient['profilePicture']) : null, child: patient['profilePicture'] == null ? const Icon(Icons.person, color: Colors.blue, size: 32) : null),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(fullName.isEmpty ? 'Patient' : fullName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1E3A8A))),
                            const SizedBox(height: 4),
                            Text('${age.replaceAll(" Years", " Years")} • $gender', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                            const SizedBox(height: 12),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.medical_information_outlined, size: 14, color: Colors.grey), const SizedBox(width: 6), Expanded(child: Text('Reason: $problem', style: TextStyle(fontSize: 12, color: Colors.grey[800])))]),
                            const SizedBox(height: 6),
                            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.video_camera_front_outlined, size: 14, color: Colors.blue), const SizedBox(width: 6), Expanded(child: Text('Consultation Type: $consultationType', style: TextStyle(fontSize: 12, color: Colors.grey[800])))]),
                          ],
                        )
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Requested On', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(formattedDate.split(', ')[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          Text(formattedDate.split(', ').length > 1 ? formattedDate.split(', ')[1] : '', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      )
                    ]
                  )
                ]
              )
            ),
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _scheduleLocked ? null : () => setState(() => _isStartNowSelected = true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _isStartNowSelected ? Colors.green.shade50 : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isStartNowSelected ? Colors.green : Colors.grey.shade200, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.video_call, color: Colors.green, size: 28),
                          const SizedBox(height: 8),
                          const Text('Start Consultation Now', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                          const SizedBox(height: 4),
                          const Text('Connect with the patient right away', style: TextStyle(fontSize: 11, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(4)), child: const Text('For available doctors', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold))),
                        ],
                      )
                    )
                  )
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _scheduleLocked ? null : () => setState(() => _isStartNowSelected = false),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _scheduleLocked ? Colors.grey.shade100 : (!_isStartNowSelected ? Colors.blue.shade50 : Colors.white),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: !_isStartNowSelected ? Colors.blue : Colors.grey.shade200, width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.calendar_month, color: _scheduleLocked ? Colors.grey : Colors.blue.shade700, size: 28),
                          const SizedBox(height: 8),
                          Text('Schedule Consultation', style: TextStyle(fontWeight: FontWeight.bold, color: _scheduleLocked ? Colors.grey : Colors.blue.shade700, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(_scheduleLocked ? 'Schedule confirmed.' : 'Choose a date & time slot to consult with the patient.', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _scheduleLocked ? Colors.grey.shade300 : Colors.blue.shade100, borderRadius: BorderRadius.circular(4)), child: Text('For busy doctors', style: TextStyle(fontSize: 10, color: _scheduleLocked ? Colors.grey : Colors.blue.shade700, fontWeight: FontWeight.bold))),
                        ],
                      )
                    )
                  )
                ),
              ],
            ),
            
            if (!_isStartNowSelected) ...[
              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 8.0), child: Text('OR', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Schedule Consultation', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E3A8A))),
              const SizedBox(height: 16),
              
              // Date Selector
              const Text('Select Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _scheduleDates.asMap().entries.map((entry) {
                    int idx = entry.key;
                    DateTime date = entry.value;
                    bool isSelected = _selectedScheduleDate == date;
                    
                    String topText = idx == 0 ? 'Today' : idx == 1 ? 'Tomorrow' : DateFormat('EEE').format(date);
                    String numText = DateFormat('dd').format(date);
                    String bottomText = DateFormat('MMM').format(date);
                    if (idx == 0) bottomText = DateFormat('EEE').format(date); // Just mimicking the design
                    
                    return GestureDetector(
                      onTap: _scheduleLocked ? null : () => setState(() => _selectedScheduleDate = date),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: _scheduleLocked ? Colors.grey.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                        ),
                        child: Column(
                          children: [
                            Text(topText, style: TextStyle(fontSize: 12, color: isSelected ? Colors.green : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                            const SizedBox(height: 4),
                            Text(numText, style: TextStyle(fontSize: 18, color: Colors.black87, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(bottomText, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ]
                        )
                      )
                    );
                  }).toList()
                )
              ),
              const SizedBox(height: 20),
              
              // Time Selector
              const Text('Select Time Slot', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['09:00 AM', '09:30 AM', '10:00 AM', '10:30 AM', '11:00 AM', '11:30 AM', '12:00 PM', '12:30 PM', '04:00 PM', '04:30 PM', '05:00 PM', '05:30 PM'].map((time) {
                  bool isSelected = _selectedScheduleTime == time;
                  return GestureDetector(
                    onTap: _scheduleLocked ? null : () => setState(() => _selectedScheduleTime = time),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 56) / 3, // 3 columns
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _scheduleLocked ? Colors.grey.shade100 : (isSelected ? Colors.green.shade50 : Colors.white),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? Colors.green : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Text(time, style: TextStyle(color: isSelected ? Colors.green : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          if (time == '10:00 AM')
                            Text('Recommended', style: TextStyle(fontSize: 8, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      )
                    )
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Add Custom Time
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.shade100)),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add Custom Time', style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold, fontSize: 13)),
                        const Text('Pick a time outside the above slots', style: TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.chevron_right, color: Colors.grey)
                  ],
                )
              ),
              const SizedBox(height: 24),
              
              // Green confirmation banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.green.shade200)),
                child: Row(
                  children: [
                    Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.check, color: Colors.white, size: 16)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Consultation will be scheduled on', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                          Text('${DateFormat('dd MMM yyyy').format(_selectedScheduleDate!)} • $_selectedScheduleTime', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                          const Text('Patient will be notified about the scheduled time.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      )
                    )
                  ],
                )
              ),
            ]
          ],
        )
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isConfirming ? null : (_isStartNowSelected ? _startConsultation : _confirmSchedule),
                  icon: _isConfirming 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(_isStartNowSelected ? Icons.videocam : Icons.calendar_month),
                  label: Text(
                    _isConfirming
                        ? 'Confirming...'
                        : (_isStartNowSelected
                            ? (_scheduleLocked
                                ? 'Start Consultation'
                                : 'Start Consultation Now')
                            : 'Confirm Schedule'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isStartNowSelected ? const Color(0xFF107C41) : const Color(0xFF1E3A8A), // Green for start, Blue for schedule
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Your information is secure and encrypted', style: TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              )
            ],
          )
        )
      ),
    );
  }
}
