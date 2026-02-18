import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../models/company_model.dart';

class OwnerHomeScreen extends StatefulWidget {
  const OwnerHomeScreen({super.key});

  @override
  State<OwnerHomeScreen> createState() => _OwnerHomeScreenState();
}

class _OwnerHomeScreenState extends State<OwnerHomeScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  UserModel? _user;
  CompanyModel? _company;
  bool _isLoading = true;
  Map<String, int>? _todayStats;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);
        if (userData == null) {
          if (!mounted) return;
          setState(() {
            _user = null;
            _company = null;
            _todayStats = null;
            _loadError = 'User profile not found. Please register again.';
            _isLoading = false;
          });
          return;
        }

        CompanyModel? company;
        if (userData.companyId != null) {
          company = await _firestoreService.getCompany(userData.companyId!);
        }

        if (!mounted) return;
        setState(() {
          _user = userData;
          _company = company;
          _todayStats = null;
          _loadError = null;
          _isLoading = false;
        });

        Map<String, int>? stats;
        if (company != null) {
          try {
            stats = await _firestoreService.getAttendanceStats(
              company.id,
              DateTime.now(),
            );
          } on FirebaseException catch (e) {
            if (mounted) {
              final needsIndex = e.code == 'failed-precondition' &&
                  (e.message ?? '').toLowerCase().contains('requires an index');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    needsIndex
                        ? 'Attendance stats need a Firestore index. Open Attendance Reports to generate/create the index link.'
                        : 'Could not load stats: ${e.message ?? e.code}',
                  ),
                  backgroundColor: AppTheme.errorColor,
                ),
              );
            }
          }
        }

        if (!mounted) return;
        setState(() {
          _todayStats = stats;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _loadError = 'No logged in user.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Error loading dashboard: $e';
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
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? Center(
              child: Text(_loadError ?? 'Error loading user data'),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                              Icons.business,
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
                              _company?.name ?? 'No company',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Today's Stats
                    if (_todayStats != null) ...[
                      Text("Today's Stats", style: AppTheme.headingSmall),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              _todayStats!['total'].toString(),
                              Icons.people,
                              AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Present',
                              _todayStats!['present'].toString(),
                              Icons.check_circle,
                              AppTheme.successColor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Absent',
                              _todayStats!['absent'].toString(),
                              Icons.cancel,
                              AppTheme.errorColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Menu Options
                    Text('Management', style: AppTheme.headingSmall),
                    const SizedBox(height: 10),

                    _buildMenuCard(
                      'Company Settings',
                      'Configure company location and working hours',
                      Icons.settings,
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.companySettings,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildMenuCard(
                      'Employee List',
                      'View and manage employees',
                      Icons.people,
                      () =>
                          Navigator.pushNamed(context, AppRoutes.employeeList),
                    ),
                    const SizedBox(height: 12),

                    _buildMenuCard(
                      'Attendance Reports',
                      'View attendance reports and analytics',
                      Icons.analytics,
                      () => Navigator.pushNamed(
                        context,
                        AppRoutes.attendanceReport,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(value, style: AppTheme.headingMedium.copyWith(color: color)),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: AppTheme.bodyLarge),
        subtitle: Text(subtitle, style: AppTheme.bodySmall),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
