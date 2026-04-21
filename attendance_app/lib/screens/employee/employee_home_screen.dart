import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/modern_ui.dart';

class EmployeeHomeScreen extends StatefulWidget {
  const EmployeeHomeScreen({super.key});

  @override
  State<EmployeeHomeScreen> createState() => _EmployeeHomeScreenState();
}

class _EmployeeHomeScreenState extends State<EmployeeHomeScreen> {
  final _authService = AuthService();
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
        if (!mounted) return;
        setState(() {
          _user = userData;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
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
                    'Error loading user data',
                    style: AppTheme.bodyLarge,
                  ),
                )
              : ResponsiveContent(
                  maxWidth: 1080,
                  child: RefreshIndicator(
                    onRefresh: _loadUserData,
                    child: ListView(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 30),
                          child: HeroBanner(
                            title: 'Hello, ${_user!.name}',
                            subtitle:
                                'Use quick actions to mark attendance, track history, and keep your check-ins consistent.',
                            icon: Icons.badge_rounded,
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
                          delay: const Duration(milliseconds: 120),
                          child: GlassPanel(
                            child: Wrap(
                              runSpacing: 14,
                              spacing: 14,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _InfoTile(
                                  icon: Icons.mail_outline_rounded,
                                  title: 'Email',
                                  value: _user!.email,
                                ),
                                _InfoTile(
                                  icon: _user!.isFaceRegistered
                                      ? Icons.verified_rounded
                                      : Icons.warning_amber_rounded,
                                  title: 'Face status',
                                  value: _user!.isFaceRegistered
                                      ? 'Registered and ready'
                                      : 'Registration needed',
                                  color: _user!.isFaceRegistered
                                      ? AppTheme.successColor
                                      : AppTheme.warningColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        AnimatedEntrance(
                          delay: const Duration(milliseconds: 200),
                          child: GlassPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quick actions',
                                    style: AppTheme.headingSmall),
                                const SizedBox(height: 8),
                                Text(
                                  'Everything important is one tap away.',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth > 720;
                                    return IntrinsicHeight(
                                      child: Flex(
                                        direction:
                                            isWide ? Axis.horizontal : Axis.vertical,
                                        children: [
                                          Expanded(
                                            child: _ActionCard(
                                              title: 'Mark Attendance',
                                              subtitle:
                                                'Use face verification to check in or check out securely.',
                                            icon: Icons.camera_alt_rounded,
                                            color: AppTheme.primaryColor,
                                            buttonLabel: 'Open camera',
                                            onTap: () {
                                              Navigator.pushNamed(
                                                context,
                                                AppRoutes.faceLogin,
                                              );
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: isWide ? 16 : 0,
                                          height: isWide ? 0 : 16,
                                        ),
                                        Expanded(
                                          child: _ActionCard(
                                            title: _user!.isFaceRegistered
                                                ? 'Face Registered'
                                                : 'Register Face',
                                            subtitle: _user!.isFaceRegistered
                                                ? 'Your profile is verified and ready for attendance.'
                                                : 'Complete your face setup before using attendance.',
                                            icon: _user!.isFaceRegistered
                                                ? Icons.check_circle_rounded
                                                : Icons.face_retouching_natural,
                                            color: _user!.isFaceRegistered
                                                ? AppTheme.successColor
                                                : AppTheme.accentColor,
                                            buttonLabel: _user!.isFaceRegistered
                                                ? 'View status'
                                                : 'Register now',
                                            onTap: _user!.isFaceRegistered
                                                ? null
                                                : () {
                                                    Navigator.pushNamed(
                                                      context,
                                                      AppRoutes.faceRegister,
                                                    );
                                                  },
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.attendanceHistory,
                                    );
                                  },
                                  icon: const Icon(Icons.history_rounded),
                                  label:
                                      const Text('View attendance history'),
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
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
    this.color = AppTheme.primaryDark,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTheme.bodySmall),
                const SizedBox(height: 2),
                Text(value, style: AppTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.buttonLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String buttonLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.14),
            Colors.white.withValues(alpha: 0.92),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 18),
          Text(title, style: AppTheme.headingSmall),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          if (onTap == null)
            StatusPill(
              label: buttonLabel,
              color: color,
              icon: Icons.check_circle_rounded,
            )
          else
            ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: Text(buttonLabel),
            ),
        ],
      ),
    );
  }
}
