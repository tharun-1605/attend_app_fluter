import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _notifications
        .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> showEmployeeCheckInReminder({
    required String userId,
    required String employeeName,
  }) async {
    await _showOncePerDay(
      key: 'employee-check-in-$userId',
      notificationId: userId.hashCode & 0x7fffffff,
      title: 'Attendance reminder',
      body: '$employeeName, please mark your attendance for today.',
    );
  }

  Future<void> showOwnerMissedAttendanceAlert({
    required String ownerId,
    required List<String> missingEmployeeNames,
  }) async {
    if (missingEmployeeNames.isEmpty) return;

    final previewNames = missingEmployeeNames.take(3).join(', ');
    final remainingCount = missingEmployeeNames.length - 3;
    final suffix = remainingCount > 0 ? ' and $remainingCount more' : '';

    await _showOncePerDay(
      key: 'owner-missed-attendance-$ownerId',
      notificationId: (ownerId.hashCode & 0x7fffffff) + 100000,
      title: 'Missed attendance alert',
      body:
          '${missingEmployeeNames.length} employees have not checked in yet: $previewNames$suffix.',
    );
  }

  Future<void> _showOncePerDay({
    required String key,
    required int notificationId,
    required String title,
    required String body,
  }) async {
    await initialize();

    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey();
    final lastShownDate = prefs.getString(key);
    if (lastShownDate == todayKey) return;

    const notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        'attendance_reminders',
        'Attendance Reminders',
        channelDescription: 'Attendance reminders and owner alerts',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _notifications.show(notificationId, title, body, notificationDetails);
    await prefs.setString(key, todayKey);
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }
}
