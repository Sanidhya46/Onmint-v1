import 'package:flutter/material.dart';

class ComingSoonScreen extends StatelessWidget {
  const ComingSoonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF152238)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(top: false, bottom: true, child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF152238),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'We are working hard to bring you\nthis feature. Stay tuned!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ],
        ),
      )),
    );
  }
}
