import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';

class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isApproved = user?.status == 'approved';
    final docs = user?.documents ?? {};

    // Map of expected documents
    final Map<String, Map<String, dynamic>> expectedDocs = {
      'profilePhoto': {
        'title': 'Profile Photo',
        'subtitle': 'Professional Photo',
        'icon': Icons.person_outline,
        'color': Colors.blue,
        'hasDoc': user?.profilePicture != null && user!.profilePicture!.isNotEmpty,
      },
      'idProof': {
        'title': 'Identity Card',
        'subtitle': 'Govt Identity Document',
        'icon': Icons.badge_outlined,
        'color': Colors.green,
        'hasDoc': docs['idProof'] != null,
      },
      'registration': {
        'title': 'Registration Cert',
        'subtitle': 'State Council Reg.',
        'icon': Icons.assignment_outlined,
        'color': Colors.purple,
        'hasDoc': docs['registration'] != null,
      },
      'certificate': {
        'title': 'Degree Cert',
        'subtitle': 'University Qualification',
        'icon': Icons.school_outlined,
        'color': Colors.orange,
        'hasDoc': docs['certificate'] != null,
      },
    };

    int uploadedCount = expectedDocs.values.where((d) => d['hasDoc'] as bool).length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Certificates',
          style: TextStyle(
            color: Color(0xFF152238),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.shield, color: Colors.blue, size: 36),
                        const Icon(Icons.verified, color: Colors.white, size: 16),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Credentials',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF152238),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Add and manage your documents.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Text(
              'Your Documents ($uploadedCount)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF152238),
              ),
            ),
            const SizedBox(height: 8),

            // Document List
            ...expectedDocs.entries.map((entry) {
              final doc = entry.value;
              return _buildDocumentItem(
                icon: doc['icon'] as IconData,
                iconColor: doc['color'] as Color,
                iconBgColor: (doc['color'] as MaterialColor).shade50,
                title: doc['title'] as String,
                subtitle: doc['subtitle'] as String,
                hasDoc: doc['hasDoc'] as bool,
                isApproved: isApproved,
              );
            }).toList(),

            const SizedBox(height: 12),

            // Keep Your Documents Updated
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.security, color: Colors.blue, size: 24),
                  ),
                  const SizedBox(width: 24),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Keep Documents Updated',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF152238),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Make sure your documents are valid.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: Row(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 const Icon(Icons.lock_outline, size: 24, color: Colors.grey),
                 const SizedBox(width: 8),
                 Text(
                   'Your information is secure and confidential.',
                   style: TextStyle(
                     fontSize: 12,
                     color: Colors.grey.shade600,
                   ),
                 ),
               ],
             ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '© Onmint. All Rights Reserved.',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool hasDoc,
    required bool isApproved,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF152238),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (hasDoc && isApproved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else if (hasDoc && !isApproved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.pending, color: Colors.orange, size: 20),
                  SizedBox(width: 4),
                  Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          else
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Upload',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
