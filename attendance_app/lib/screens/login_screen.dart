import 'package:flutter/material.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../services/auth_service.dart';
import '../widgets/modern_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (user != null && mounted) {
        if (user.role == 'owner') {
          Navigator.pushReplacementNamed(context, AppRoutes.ownerHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.employeeHome);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 860;
    final hero = AnimatedEntrance(
      delay: const Duration(milliseconds: 40),
      child: HeroBanner(
        title: 'Face-first attendance, made calm and fast.',
        subtitle:
            'A cleaner workspace for owners and employees to check in, verify identity, and follow attendance in real time.',
        icon: Icons.verified_user_rounded,
        leading: Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const AppLogoMark(
            size: 56,
            padding: EdgeInsets.all(8),
            borderRadius: 18,
          ),
        ),
        trailing: const StatusPill(
          label: 'Live attendance',
          color: Colors.white,
          icon: Icons.auto_graph,
        ),
      ),
    );
    final formPanel = AnimatedEntrance(
      delay: const Duration(milliseconds: 140),
      child: GlassPanel(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Welcome back', style: AppTheme.headingLarge),
              const SizedBox(height: 8),
              Text(
                'Sign in to manage attendance with a faster, clearer dashboard.',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@company.com',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : ElevatedButton.icon(
                        key: const ValueKey('login-button'),
                        onPressed: _login,
                        icon: const Icon(Icons.login_rounded),
                        label: const Text('Login'),
                      ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Text(
                    "Don't have an account?",
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                    child: const Text('Register'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return GradientScaffold(
      child: ResponsiveContent(
        maxWidth: 1160,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: isWide
            ? Center(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 11, child: hero),
                    const SizedBox(width: 24),
                    Expanded(flex: 10, child: formPanel),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    hero,
                    const SizedBox(height: 24),
                    formPanel,
                  ],
                ),
              ),
      ),
    );
  }
}
