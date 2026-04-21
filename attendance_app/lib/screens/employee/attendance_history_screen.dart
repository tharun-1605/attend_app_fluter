import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/firestore_service.dart';
import '../../models/attendance_model.dart';
import '../../widgets/modern_ui.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  final _firestoreService = FirestoreService();

  List<AttendanceModel> _attendanceList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final attendance = await _firestoreService.getAttendanceByUser(
          user.uid,
        );
        setState(() {
          _attendanceList = attendance;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading attendance: $e'),
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
              child: Text('Attendance History', style: AppTheme.headingMedium),
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
                      Icons.history_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent records', style: AppTheme.headingSmall),
                        const SizedBox(height: 2),
                        Text(
                          '${_attendanceList.length} entries available',
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
                  : _attendanceList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.history,
                                size: 56,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No attendance records yet',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAttendanceHistory,
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

  Widget _buildAttendanceCard(AttendanceModel attendance) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateFormat.format(attendance.checkInTime),
                  style: AppTheme.headingSmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: attendance.status == 'present'
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : attendance.status == 'late'
                        ? AppTheme.accentColor.withValues(alpha: 0.1)
                        : AppTheme.errorColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _statusLabel(attendance.status),
                    style: TextStyle(
                      color: attendance.status == 'present'
                          ? AppTheme.successColor
                          : attendance.status == 'late'
                          ? AppTheme.accentColor
                          : AppTheme.errorColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Check In',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeFormat.format(attendance.checkInTime),
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                if (attendance.checkOutTime != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Check Out',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeFormat.format(attendance.checkOutTime!),
                          style: AppTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
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
                const SizedBox(width: 4),
                Text(
                  attendance.isValidLocation
                      ? 'Location verified'
                      : 'Location not verified',
                  style: TextStyle(
                    color: attendance.isValidLocation
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'late':
        return 'PRESENT (LATE)';
      case 'present':
        return 'PRESENT';
      case 'invalid_location':
        return 'INVALID LOCATION';
      default:
        return status.replaceAll('_', ' ').toUpperCase();
    }
  }
}
