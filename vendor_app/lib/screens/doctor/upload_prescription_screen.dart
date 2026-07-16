import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:ui_components/ui_components.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vendor_app/screens/home/home_screen.dart';
import 'package:intl/intl.dart';
import 'package:vendor_app/screens/doctor/consultation_success_screen.dart';
import 'prescription_cache.dart';

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
  bool _showUploadForm = false;

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
        PrescriptionCache.bytes[widget.appointmentId] = bytes;
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
          MaterialPageRoute(
            builder: (context) => ConsultationSuccessScreen(
              appointment: widget.appointment,
            ),
          ),
          (route) => route.isFirst,
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

    DateTime parseLocalTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) return DateTime.now();
      try {
        String t = timeStr;
        if (t.endsWith('Z')) {
          t = t.substring(0, t.length - 1);
        }
        return DateTime.parse(t);
      } catch (e) {
        return DateTime.now();
      }
    }

    final String scheduledTimeStr = widget.appointment?['scheduledTime'] ?? widget.appointment?['createdAt'] ?? '';
    final dt = parseLocalTime(scheduledTimeStr);
    final dateStr = DateFormat('dd MMM yyyy').format(dt);
    final timeStr = DateFormat('hh:mm a').format(dt);

    String? getPrescriptionUrl(Map<String, dynamic> data) {
      if (data['prescriptionFileUrl'] != null && data['prescriptionFileUrl'].toString().isNotEmpty) return data['prescriptionFileUrl'].toString();
      
      if (data['prescription'] != null) {
        if (data['prescription'] is Map) {
          final Map p = data['prescription'];
          if (p['prescriptionFile'] != null && p['prescriptionFile'].toString().isNotEmpty) return p['prescriptionFile'].toString();
          if (p['fileUrl'] != null && p['fileUrl'].toString().isNotEmpty) return p['fileUrl'].toString();
        } else if (data['prescription'].toString().isNotEmpty) {
          return data['prescription'].toString();
        }
      }

      if (data['prescriptionUrl'] != null && data['prescriptionUrl'].toString().isNotEmpty) return data['prescriptionUrl'].toString();
      if (data['prescription_url'] != null && data['prescription_url'].toString().isNotEmpty) return data['prescription_url'].toString();
      if (data['report'] != null && data['report'].toString().isNotEmpty) return data['report'].toString();
      if (data['prescriptionImages'] != null && data['prescriptionImages'] is List && (data['prescriptionImages'] as List).isNotEmpty) return data['prescriptionImages'][0].toString();
      if (data['prescriptionFile'] != null && data['prescriptionFile'].toString().isNotEmpty) return data['prescriptionFile'].toString();
      
      String? foundUrl;
      void searchMap(Map m) {
        m.forEach((key, value) {
          if (foundUrl != null) return;
          if (value is String) {
            final valLower = value.toLowerCase();
            if (!valLower.contains('profile') && !valLower.contains('zoom') && !valLower.contains('avatar')) {
              if (valLower.startsWith('http') || valLower.contains('uploads/') || valLower.contains('/api/')) {
                if (valLower.contains('prescription') || valLower.contains('report') || valLower.endsWith('.pdf') || valLower.endsWith('.jpg') || valLower.endsWith('.png') || valLower.endsWith('.jpeg')) {
                  foundUrl = value;
                }
              } else if (valLower.endsWith('.pdf') || valLower.endsWith('.jpg') || valLower.endsWith('.png') || valLower.endsWith('.jpeg')) {
                foundUrl = value;
              }
            }
          } else if (value is Map) {
            searchMap(value);
          } else if (value is List) {
            for (var item in value) {
              if (item is Map) searchMap(item);
              else if (item is String) {
                final itemLower = item.toLowerCase();
                if (!itemLower.contains('profile') && !itemLower.contains('zoom') && !itemLower.contains('avatar')) {
                  if (itemLower.startsWith('http') || itemLower.contains('uploads/') || itemLower.contains('/api/')) {
                    if (itemLower.contains('prescription') || itemLower.contains('report') || itemLower.endsWith('.pdf') || itemLower.endsWith('.png') || itemLower.endsWith('.jpg') || itemLower.endsWith('.jpeg')) {
                      foundUrl = item;
                    }
                  } else if (itemLower.endsWith('.pdf') || itemLower.endsWith('.jpg') || itemLower.endsWith('.png') || itemLower.endsWith('.jpeg')) {
                    foundUrl = item;
                  }
                }
              }
            }
          }
        });
      }
      searchMap(data);
      
      if (foundUrl != null && !foundUrl!.startsWith('http')) {
        if (!foundUrl!.startsWith('/')) foundUrl = '/$foundUrl';
        foundUrl = 'http://192.168.1.6:5000$foundUrl'; // Fallback base URL based on existing codebase
      }
      
      return foundUrl;
    }

    final String? uploadedUrl = widget.appointment != null ? getPrescriptionUrl(widget.appointment!) : null;
    final bool hasUploadedPrescription = uploadedUrl != null && uploadedUrl.isNotEmpty;
    final bool displayUploaded = hasUploadedPrescription && !_showUploadForm;


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
              if (displayUploaded)
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
                      const Text('Uploaded Prescription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 16),
                      Stack(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 250,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: (uploadedUrl!.toLowerCase().endsWith('.pdf'))
                                  ? const Center(child: Icon(Icons.picture_as_pdf, size: 64, color: Colors.red))
                                  : Image.network(uploadedUrl, fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.grey))),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _showUploadForm = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.close, size: 20, color: Colors.red),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              else ...[
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
              ],

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

