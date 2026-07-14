import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vendor_app/screens/home/home_screen.dart';

class UploadPrescriptionScreen extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic>? appointment;

  const UploadPrescriptionScreen({
    super.key,
    required this.appointmentId,
    this.appointment,
  });

  @override
  State<UploadPrescriptionScreen> createState() =>
      _UploadPrescriptionScreenState();
}

class _UploadPrescriptionScreenState extends State<UploadPrescriptionScreen> {
  final _apiClient = OnMintApiClient();
  final _noteController = TextEditingController();

  XFile? _selectedFile;
  String? _fileName;
  String? _fileSize;
  bool _isUploading = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
      );

      if (file == null) {
        return;
      }

      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File must be 5 MB or smaller.')),
          );
        }
        return;
      }

      setState(() {
        _selectedFile = file;
        _fileName = file.name;
        _fileSize = (fileSize / 1024).toStringAsFixed(2);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick file: $e')),
        );
      }
    }
  }

  Future<void> _uploadPrescription() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a prescription file to upload.')),
      );
      return;
    }

    setState(() => _isUploading = true);
    try {
      await _apiClient.initialize();
      final notes = _noteController.text.trim();

      if (kIsWeb) {
        final bytes = await _selectedFile!.readAsBytes();
        await _apiClient.doctor.uploadPrescriptionFileBytes(
          widget.appointmentId,
          bytes,
          _selectedFile!.name,
          notes: notes.isNotEmpty ? notes : null,
        );
      } else {
        await _apiClient.doctor.uploadPrescriptionFile(
          widget.appointmentId,
          _selectedFile!.path,
          notes: notes.isNotEmpty ? notes : null,
        );
      }

      if (mounted) {
        ToastUtils.showSuccess('Prescription uploaded successfully!');
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.showError('Failed to upload: $e');
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patient = widget.appointment?['patient'] ?? {};
    final patientName = patient['fullName'] ?? 'Patient';
    final gender = patient['gender'] ?? 'Male';
    final age = (widget.appointment?['patientAge'] ?? patient['age'] ?? '28').toString();
    final price = widget.appointment?['price'] ?? widget.appointment?['totalAmount'] ?? 300;

    String dateStr = '13 May 2025'; // Default mock to match design if not available
    String timeStr = '06:45 PM';
    if (widget.appointment?['endTime'] != null) {
      final d = DateTime.tryParse(widget.appointment!['endTime']);
      if (d != null) {
        dateStr = '${d.day} ${_getMonth(d.month)} ${d.year}';
        final hour = d.hour > 12 ? d.hour - 12 : d.hour;
        final period = d.hour >= 12 ? 'PM' : 'AM';
        timeStr = '${hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} $period';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Upload Prescription', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Consultation Completed Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Consultation Completed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Please upload your prescription to help us serve you better.', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Patient Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 28,
                          backgroundImage: AssetImage('assets/images/logos/doctor_logo.png'), // Mock photo
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.male, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('$gender  •  $age Years', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                                  const SizedBox(width: 4),
                                  Text('3.1 km away', style: TextStyle(color: Colors.grey[700], fontSize: 13)), // Mock distance
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.access_time_outlined, size: 16, color: Colors.black54),
                                const SizedBox(width: 8),
                                Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹$price', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2E7D32))),
                            const SizedBox(height: 4),
                            Text('Consultation Fee', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Upload Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Upload Prescription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Upload a clear prescription (JPG, PNG or PDF)', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    const SizedBox(height: 16),
                    
                    GestureDetector(
                      onTap: _isUploading ? null : _pickFile,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          // Custom dashed border logic using simple solid border for standard flutter if dotted_border not available
                          border: Border.all(color: Colors.grey[400]!, style: BorderStyle.solid),
                        ),
                        child: _fileName != null
                            ? Column(
                                children: [
                                  const Icon(Icons.check_circle, size: 40, color: Colors.green),
                                  const SizedBox(height: 12),
                                  Text(_fileName!, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                  const SizedBox(height: 4),
                                  Text('($_fileSize KB)', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ],
                              )
                            : Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.file_upload_outlined, size: 32, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text('Tap to upload', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Text('or choose a file from your device', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                  const SizedBox(height: 8),
                                  Text('JPG, PNG or PDF (Max 5 MB)', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Note Section
              const Text('Add a Note (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: 'Add any additional information...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Submit Button
              ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadPrescription,
                icon: _isUploading
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.upload, color: Colors.white, size: 20),
                label: const Text('Upload Prescription Photo', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              
              // Secure info
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text('Your file is secure and private.', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                ],
              ),
              const SizedBox(height: 24),

              // Why upload prescription block
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFF2E7D32), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Why upload prescription?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(
                            'Helps doctors understand your treatment better and provide accurate follow-up.',
                            style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

