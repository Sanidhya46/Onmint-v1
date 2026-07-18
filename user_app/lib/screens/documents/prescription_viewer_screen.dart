import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';

/// Prescription viewer screen - View prescription details
class PrescriptionViewerScreen extends StatefulWidget {
  final String prescriptionId;

  const PrescriptionViewerScreen({
    super.key,
    required this.prescriptionId,
  });

  @override
  State<PrescriptionViewerScreen> createState() =>
      _PrescriptionViewerScreenState();
}

class _PrescriptionViewerScreenState extends State<PrescriptionViewerScreen> {
  Map<String, dynamic>? _prescription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPrescription();
  }

  Future<void> _loadPrescription() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Get booking details which includes prescription
      final patientService = PatientService();
      final booking =
          await patientService.getBookingById(widget.prescriptionId);

      if (mounted) {
        setState(() {
          _prescription = booking['prescription'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prescription: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Download prescription as PDF
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Download functionality coming soon')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(top: false, bottom: true, child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _prescription == null
              ? const Center(child: Text('Prescription not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.medication,
                                      color: Colors.blue, size: 32),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Prescription',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'Date: ${_formatDate(DateTime.parse(_prescription!['createdAt']))}',
                                          style: TextStyle(
                                              color: Colors.grey[700]),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Doctor Information
                      _buildSection('Doctor Information', [
                        _buildInfoRow('Name',
                            _prescription!['doctor']?['fullName'] ?? 'N/A'),
                        _buildInfoRow(
                            'Specialization',
                            _prescription!['doctor']?['specialization'] ??
                                'N/A'),
                        _buildInfoRow(
                            'Registration',
                            _prescription!['doctor']?['registrationNumber'] ??
                                'N/A'),
                      ]),

                      const SizedBox(height: 20),

                      // Diagnosis
                      _buildSection('Diagnosis', [
                        Text(_prescription!['diagnosis'] ?? 'N/A'),
                      ]),

                      const SizedBox(height: 20),

                      // Symptoms
                      if (_prescription!['symptoms'] != null &&
                          (_prescription!['symptoms'] as List).isNotEmpty)
                        _buildSection('Symptoms', [
                          ...(_prescription!['symptoms'] as List)
                              .map((symptom) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.circle,
                                            size: 8, color: Colors.grey),
                                        const SizedBox(width: 8),
                                        Text(symptom),
                                      ],
                                    ),
                                  )),
                        ]),

                      const SizedBox(height: 20),

                      // Medicines
                      _buildSection('Medicines', [
                        if (_prescription!['medicines'] != null)
                          ...(_prescription!['medicines'] as List)
                              .map((medicine) => Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            medicine['name'] ??
                                                'Unknown Medicine',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Dosage',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      medicine['dosage'] ??
                                                          'N/A',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Frequency',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                    Text(
                                                      medicine['frequency'] ??
                                                          'N/A',
                                                      style: const TextStyle(
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Duration: ${medicine['duration'] ?? 'N/A'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                      ]),

                      const SizedBox(height: 20),

                      // Tests
                      if (_prescription!['tests'] != null &&
                          (_prescription!['tests'] as List).isNotEmpty)
                        _buildSection('Recommended Tests', [
                          ...(_prescription!['tests'] as List)
                              .map((test) => Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: const Icon(Icons.science,
                                          color: Colors.purple),
                                      title: Text(test),
                                    ),
                                  )),
                        ]),

                      const SizedBox(height: 20),

                      // Advice
                      if (_prescription!['advice'] != null)
                        _buildSection('Doctor\'s Advice', [
                          Text(_prescription!['advice']),
                        ]),

                      const SizedBox(height: 32),

                      // Footer
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(
                              'This is a digital prescription. Please consult your doctor before taking any medication.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
