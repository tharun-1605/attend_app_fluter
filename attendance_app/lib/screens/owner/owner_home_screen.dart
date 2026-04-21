import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/company_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/modern_ui.dart';

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
              ? Center(
                  child: Text(
                    _loadError ?? 'Error loading user data',
                    style: AppTheme.bodyLarge,
                  ),
                )
              : ResponsiveContent(
                  maxWidth: 1160,
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 40),
                          child: HeroBanner(
                            title: 'Owner dashboard',
                            subtitle:
                                'Track today’s attendance, manage your company profile, and keep the whole team aligned from one place.',
                            icon: Icons.apartment_rounded,
                            trailing: IconButton.filledTonal(
                              onPressed: _logout,
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.18),
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.logout_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 100),
                          child: GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height: 56,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(18),
                                      ),
                                      child: const Icon(
                                        Icons.business_rounded,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Welcome, ${_user!.name}',
                                            style: AppTheme.headingMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _company?.name ?? 'No company linked',
                                            style: AppTheme.bodyLarge.copyWith(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (_company != null) ...[
                                  const SizedBox(height: 18),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 10,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      StatusPill(
                                        label: 'Company ID: ${_company!.id}',
                                        color: AppTheme.primaryColor,
                                        icon: Icons.badge_rounded,
                                      ),
                                      TextButton.icon(
                                        onPressed: () async {
                                          await Clipboard.setData(
                                            ClipboardData(text: _company!.id),
                                          );
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Company ID copied'),
                                              backgroundColor:
                                                  AppTheme.successColor,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.copy_rounded),
                                        label: const Text('Copy ID'),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (_todayStats != null) ...[
                          const SizedBox(height: 20),
                          AnimatedEntrance(
                            delay: const Duration(milliseconds: 160),
                            child: _buildStatsSection(context),
                          ),
                        ],
                        const SizedBox(height: 20),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 220),
                          child: GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Management', style: AppTheme.headingSmall),
                                const SizedBox(height: 8),
                                Text(
                                  'Quick shortcuts for the most-used owner actions.',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final twoColumns =
                                        constraints.maxWidth > 760;
                                    final children = [
                                      _buildMenuCard(
                                        'Today\'s Attendance',
                                        'Open a focused report for today only',
                                        Icons.today_rounded,
                                        AppTheme.primaryColor,
                                        () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.todayAttendance,
                                        ),
                                      ),
                                      _buildMenuCard(
                                        'Company Settings',
                                        'Configure company location and hours',
                                        Icons.settings_rounded,
                                        AppTheme.accentColor,
                                        () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.companySettings,
                                        ),
                                      ),
                                      _buildMenuCard(
                                        'Employee List',
                                        'View and manage employee accounts',
                                        Icons.groups_rounded,
                                        AppTheme.successColor,
                                        () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.employeeList,
                                        ),
                                      ),
                                      _buildMenuCard(
                                        'Attendance Reports',
                                        'Browse attendance analytics by date',
                                        Icons.analytics_rounded,
                                        AppTheme.primaryDark,
                                        () => Navigator.pushNamed(
                                          context,
                                          AppRoutes.attendanceReport,
                                        ),
                                      ),
                                    ];

                                    if (!twoColumns) {
                                      return Column(
                                        children: [
                                          for (var i = 0;
                                              i < children.length;
                                              i++) ...[
                                            children[i],
                                            if (i != children.length - 1)
                                              const SizedBox(height: 14),
                                          ],
                                        ],
                                      );
                                    }

                                    return Wrap(
                                      spacing: 16,
                                      runSpacing: 16,
                                      children: children
                                          .map(
                                            (child) => SizedBox(
                                              width:
                                                  (constraints.maxWidth - 16) /
                                                      2,
                                              child: child,
                                            ),
                                          )
                                          .toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final stats = _todayStats!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today\'s pulse',
          style: AppTheme.headingSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final statWidth = constraints.maxWidth > 760
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatCard(
                  width: statWidth,
                  label: 'Total team',
                  value: '${stats['total'] ?? 0}',
                  icon: Icons.people_alt_rounded,
                  color: AppTheme.primaryColor,
                ),
                _StatCard(
                  width: statWidth,
                  label: 'Present today',
                  value: '${stats['present'] ?? 0}',
                  icon: Icons.check_circle_rounded,
                  color: AppTheme.successColor,
                ),
                _StatCard(
                  width: statWidth,
                  label: 'Absent today',
                  value: '${stats['absent'] ?? 0}',
                  icon: Icons.person_off_rounded,
                  color: AppTheme.errorColor,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        GlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance overview', style: AppTheme.headingSmall),
              const SizedBox(height: 8),
              Text(
                'Today\'s attendance only: ${stats['present'] ?? 0} / ${stats['total'] ?? 0}',
                style: AppTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Absent for today only: ${stats['absent'] ?? 0}',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.todayAttendance),
                icon: const Icon(Icons.visibility_rounded),
                label: const Text('View today\'s attendance'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(26),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.headingSmall),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 18),
            Text(value, style: AppTheme.headingLarge.copyWith(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
