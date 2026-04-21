import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/employee/employee_home_screen.dart';
import 'screens/employee/face_register_screen.dart';
import 'screens/employee/face_login_screen.dart';
import 'screens/employee/attendance_history_screen.dart';
import 'screens/owner/owner_home_screen.dart';
import 'screens/owner/company_settings_screen.dart';
import 'screens/owner/employee_list_screen.dart';
import 'screens/owner/attendance_report_screen.dart';
import 'screens/owner/today_attendance_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  await NotificationService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.register: (context) => const RegisterScreen(),
        AppRoutes.employeeHome: (context) => const EmployeeHomeScreen(),
        AppRoutes.faceRegister: (context) => const FaceRegisterScreen(),
        AppRoutes.faceLogin: (context) => const FaceLoginScreen(),
        AppRoutes.attendanceHistory: (context) =>
            const AttendanceHistoryScreen(),
        AppRoutes.ownerHome: (context) => const OwnerHomeScreen(),
        AppRoutes.companySettings: (context) => const CompanySettingsScreen(),
        AppRoutes.employeeList: (context) => const EmployeeListScreen(),
        AppRoutes.attendanceReport: (context) => const AttendanceReportScreen(),
        AppRoutes.todayAttendance: (context) => const TodayAttendanceScreen(),
      },
    );
  }
}
