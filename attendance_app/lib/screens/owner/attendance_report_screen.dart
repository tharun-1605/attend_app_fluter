import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../config/theme.dart';
import '../../models/attendance_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  List<AttendanceModel> _attendanceList = [];
  List<UserModel> _missingEmployees = [];
  bool _isLoading = true;
  bool _didApplyArguments = false;
  DateTime _selectedDate = DateTime.now();
  String _period = 'today';
  String _recordFilter = 'all';
  String? _companyId;

  List<AttendanceModel> get _filteredAttendanceList {
    switch (_recordFilter) {
      case 'late':
        return _attendanceList.where((item) => item.status == 'late').toList();
      case 'invalid':
        return _attendanceList
            .where(
              (item) => item.status == 'invalid_location' || !item.isValidLocation,
            )
            .toList();
      default:
        return _attendanceList;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyArguments) return;

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _period = (args?['period'] as String?) ?? _period;
    _recordFilter = (args?['recordFilter'] as String?) ?? _recordFilter;
    _didApplyArguments = true;
    _loadAttendance();
  }

  Future<void> _loadAttendance() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No logged in owner found');
      }

      final userData = await _authService.getUserData(user.uid);
      if (userData?.companyId == null) {
        throw Exception('No company linked to this owner');
      }

      final companyId = userData!.companyId!;
      final range = _resolveRange(_selectedDate, _period);
      final attendance = await _firestoreService.getAttendanceByCompanyRange(
        companyId,
        startDate: range.start,
        endDate: range.end,
      );
      final missingEmployees = _period == 'today'
          ? await _firestoreService.getAbsentEmployeesForDate(
              companyId,
              _selectedDate,
            )
          : <UserModel>[];

      if (!mounted) return;
      setState(() {
        _companyId = companyId;
        _attendanceList = attendance;
        _missingEmployees = missingEmployees;
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked == null || _isSameDay(picked, _selectedDate)) return;
    setState(() {
      _selectedDate = picked;
    });
    await _loadAttendance();
  }

  Future<void> _exportCurrentView() async {
    final visibleRows = _filteredAttendanceList;
    if (visibleRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No attendance records available to export.'),
          backgroundColor: AppTheme.warningColor,
        ),
      );
      return;
    }

    try {
      final directory = await getApplicationDocumentsDirectory();
      final range = _resolveRange(_selectedDate, _period);
      final fileName =
          'attendance_${_period}_${DateFormat('yyyyMMdd').format(range.start)}.csv';
      final file = File('${directory.path}/$fileName');
      final csv = StringBuffer()
        ..writeln('Report Type,${_csvValue(_periodLabel)}')
        ..writeln('Record Filter,${_csvValue(_recordFilterLabel)}')
        ..writeln('Range,${_csvValue(_rangeLabel(range))}')
        ..writeln()
        ..writeln(
          'Employee,Status,Valid Location,Check In,Check Out,Check In Coordinates,Check Out Coordinates',
        );

      final dateTimeFormat = DateFormat('yyyy-MM-dd hh:mm a');
      for (final item in visibleRows) {
        csv.writeln(
          [
            _csvValue(item.userName),
            _csvValue(_statusLabel(item.status)),
            item.isValidLocation ? 'Yes' : 'No',
            _csvValue(dateTimeFormat.format(item.checkInTime)),
            _csvValue(
              item.checkOutTime == null
                  ? '-'
                  : dateTimeFormat.format(item.checkOutTime!),
            ),
            _csvValue(_coordinateLabel(item.checkInLatitude, item.checkInLongitude)),
            _csvValue(
              _coordinateLabel(item.checkOutLatitude, item.checkOutLongitude),
            ),
          ].join(','),
        );
      }

      if (_period == 'today' && _missingEmployees.isNotEmpty) {
        csv
          ..writeln()
          ..writeln('Missing Employees')
          ..writeln('Name,Email');
        for (final employee in _missingEmployees) {
          csv.writeln(
            '${_csvValue(employee.name)},${_csvValue(employee.email)}',
          );
        }
      }

      await file.writeAsString(csv.toString(), flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported report to ${file.path}'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleRows = _filteredAttendanceList;
    final range = _resolveRange(_selectedDate, _period);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Report'),
        actions: [
          IconButton(
            tooltip: 'Export CSV',
            onPressed: _isLoading ? null : _exportCurrentView,
            icon: const Icon(Icons.download_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Range: ${_rangeLabel(range)}',
                  style: AppTheme.headingSmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in const [
                      ('today', 'Today', Icons.today_rounded),
                      ('week', 'Weekly', Icons.view_week_rounded),
                      ('month', 'Monthly', Icons.calendar_month_rounded),
                    ])
                      ChoiceChip(
                        label: Text(item.$2),
                        avatar: Icon(item.$3, size: 18),
                        selected: _period == item.$1,
                        onSelected: (_) async {
                          setState(() {
                            _period = item.$1;
                          });
                          await _loadAttendance();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final item in const [
                      ('all', 'All records'),
                      ('late', 'Late employees'),
                      ('invalid', 'Invalid location'),
                    ])
                      FilterChip(
                        label: Text(item.$2),
                        selected: _recordFilter == item.$1,
                        onSelected: (_) {
                          setState(() {
                            _recordFilter = item.$1;
                          });
                        },
                      ),
                    OutlinedButton.icon(
                      onPressed: _selectDate,
                      icon: const Icon(Icons.event_rounded),
                      label: Text(
                        'Reference date: ${DateFormat('MMM dd, yyyy').format(_selectedDate)}',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildSummaryCard(
                  'Visible',
                  visibleRows.length.toString(),
                  Icons.people_rounded,
                  AppTheme.primaryColor,
                ),
                _buildSummaryCard(
                  'Present',
                  visibleRows
                      .where(
                        (item) =>
                            item.status == 'present' || item.status == 'late',
                      )
                      .length
                      .toString(),
                  Icons.check_circle_rounded,
                  AppTheme.successColor,
                ),
                _buildSummaryCard(
                  'Late',
                  visibleRows
                      .where((item) => item.status == 'late')
                      .length
                      .toString(),
                  Icons.alarm_rounded,
                  AppTheme.warningColor,
                ),
                _buildSummaryCard(
                  'Invalid',
                  visibleRows
                      .where(
                        (item) =>
                            item.status == 'invalid_location' ||
                            !item.isValidLocation,
                      )
                      .length
                      .toString(),
                  Icons.location_off_rounded,
                  AppTheme.errorColor,
                ),
                if (_period == 'today')
                  _buildSummaryCard(
                    'Missing',
                    _missingEmployees.length.toString(),
                    Icons.person_off_rounded,
                    AppTheme.primaryDark,
                  ),
              ],
            ),
          ),
          if (_period == 'today' && _missingEmployees.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Employees missing today', style: AppTheme.headingSmall),
                      const SizedBox(height: 8),
                      Text(
                        _missingEmployees
                            .map((employee) => employee.name)
                            .join(', '),
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : visibleRows.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.event_busy,
                              size: 60,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _companyId == null
                                  ? 'No company linked to this account'
                                  : 'No attendance records for this filter',
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
                          padding: const EdgeInsets.all(16),
                          itemCount: visibleRows.length,
                          itemBuilder: (context, index) {
                            return _buildAttendanceCard(visibleRows[index]);
                          },
                        ),
                      ),
          ),
        ],
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
      width: 150,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(value, style: AppTheme.headingSmall.copyWith(color: color)),
              Text(label, style: AppTheme.bodySmall),
            ],
          ),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Check in: ${timeFormat.format(attendance.checkInTime)} - ${_statusLabel(attendance.status)}',
              style: AppTheme.bodySmall,
            ),
            if (attendance.checkOutTime != null)
              Text(
                'Check out: ${timeFormat.format(attendance.checkOutTime!)}',
                style: AppTheme.bodySmall.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
          ],
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

  _DateRange _resolveRange(DateTime anchorDate, String period) {
    final startOfDay = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
    switch (period) {
      case 'week':
        final start = startOfDay.subtract(
          Duration(days: startOfDay.weekday - DateTime.monday),
        );
        return _DateRange(start: start, end: start.add(const Duration(days: 7)));
      case 'month':
        final start = DateTime(anchorDate.year, anchorDate.month, 1);
        final end = anchorDate.month == 12
            ? DateTime(anchorDate.year + 1, 1, 1)
            : DateTime(anchorDate.year, anchorDate.month + 1, 1);
        return _DateRange(start: start, end: end);
      case 'today':
      default:
        return _DateRange(
          start: startOfDay,
          end: startOfDay.add(const Duration(days: 1)),
        );
    }
  }

  String _rangeLabel(_DateRange range) {
    final formatter = DateFormat('MMM dd, yyyy');
    if (_period == 'today') {
      return formatter.format(range.start);
    }
    return '${formatter.format(range.start)} - ${formatter.format(range.end.subtract(const Duration(days: 1)))}';
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

  String get _periodLabel {
    switch (_period) {
      case 'week':
        return 'Weekly';
      case 'month':
        return 'Monthly';
      default:
        return 'Today';
    }
  }

  String get _recordFilterLabel {
    switch (_recordFilter) {
      case 'late':
        return 'Late employees';
      case 'invalid':
        return 'Invalid location';
      default:
        return 'All records';
    }
  }

  String _coordinateLabel(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return '-';
    return '$latitude,$longitude';
  }

  String _csvValue(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DateRange {
  const _DateRange({
    required this.start,
    required this.end,
  });

  final DateTime start;
  final DateTime end;
}
