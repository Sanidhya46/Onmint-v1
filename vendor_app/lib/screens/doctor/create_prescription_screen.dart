import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart';

/// Create prescription screen for doctors
class CreatePrescriptionScreen extends StatefulWidget {
  final String bookingId;

  const CreatePrescriptionScreen({
    super.key,
    required this.bookingId,
  });

  @override
  State<CreatePrescriptionScreen> createState() => _CreatePrescriptionScreenState();
}

class _CreatePrescriptionScreenState extends State<CreatePrescriptionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = OnMintApiClient();
  
  final _diagnosisController = TextEditingController();
  final _adviceController = TextEditingController();
  
  final List<String> _symptoms = [];
  final List<Map<String, dynamic>> _medicines = [];
  final List<String> _tests = [];
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _diagnosisController.dispose();
    _adviceController.dispose();
    super.dispose();
  }

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_medicines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      await _apiClient.doctor.createPrescription({
        'bookingId': widget.bookingId,
        'diagnosis': _diagnosisController.text,
        'symptoms': _symptoms,
        'medicines': _medicines,
        'tests': _tests,
        'advice': _adviceController.text,
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prescription created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Return true to indicate success
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        // Check if error is about prescription already existing
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('prescription already exists') || 
            errorMessage.contains('already exists for this booking')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prescription already exists for this booking'),
              backgroundColor: Colors.orange,
            ),
          );
          // Return true to refresh the appointment screen
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _addSymptom() async {
    final controller = TextEditingController();
    final symptom = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Symptom'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Symptom',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (symptom != null && symptom.isNotEmpty) {
      setState(() => _symptoms.add(symptom));
    }
  }

  void _addMedicine() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AddMedicineDialog(),
    );
    
    if (result != null) {
      setState(() => _medicines.add(result));
    }
  }

  void _addTest() async {
    final controller = TextEditingController();
    final test = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Test'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Test Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (test != null && test.isNotEmpty) {
      setState(() => _tests.add(test));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Prescription'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Diagnosis
            TextFormField(
              controller: _diagnosisController,
              decoration: const InputDecoration(
                labelText: 'Diagnosis *',
                border: OutlineInputBorder(),
                hintText: 'Enter diagnosis',
              ),
              maxLines: 2,
              validator: (value) =>
                  value?.isEmpty ?? true ? 'Diagnosis is required' : null,
            ),
            
            const SizedBox(height: 20),
            
            // Symptoms
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Symptoms',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSymptom,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_symptoms.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No symptoms added',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._symptoms.map((symptom) => Card(
                    child: ListTile(
                      title: Text(symptom),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _symptoms.remove(symptom));
                        },
                      ),
                    ),
                  )),
            
            const SizedBox(height: 20),
            
            // Medicines
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Medicines *',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addMedicine,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_medicines.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No medicines added',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._medicines.map((medicine) => Card(
                    child: ListTile(
                      title: Text(medicine['name']),
                      subtitle: Text(
                        '${medicine['dosage']} - ${medicine['frequency']} - ${medicine['duration']}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _medicines.remove(medicine));
                        },
                      ),
                    ),
                  )),
            
            const SizedBox(height: 20),
            
            // Tests
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recommended Tests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addTest,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (_tests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'No tests added',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ..._tests.map((test) => Card(
                    child: ListTile(
                      title: Text(test),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() => _tests.remove(test));
                        },
                      ),
                    ),
                  )),
            
            const SizedBox(height: 20),
            
            // Advice
            TextFormField(
              controller: _adviceController,
              decoration: const InputDecoration(
                labelText: 'Advice',
                border: OutlineInputBorder(),
                hintText: 'Enter advice for patient',
              ),
              maxLines: 3,
            ),
            
            const SizedBox(height: 24),
            
            // Submit Button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPrescription,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Create Prescription'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddMedicineDialog extends StatefulWidget {
  const _AddMedicineDialog();

  @override
  State<_AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<_AddMedicineDialog> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  String _frequency = 'Once daily';
  final _durationController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Medicine'),
      content: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _dosageController,
              decoration: const InputDecoration(
                labelText: 'Dosage (e.g., 500mg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _frequency,
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Once daily', child: Text('Once daily')),
                DropdownMenuItem(value: 'Twice daily', child: Text('Twice daily')),
                DropdownMenuItem(value: 'Thrice daily', child: Text('Thrice daily')),
                DropdownMenuItem(value: 'Four times daily', child: Text('Four times daily')),
                DropdownMenuItem(value: 'As needed', child: Text('As needed')),
              ],
              onChanged: (value) {
                setState(() => _frequency = value!);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _durationController,
              decoration: const InputDecoration(
                labelText: 'Duration (e.g., 7 days)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty ||
                _dosageController.text.isEmpty ||
                _durationController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }
            
            Navigator.pop(context, {
              'name': _nameController.text,
              'dosage': _dosageController.text,
              'frequency': _frequency,
              'duration': _durationController.text,
            });
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
