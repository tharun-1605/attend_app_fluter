import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/attendance_model.dart';
import '../../widgets/modern_ui.dart';

class TodayAttendanceScreen extends StatefulWidget {
  const TodayAttendanceScreen({super.key});

  @override
  State<TodayAttendanceScreen> createState() => _TodayAttendanceScreenState();
}

class _TodayAttendanceScreenState extends State<TodayAttendanceScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  List<AttendanceModel> _attendanceList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _authService.getUserData(user.uid);

        if (userData?.companyId != null) {
          final attendance = await _firestoreService.getAttendanceByCompany(
            userData!.companyId!,
            date: DateTime.now(),
          );

          if (!mounted) return;
          setState(() {
            _attendanceList = attendance;
            _isLoading = false;
          });
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading attendance: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayLabel = DateFormat('MMM dd, yyyy').format(DateTime.now());

    return GradientScaffold(
      child: ResponsiveContent(
        maxWidth: 980,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text("Today's Attendance", style: AppTheme.headingMedium),
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
                      Icons.today_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Date: $todayLabel',
                      style: AppTheme.headingSmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _buildSummaryCard(
                  'Total',
                  _attendanceList.length.toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
                _buildSummaryCard(
                  'Present',
                  _attendanceList
                      .where((a) => a.status == 'present' || a.status == 'late')
                      .length
                      .toString(),
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
                _buildSummaryCard(
                  'Invalid',
                  _attendanceList
                      .where((a) => a.status != 'present' && a.status != 'late')
                      .length
                      .toString(),
                  Icons.warning,
                  AppTheme.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _attendanceList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.event_busy,
                                size: 56,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No attendance records for today',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAttendance,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _attendanceList.length,
                            itemBuilder: (context, index) {
                              final attendance = _attendanceList[index];
                              return _buildAttendanceCard(attendance);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return SizedBox(
      width: 110,
      child: GlassPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(value, style: AppTheme.headingSmall.copyWith(color: color)),
            Text(label, style: AppTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              attendance.status == 'present' || attendance.status == 'late'
              ? AppTheme.successColor
              : AppTheme.errorColor,
          child: Icon(
            attendance.status == 'present' || attendance.status == 'late'
                ? Icons.check
                : Icons.warning,
            color: Colors.white,
          ),
        ),
        title: Text(attendance.userName),
        subtitle: Text(
          'Check in: ${timeFormat.format(attendance.checkInTime)} - ${_statusLabel(attendance.status)}',
          style: AppTheme.bodySmall,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(
              attendance.isValidLocation
                  ? Icons.location_on
                  : Icons.location_off,
              size: 16,
              color: attendance.isValidLocation
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
            ),
            Text(
              attendance.isValidLocation ? 'Valid' : 'Invalid',
              style: TextStyle(
                fontSize: 12,
                color: attendance.isValidLocation
                    ? AppTheme.successColor
                    : AppTheme.errorColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'late':
        return 'Present (Late)';
      case 'present':
        return 'Present';
      case 'invalid_location':
        return 'Invalid Location';
      default:
        return status.replaceAll('_', ' ');
    }
  }
}
