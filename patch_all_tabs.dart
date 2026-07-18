import 'dart:io';

void main() {
  final files = [
    'vendor_app/lib/screens/doctor/doctor_home_screen.dart',
    'vendor_app/lib/screens/doctor/bookings_screen.dart',
    'vendor_app/lib/screens/doctor/earnings_screen.dart',
    'vendor_app/lib/screens/profile/profile_screen.dart',
    // also other vendors
    'vendor_app/lib/screens/ambulance/ride_requests_screen.dart',
    'vendor_app/lib/screens/pathology/pathology_bookings_screen.dart',
    'vendor_app/lib/screens/blood_bank/blood_bank_bookings_screen.dart',
    'vendor_app/lib/screens/nurse/bookings_screen.dart',
  ];

  for (var file in files) {
    final f = File(file);
    if (!f.existsSync()) continue;
    String content = f.readAsStringSync();
    
    if (content.contains("automaticallyImplyLeading: false,")) {
       continue;
    }

    if (content.contains("automaticallyImplyLeading: !widget.isTab,")) {
       continue;
    }

    // Replace the first elevation: x, with automaticallyImplyLeading: false,
    content = content.replaceFirst(
      "elevation: 0,",
      "elevation: 0,\n        automaticallyImplyLeading: false,"
    );
    f.writeAsStringSync(content);
  }
}
