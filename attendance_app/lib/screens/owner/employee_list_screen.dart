import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../widgets/modern_ui.dart';

class EmployeeListScreen extends StatefulWidget {
  const EmployeeListScreen({super.key});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  List<UserModel> _employees = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);

        if (userData?.companyId != null) {
          final employees = await _firestoreService.getEmployeesByCompany(
            userData!.companyId!,
          );

          setState(() {
            _employees = employees;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading employees: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      child: ResponsiveContent(
        maxWidth: 980,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text('Employee List', style: AppTheme.headingMedium),
            ),
            GlassPanel(
              child: Row(
                children: [
                  Container(
                    height: 42,
                    width: 42,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Team directory', style: AppTheme.headingSmall),
                        const SizedBox(height: 2),
                        Text(
                          '${_employees.length} employees linked to this company',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _employees.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.people,
                                size: 56,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No employees yet',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Employees can register using the app',
                                style: AppTheme.bodySmall,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadEmployees,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _employees.length,
                            itemBuilder: (context, index) {
                              final employee = _employees[index];
                              return _buildEmployeeCard(employee);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(UserModel employee) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            employee.name.isNotEmpty ? employee.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(employee.name, style: AppTheme.bodyLarge),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(employee.email, style: AppTheme.bodySmall),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  employee.isFaceRegistered
                      ? Icons.check_circle
                      : Icons.warning,
                  size: 14,
                  color: employee.isFaceRegistered
                      ? AppTheme.successColor
                      : AppTheme.accentColor,
                ),
                const SizedBox(width: 4),
                Text(
                  employee.isFaceRegistered
                      ? 'Face registered'
                      : 'Face not registered',
                  style: TextStyle(
                    fontSize: 11,
                    color: employee.isFaceRegistered
                        ? AppTheme.successColor
                        : AppTheme.accentColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: employee.lastAttendance != null
            ? Text(
                _formatDate(employee.lastAttendance!),
                style: AppTheme.bodySmall,
              )
            : null,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
