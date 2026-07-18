import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';
import 'upload_document_screen.dart';
import 'document_viewer_screen.dart';

/// Documents list screen - View all uploaded documents
class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen>
    with SingleTickerProviderStateMixin {
  final _apiClient = OnMintApiClient();
  late TabController _tabController;

  final Map<String, List<dynamic>> _documents = {
    'all': [],
    'prescription': [],
    'medical_report': [],
    'lab_report': [],
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDocuments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDocuments() async {
    setState(() => _isLoading = true);
    try {
      // Load all documents
      final allDocs = await _apiClient.document.getDocuments();
      final prescriptions = await _apiClient.document.getPrescriptions();
      final medicalReports = await _apiClient.document.getMedicalReports();
      final labReports = await _apiClient.document.getLabReports();

      setState(() {
        _documents['all'] = allDocs['items'] ?? [];
        _documents['prescription'] = prescriptions['items'] ?? [];
        _documents['medical_report'] = medicalReports['items'] ?? [];
        _documents['lab_report'] = labReports['items'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading documents: $e')),
        );
      }
    }
  }

  Future<void> _deleteDocument(String documentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Document'),
        content: const Text('Are you sure you want to delete this document?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiClient.document.deleteDocument(documentId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document deleted')),
        );
        _loadDocuments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting document: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Documents'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Prescriptions'),
            Tab(text: 'Medical Reports'),
            Tab(text: 'Lab Reports'),
          ],
        ),
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDocumentList('all'),
                _buildDocumentList('prescription'),
                _buildDocumentList('medical_report'),
                _buildDocumentList('lab_report'),
              ],
            )),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UploadDocumentScreen(),
            ),
          );
          if (result == true) {
            _loadDocuments();
          }
        },
        icon: const Icon(Icons.upload_file),
        label: const Text('Upload'),
      ),
    );
  }

  Widget _buildDocumentList(String type) {
    final documents = _documents[type] ?? [];

    if (documents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No documents found',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDocuments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          return _buildDocumentCard(doc);
        },
      ),
    );
  }

  Widget _buildDocumentCard(Map<String, dynamic> doc) {
    final fileName = doc['fileName'] ?? 'Unknown';
    final documentType = doc['documentType'] ?? 'document';
    final uploadedAt = DateTime.parse(doc['createdAt']);
    final fileSize = doc['fileSize'] ?? 0;

    IconData icon;
    Color iconColor;
    switch (documentType) {
      case 'prescription':
        icon = Icons.medication;
        iconColor = Colors.blue;
        break;
      case 'medical_report':
        icon = Icons.description;
        iconColor = Colors.green;
        break;
      case 'lab_report':
        icon = Icons.science;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          fileName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _formatDocumentType(documentType),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              '${_formatFileSize(fileSize)} • ${_formatDate(uploadedAt)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'view') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DocumentViewerScreen(
                    documentId: doc['_id'],
                    fileName: fileName,
                  ),
                ),
              );
            } else if (value == 'delete') {
              _deleteDocument(doc['_id']);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility, size: 20),
                  SizedBox(width: 12),
                  Text('View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentViewerScreen(
                documentId: doc['_id'],
                fileName: fileName,
              ),
            ),
          );
        },
      ),
    );
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
    return '${date.day}/${date.month}/${date.year}';
  }
}
