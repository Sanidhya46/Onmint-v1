import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_service/auth_service.dart';
import '../config/app_config.dart';
import '../config/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    // Delay initialization to allow splash to render first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  void _setupAnimation() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.initialize();

      // Fast loading animation delay of 800 ms
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      if (AppConfig.developmentMode && AppConfig.forceLogoutOnStart) {
        await authProvider.forceLogout();
        if (mounted) Navigator.of(context).pushReplacementNamed('/register');
        return;
      }

      if (authProvider.isAuthenticated && authProvider.isPatient) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/home');
      } else {
        if (authProvider.isAuthenticated && !authProvider.isPatient) {
          await authProvider.logout();
        }
        if (mounted) Navigator.of(context).pushReplacementNamed('/register');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/register');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_screen.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.primary,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_hospital,
                            size: screenSize.width * 0.25,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'OnMint',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D6EFD)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
