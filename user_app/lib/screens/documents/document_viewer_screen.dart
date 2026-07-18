import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

/// Document viewer screen - View and download documents
class DocumentViewerScreen extends StatefulWidget {
  final String documentId;
  final String fileName;

  const DocumentViewerScreen({
    super.key,
    required this.documentId,
    required this.fileName,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final _apiClient = OnMintApiClient();
  Map<String, dynamic>? _document;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    setState(() => _isLoading = true);
    try {
      final doc =
          await _apiClient.document.getDocumentDetails(widget.documentId);
      setState(() {
        _document = doc;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading document: $e')),
        );
      }
    }
  }

  Future<void> _downloadAndOpenDocument() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/${widget.fileName}';

      // Download file
      await _apiClient.document.downloadDocument(
        widget.documentId,
        filePath,
      );

      setState(() {
        _isDownloading = false;
        _downloadProgress = 1.0;
      });

      // Open file
      final result = await OpenFile.open(filePath);

      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error opening file: ${result.message}')),
          );
        }
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading document: $e')),
        );
      }
    }
  }

  Future<void> _shareDocument() async {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareDocument,
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _document == null
              ? const Center(child: Text('Document not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Document Preview Card
                      Card(
                        elevation: 4,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                _getFileIcon(_document!['fileExtension'] ?? ''),
                                size: 80,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.fileName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatFileSize(_document!['fileSize'] ?? 0),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Document Details
                      const Text(
                        'Document Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildDetailRow('Type',
                          _formatDocumentType(_document!['documentType'])),
                      _buildDetailRow('Uploaded',
                          _formatDate(DateTime.parse(_document!['createdAt']))),
                      if (_document!['description'] != null)
                        _buildDetailRow(
                            'Description', _document!['description']),

                      const SizedBox(height: 32),

                      // Action Buttons
                      if (_isDownloading)
                        Column(
                          children: [
                            LinearProgressIndicator(value: _downloadProgress),
                            const SizedBox(height: 8),
                            const Text('Downloading...'),
                          ],
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _downloadAndOpenDocument,
                                icon: const Icon(Icons.download),
                                label: const Text('Download & Open'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  try {
                                    final url = await _apiClient.document
                                        .getDocumentUrl(widget.documentId);
                                    // TODO: Open URL in browser or webview
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content:
                                                Text('Opening in browser...')),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                    }
                                  }
                                },
                                icon: const Icon(Icons.open_in_browser),
                                label: const Text('View in Browser'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                )),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
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

  String _formatDocumentType(String type) {
    switch (type) {
      case 'prescription':
        return 'Prescription';
      case 'medical_report':
        return 'Medical Report';
      case 'lab_report':
        return 'Lab Report';
      default:
        return 'Document';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
