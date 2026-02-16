import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  UserModel? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        setState(() {
          _user = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('Error loading user data'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Welcome Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 60,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Welcome, ${_user!.name}!',
                            style: AppTheme.headingMedium,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _user!.email,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Face Registration Status
                  Card(
                    child: ListTile(
                      leading: Icon(
                        _user!.isFaceRegistered
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _user!.isFaceRegistered
                            ? AppTheme.successColor
                            : AppTheme.accentColor,
                      ),
                      title: const Text('Face Registration'),
                      subtitle: Text(
                        _user!.isFaceRegistered
                            ? 'Your face is registered'
                            : 'Please register your face',
                      ),
                      trailing: _user!.isFaceRegistered
                          ? null
                          : ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  AppRoutes.faceRegister,
                                );
                              },
                              child: const Text('Register'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Attendance Options
                  Text('Attendance', style: AppTheme.headingSmall),
                  const SizedBox(height: 10),

                  // Mark Attendance Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.faceLogin);
                    },
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Mark Attendance'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // View History Button
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.attendanceHistory);
                    },
                    icon: const Icon(Icons.history),
                    label: const Text('View Attendance History'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
