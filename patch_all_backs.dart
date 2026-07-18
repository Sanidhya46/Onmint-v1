import 'dart:io';

void main() {
  final vendorFiles = [
    'vendor_app/lib/screens/doctor/appointment_details_screen.dart',
    'vendor_app/lib/screens/doctor/doctor_active_consultation_screen.dart',
    'vendor_app/lib/screens/doctor/consultation_success_screen.dart',
  ];

  for (var file in vendorFiles) {
    final f = File(file);
    if (!f.existsSync()) continue;
    String content = f.readAsStringSync();
    
    // Add import if missing
    if (!content.contains("import '../home/home_screen.dart';") && !content.contains("import 'package:vendor_app/screens/home/home_screen.dart';")) {
      content = "import '../home/home_screen.dart';\n" + content;
    }
    
    content = content.replaceAll(
      "Navigator.popUntil(context, (route) => route.isFirst)",
      "Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false)"
    );
    f.writeAsStringSync(content);
  }

  final userFiles = [
    'user_app/lib/screens/booking/doctor_request_sent_screen.dart',
    'user_app/lib/screens/booking/test_booking_screen.dart',
    'user_app/lib/screens/booking/order_detail_file.dart',
    'user_app/lib/screens/booking/nurse_booking_screen.dart',
  ];

  for (var file in userFiles) {
    final f = File(file);
    if (!f.existsSync()) continue;
    String content = f.readAsStringSync();
    
    // Add import if missing
    if (!content.contains("import '../home/home_screen.dart';") && !content.contains("import 'package:user_app/screens/home/home_screen.dart';")) {
      content = "import '../home/home_screen.dart';\n" + content;
    }
    
    content = content.replaceAll(
      "Navigator.popUntil(context, (route) => route.isFirst)",
      "Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomeScreen()), (route) => false)"
    );
    f.writeAsStringSync(content);
  }
}
