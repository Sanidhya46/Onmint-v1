import 'package:flutter/material.dart';

class NursingCareModel {
  final String id;
  final String name;
  final String description;
  final String iconPath;

  NursingCareModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
  });
}

class NursingCareSelectionScreen extends StatefulWidget {
  final List<NursingCareModel> initialSelectedCares;

  const NursingCareSelectionScreen({
    Key? key,
    required this.initialSelectedCares,
  }) : super(key: key);

  @override
  State<NursingCareSelectionScreen> createState() =>
      _NursingCareSelectionScreenState();
}

class _NursingCareSelectionScreenState
    extends State<NursingCareSelectionScreen> {
  final List<NursingCareModel> _allCares = [
    NursingCareModel(
      id: '1',
      name: 'Injection Assistance',
      description: 'Get injection at home',
      iconPath:
          'assets/images/nurse/injection.png', // Fallback to icons if images don't exist
    ),
    NursingCareModel(
      id: '2',
      name: 'IV Drip Administration',
      description: 'IV therapy and saline at home',
      iconPath: 'assets/images/nurse/iv_drip.png',
    ),
    NursingCareModel(
      id: '3',
      name: 'Wound Dressing',
      description: 'Wound care and dressing',
      iconPath: 'assets/images/nurse/wound.png',
    ),
    NursingCareModel(
      id: '4',
      name: 'Catheter Care',
      description: 'Catheter change and care',
      iconPath: 'assets/images/nurse/catheter.png',
    ),
    NursingCareModel(
      id: '5',
      name: 'Elderly Care',
      description: 'Elderly and patient care at home',
      iconPath: 'assets/images/nurse/elderly.png',
    ),
    NursingCareModel(
      id: '6',
      name: 'Post-Operative Care',
      description: 'Care for post-surgery patients',
      iconPath: 'assets/images/nurse/post_op.png',
    ),
    NursingCareModel(
      id: '7',
      name: 'Vital Signs Monitoring',
      description: 'BP, sugar, temperature & more',
      iconPath: 'assets/images/nurse/vitals.png',
    ),
    NursingCareModel(
      id: '8',
      name: 'Home Nursing Care',
      description: 'Hourly or full-day nursing care',
      iconPath: 'assets/images/nurse/home_nursing.png',
    ),
    NursingCareModel(
      id: '9',
      name: 'Baby & Mother Care',
      description: 'Newborn and mother care',
      iconPath: 'assets/images/nurse/baby_care.png',
    ),
    NursingCareModel(
      id: '10',
      name: 'Medicine Administration',
      description: 'Medicine on time at home',
      iconPath: 'assets/images/nurse/medicine.png',
    ),
  ];

  late List<NursingCareModel> _selectedCares;

  @override
  void initState() {
    super.initState();
    _selectedCares = List.from(widget.initialSelectedCares);
  }

  void _toggleSelection(NursingCareModel care) {
    setState(() {
      if (_selectedCares.any((c) => c.id == care.id)) {
        _selectedCares.removeWhere((c) => c.id == care.id);
      } else {
        _selectedCares.add(care);
      }
    });
  }

  IconData _getIconForCare(String id) {
    switch (id) {
      case '1':
        return Icons.vaccines_outlined;
      case '2':
        return Icons.bloodtype_outlined;
      case '3':
        return Icons.healing_outlined;
      case '4':
        return Icons.medical_services_outlined;
      case '5':
        return Icons.elderly_outlined;
      case '6':
        return Icons.favorite_border_outlined;
      case '7':
        return Icons.monitor_heart_outlined;
      case '8':
        return Icons.person_add_alt_outlined;
      case '9':
        return Icons.child_care_outlined;
      case '10':
        return Icons.medication_outlined;
      default:
        return Icons.medical_services_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context, _selectedCares),
        ),
        title: const Text(
          'Select Nurse Service',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Choose the type of nursing service you need',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0, bottom: 100.0),
              itemCount: _allCares.length,
              itemBuilder: (context, index) {
                final care = _allCares[index];
                final isSelected = _selectedCares.any((c) => c.id == care.id);

                return GestureDetector(
                  onTap: () => _toggleSelection(care),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[50] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? Colors.blue[300]! : Colors.grey[200]!,
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getIconForCare(care.id),
                            color: Colors.blue[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                care.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                care.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blue[600]
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.blue[600]!
                                  : Colors.grey[400]!,
                              width: 1.5,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      )),
      bottomNavigationBar: _selectedCares.isEmpty
          ? const SizedBox.shrink()
          : Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedCares);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Proceed',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward,
                            color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
