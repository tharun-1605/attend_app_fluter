import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../models/company_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/modern_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _companyIdController = TextEditingController();

  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String _selectedRole = 'employee';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyNameController.dispose();
    _companyIdController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final companyIdInput = _companyIdController.text.trim();
      if (_selectedRole == 'employee') {
        final company = await _firestoreService.getCompany(companyIdInput);
        if (company == null) {
          throw Exception('Invalid company ID. Please check with your owner.');
        }
      }

      UserModel? user = await _authService.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        role: _selectedRole,
        companyId: _selectedRole == 'employee' ? companyIdInput : null,
      );

      if (user != null) {
        if (_selectedRole == 'owner') {
          final company = CompanyModel(
            id: const Uuid().v4(),
            name: _companyNameController.text.trim(),
            ownerId: user.id,
            createdAt: DateTime.now(),
          );
          await _firestoreService.createCompany(company);
          user = user.copyWith(companyId: company.id);
          await _authService.updateUserData(user);
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please login.'),
            backgroundColor: AppTheme.successColor,
          ),
        );
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
        title: 'Create a workspace that feels ready on day one.',
        subtitle:
            'Owners can set up their company, while employees can join quickly with a company ID and start attendance without friction.',
        icon: Icons.groups_2_rounded,
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
        trailing: StatusPill(
          label: _selectedRole == 'owner' ? 'Owner setup' : 'Employee join',
          color: Colors.white,
          icon: _selectedRole == 'owner'
              ? Icons.apartment_rounded
              : Icons.badge_rounded,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Create account',
                      style: AppTheme.headingLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
                      );
                    },
                    child: const Text('Back to login'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your role, then fill in the essentials.',
                style: AppTheme.bodyLarge.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              SegmentedButton<String>(
                style: ButtonStyle(
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                segments: const [
                  ButtonSegment<String>(
                    value: 'employee',
                    label: Text('Employee'),
                    icon: Icon(Icons.person_outline_rounded),
                  ),
                  ButtonSegment<String>(
                    value: 'owner',
                    label: Text('Owner'),
                    icon: Icon(Icons.apartment_rounded),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (selection) {
                  setState(() {
                    _selectedRole = selection.first;
                  });
                },
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
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
                    return 'Please enter a password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirm password',
                  prefixIcon: const Icon(Icons.verified_user_outlined),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _selectedRole == 'owner'
                    ? Padding(
                        key: const ValueKey('owner'),
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          controller: _companyNameController,
                          decoration: const InputDecoration(
                            labelText: 'Company name',
                            prefixIcon: Icon(Icons.business_center_rounded),
                          ),
                          validator: (value) {
                            if (_selectedRole == 'owner' &&
                                (value == null || value.isEmpty)) {
                              return 'Please enter your company name';
                            }
                            return null;
                          },
                        ),
                      )
                    : Padding(
                        key: const ValueKey('employee'),
                        padding: const EdgeInsets.only(top: 16),
                        child: TextFormField(
                          controller: _companyIdController,
                          decoration: const InputDecoration(
                            labelText: 'Company ID',
                            helperText: 'Ask your owner for the company ID',
                            prefixIcon: Icon(Icons.badge_outlined),
                          ),
                          validator: (value) {
                            if (_selectedRole == 'employee' &&
                                (value == null || value.trim().isEmpty)) {
                              return 'Please enter company ID';
                            }
                            return null;
                          },
                        ),
                      ),
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
                        key: const ValueKey('register-button'),
                        onPressed: _register,
                        icon: const Icon(Icons.rocket_launch_rounded),
                        label: const Text('Create account'),
                      ),
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
        child: SingleChildScrollView(
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 10, child: hero),
                    const SizedBox(width: 24),
                    Expanded(flex: 12, child: formPanel),
                  ],
                )
              : Column(
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
