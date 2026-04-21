import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/routes.dart';
import '../services/auth_service.dart';
import '../config/theme.dart';
import '../widgets/modern_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    try {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Get user data and check role
        final authService = AuthService();
        final userData = await authService.getUserData(user.uid);
        if (!mounted) return;

        if (userData != null) {
          if (userData.role == 'owner') {
            Navigator.pushReplacementNamed(context, AppRoutes.ownerHome);
          } else {
            Navigator.pushReplacementNamed(context, AppRoutes.employeeHome);
          }
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const AppLogoMark(
                size: 108,
                padding: EdgeInsets.all(12),
                borderRadius: 20,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Attendance App',
              style: AppTheme.headingLarge.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 10),
            const Text(
              'Face Recognition Attendance System',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
