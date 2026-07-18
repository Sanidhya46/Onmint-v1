import 'dart:io';

void main() {
  final files = [
    'vendor_app/lib/screens/home/home_screen.dart',
    'vendor_app/lib/screens/doctor/doctor_main_screen.dart',
  ];

  for (var file in files) {
    final f = File(file);
    if (!f.existsSync()) continue;
    String content = f.readAsStringSync();
    
    // Add import if missing
    if (!content.contains("import 'package:flutter/services.dart';")) {
      content = "import 'package:flutter/services.dart';\n" + content;
    }
    
    // Replace the return true logic
    content = content.replaceAll(
      "        return true;\n      },\n      child: Scaffold",
      "        SystemNavigator.pop();\n        return false;\n      },\n      child: Scaffold"
    );
    f.writeAsStringSync(content);
  }
}
