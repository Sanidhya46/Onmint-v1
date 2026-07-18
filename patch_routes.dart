import 'dart:io';

void main() {
  final files = [
    'user_app/lib/screens/booking/doctor_request_sent_screen.dart',
    'vendor_app/lib/screens/doctor/appointment_details_screen.dart',
    'vendor_app/lib/screens/doctor/doctor_active_consultation_screen.dart',
    'vendor_app/lib/screens/doctor/consultation_success_screen.dart'
  ];

  for (var file in files) {
    final f = File(file);
    if (!f.existsSync()) continue;
    String content = f.readAsStringSync();
    content = content.replaceAll(
      "Navigator.pushNamedAndRemoveUntil(\n          context,\n          '/home',\n          (route) => false,\n        );",
      "Navigator.popUntil(context, (route) => route.isFirst);"
    );
    content = content.replaceAll(
      "Navigator.pushNamedAndRemoveUntil(\n              context,\n              '/home',\n              (route) => false,\n            );",
      "Navigator.popUntil(context, (route) => route.isFirst);"
    );
    content = content.replaceAll(
      "Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false)",
      "Navigator.popUntil(context, (route) => route.isFirst)"
    );
    f.writeAsStringSync(content);
  }
}
