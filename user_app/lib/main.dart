import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'config/app_config.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/medicines/medicine_detail_screen.dart';
import 'screens/medicines/cart_screen.dart';
import 'screens/medicines/checkout_screen.dart';
import 'screens/medicines/medicines_list_screen.dart';
import 'screens/medicines/medicine_details_screen.dart';
import 'screens/consultation/video_consultation_screen.dart';
import 'screens/bookings/pharmacist_order_tracking_screen.dart';
import 'services/cart_service.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    print("Firebase init error: $e");
  }
  runApp(const OnMintUserApp());
}

class OnMintUserApp extends StatelessWidget {
  const OnMintUserApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: MaterialApp(
        title: 'OnMint - Healthcare Services',
        theme: AppConfig.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/home': (context) => const HomeScreen(),
          '/cart': (context) => const CartScreen(),
          '/checkout': (context) => const CheckoutScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/medicine-detail') {
            final medicineId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) =>
                  MedicineDetailScreen(medicineId: medicineId),
            );
          }
          if (settings.name == '/medicines-list') {
            return MaterialPageRoute(
              builder: (context) => const MedicinesListScreen(),
              settings: settings,
            );
          }
          if (settings.name == '/medicine-details') {
            return MaterialPageRoute(
              builder: (context) => const MedicineDetailsScreen(),
              settings: settings,
            );
          }
          // TEMPORARILY DISABLED FOR RELEASE 1.0.1+11
          // Consultation feature will be restored in a future release.
          /*
          if (settings.name == '/video-consultation') {
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => VideoConsultationScreen(
                bookingId: args['bookingId'] as String,
              ),
            );
          }
          */
          if (settings.name != null && settings.name!.startsWith('/pharmacist-tracking')) {
            final uri = Uri.parse(settings.name!);
            final bookingId = uri.queryParameters['id'] ?? '';
            return MaterialPageRoute(
              builder: (context) => PharmacistOrderTrackingScreen(bookingId: bookingId),
            );
          }
          // Doctor detail navigation removed - needs to fetch doctor data first
          return null;
        },
      ),
    );
  }
}
