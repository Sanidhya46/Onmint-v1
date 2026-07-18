import 'package:flutter/material.dart';

class NotFoundScreen extends StatelessWidget {
  final String title;
  const NotFoundScreen({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(top: false, bottom: true, child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Feature Coming Soon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This section is currently under development.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
              ),
              child: const Text('Go Back', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      )),
    );
  }
}
