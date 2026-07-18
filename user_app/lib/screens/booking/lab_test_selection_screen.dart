import 'package:flutter/material.dart';

class LabTestModel {
  final String id;
  final String name;
  final String description;
  final double price;

  LabTestModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
  });
}

class LabTestSelectionScreen extends StatefulWidget {
  final List<LabTestModel> initialSelectedTests;

  const LabTestSelectionScreen({
    Key? key,
    this.initialSelectedTests = const [],
  }) : super(key: key);

  @override
  State<LabTestSelectionScreen> createState() => _LabTestSelectionScreenState();
}

class _LabTestSelectionScreenState extends State<LabTestSelectionScreen> {
  final List<LabTestModel> _allTests = [
    LabTestModel(
        id: '1',
        name: 'HbA1c',
        description: 'Known as Glycosylated Haemoglobin Blood',
        price: 420),
    LabTestModel(
        id: '2',
        name: 'Vitamin B 12',
        description: 'Known as Vitamin B12 Conventional Blood',
        price: 960),
    LabTestModel(
        id: '3',
        name: 'Beta HCG',
        description: 'Known as Beta Hcg Automated Blood',
        price: 815),
    LabTestModel(
        id: '4',
        name: 'Fasting Blood Sugar',
        description: 'Known as Glucose Fasting Blood',
        price: 80),
    LabTestModel(
        id: '5',
        name: 'Vitamin D Profile',
        description: 'Known as Vitamin D Profile Blood',
        price: 1910),
    LabTestModel(
        id: '6',
        name: 'Thyroid Profile',
        description: 'Known as Thyroid Profile Total Blood',
        price: 420),
    LabTestModel(
        id: '7',
        name: 'Complete Blood Count',
        description: 'Known as Complete Blood Count Automated Blood',
        price: 330),
    LabTestModel(
        id: '8',
        name: 'Lipid Profile',
        description: 'Known as Lipid Profile Blood',
        price: 620),
    LabTestModel(
        id: '9',
        name: 'Liver Function Test',
        description: 'Known as Liver Function Tests Blood',
        price: 790),
    LabTestModel(
        id: '10',
        name: 'Dengue NS 1',
        description: 'Known as Dengue Ns1 Antigen Pcr Blood',
        price: 630),
    LabTestModel(
        id: '11',
        name: 'Malarial Antigen',
        description: 'Known as Malarial Antigen Pcr Blood',
        price: 680),
  ];

  late List<LabTestModel> _selectedTests;

  @override
  void initState() {
    super.initState();
    _selectedTests = List.from(widget.initialSelectedTests);
  }

  void _toggleSelection(LabTestModel test) {
    setState(() {
      if (_selectedTests.any((t) => t.id == test.id)) {
        _selectedTests.removeWhere((t) => t.id == test.id);
      } else {
        _selectedTests.add(test);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double totalPrice = _selectedTests.fold(0, (sum, item) => sum + item.price);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Select Tests',
            style: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(top: false, bottom: true, child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _allTests.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey[200], height: 1),
              itemBuilder: (context, index) {
                final test = _allTests[index];
                final isSelected = _selectedTests.any((t) => t.id == test.id);

                return InkWell(
                  onTap: () => _toggleSelection(test),
                  child: Container(
                    color: isSelected ? const Color(0xFFF4F0FF) : Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                test.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                test.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              _toggleSelection(test);
                            },
                            activeColor: Colors.purple[700],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Persistent Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, -4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_selectedTests.length} Test${_selectedTests.length == 1 ? '' : 's'} Selected',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 150,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, _selectedTests);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      )),
    );
  }
}
