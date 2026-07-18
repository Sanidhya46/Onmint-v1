import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:api_client/api_client.dart';

/// Upload document screen - Upload new documents
class UploadDocumentScreen extends StatefulWidget {
  const UploadDocumentScreen({super.key});

  @override
  State<UploadDocumentScreen> createState() => _UploadDocumentScreenState();
}

class _UploadDocumentScreenState extends State<UploadDocumentScreen> {
  final _apiClient = OnMintApiClient();
  final _descriptionController = TextEditingController();

  String _selectedType = 'medical_report';
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _uploadDocument() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      await _apiClient.document.uploadDocument(
        filePath: _selectedFile!.path!,
        fileName: _selectedFile!.name,
        documentType: _selectedType,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploaded successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Document'),
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Document Type Selection
            const Text(
              'Document Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'prescription',
                  child: Text('Prescription'),
                ),
                DropdownMenuItem(
                  value: 'medical_report',
                  child: Text('Medical Report'),
                ),
                DropdownMenuItem(
                  value: 'lab_report',
                  child: Text('Lab Report'),
                ),
                DropdownMenuItem(
                  value: 'other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),

            const SizedBox(height: 24),

            // File Selection
            const Text(
              'Select File',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_selectedFile == null)
              InkWell(
                onTap: _pickFile,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_upload,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Tap to select file',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'PDF, JPG, JPEG, PNG (Max 10MB)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getFileIcon(_selectedFile!.extension ?? ''),
                      color: Colors.blue,
                    ),
                  ),
                  title: Text(
                    _selectedFile!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    _formatFileSize(_selectedFile!.size),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() => _selectedFile = null);
                    },
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // Description
            const Text(
              'Description (Optional)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Add a description for this document',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),

            // Upload Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadDocument,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Document'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }

  IconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
