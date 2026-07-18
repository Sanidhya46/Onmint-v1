import 'package:flutter/material.dart';
import 'package:api_client/api_client.dart'; // Depending on existing imports
import 'doctor_summary_screen.dart';

class DoctorCategoriesScreen extends StatefulWidget {
  const DoctorCategoriesScreen({Key? key}) : super(key: key);

  @override
  State<DoctorCategoriesScreen> createState() => _DoctorCategoriesScreenState();
}

class _DoctorCategoriesScreenState extends State<DoctorCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {
      'title': 'General Physician',
      'path': 'General_Physician',
      'symptoms': [
        {'name': 'Fever', 'image': 'Fever.png'},
        {'name': 'Cold & Cough', 'image': 'cold_and_cough.png'},
        {'name': 'Headache', 'image': 'Headache.png'},
        {'name': 'Weakness', 'image': 'Weakness.png'},
      ]
    },
    {
      'title': 'Dermatology',
      'path': 'Dermatology',
      'symptoms': [
        {'name': 'Hair Loss', 'image': 'Hair_loss.png'},
        {'name': 'Dandruff', 'image': 'Dandruff.png'},
        {'name': 'Acne', 'image': 'Acne.png'},
        {'name': 'Fungal Infection', 'image': 'Fungal_infection.png'},
      ]
    },
    {
      'title': 'Gynecology',
      'path': 'Gynecology',
      'symptoms': [
        {'name': 'Irregular Periods', 'image': 'Irregular_periods.png'},
        {'name': 'PCOS', 'image': 'PCOS.png'},
        {'name': 'Pregnancy Care', 'image': 'Pregnancy_care.png'},
        {'name': 'Vaginal Discharge', 'image': 'Vaginal_discharge.png'},
      ]
    },
    {
      'title': 'Mental Wellness',
      'path': 'Mental_Wellness',
      'symptoms': [
        {'name': 'Anxiety', 'image': 'Anxiety.png'},
        {'name': 'Stress', 'image': 'Stress.png'},
        {'name': 'Depression', 'image': 'Depression.png'},
        {'name': 'Sleep Issues', 'image': 'Sleep_issues.png'},
      ]
    },
    {
      'title': 'Sexology',
      'path': 'Sexology',
      'symptoms': [
        {'name': 'Premature Ejaculation', 'image': 'Premature_ejaculation.png'},
        {'name': 'Erectile Dysfunction', 'image': 'Erectile_Dysfunction.png'},
        {'name': 'Low Libido', 'image': 'Low_libido.png'},
        {'name': 'Nightfall', 'image': 'Night_fall.png'},
      ]
    },
    {
      'title': 'Stomach & Digestion',
      'path': 'Stomach_&_Digestion',
      'symptoms': [
        {'name': 'Acidity', 'image': 'Acidity.png'},
        {'name': 'Constipation', 'image': 'Constipation.png'},
        {'name': 'Piles', 'image': 'Piles.png'},
        {'name': 'Stomach Pain', 'image': 'Stomach_pain.png'},
      ]
    },
    {
      'title': 'Pediatrics',
      'path': 'Pediatrics',
      'symptoms': [
        {'name': 'Child Fever', 'image': 'Child_Fever.png'},
        {'name': 'Cold & Cough', 'image': 'child_cold_and_cough.png'},
        {'name': 'Nutrition', 'image': 'Nutrition.png'},
        {'name': 'Vaccination', 'image': 'Vaccination.png'},
      ]
    },
    {
      'title': 'Orthopedic',
      'path': 'Orthopedic',
      'symptoms': [
        {'name': 'Back Pain', 'image': 'Back_pain.png'},
        {'name': 'Knee Pain', 'image': 'Knee_pain.png'},
        {'name': 'Neck Pain', 'image': 'Neck_pain.png'},
        {'name': 'Joint Pain', 'image': 'Joint_pain.png'},
      ]
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Consult a doctor',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF283593), // Dark blue from image
        elevation: 0,
      ),
      body: SafeArea(top: false, bottom: true, child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search symptoms.',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ..._categories
                  .map((category) => _buildCategorySection(category))
                  .toList(),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildCategorySection(Map<String, dynamic> category) {
    List<Map<String, String>> symptoms =
        List<Map<String, String>>.from(category['symptoms']);
    String path = category['path'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category['title'],
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              const itemsPerRow = 4;
              final itemWidth =
                  (constraints.maxWidth - spacing * (itemsPerRow - 1)) /
                      itemsPerRow;
              return Wrap(
                spacing: spacing,
                runSpacing: 12,
                children: symptoms
                    .map(
                      (symptom) => SizedBox(
                        width: itemWidth,
                        child: _buildSymptomItem(
                          category['title'],
                          path,
                          symptom,
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomItem(
      String categoryTitle, String path, Map<String, String> symptom) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorSummaryScreen(
              categoryTitle: categoryTitle,
              symptomName: symptom['name']!,
            ),
          ),
        );
      },
      child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[100],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/doctor/categories/$path/${symptom['image']}',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.medical_services,
                        size: 30, color: Colors.grey);
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              symptom['name']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
    );
  }
}
