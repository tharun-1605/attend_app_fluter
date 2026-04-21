import 'package:flutter/material.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/employee/employee_home_screen.dart';
import '../screens/employee/face_register_screen.dart';
import '../screens/employee/face_login_screen.dart';
import '../screens/employee/attendance_history_screen.dart';
import '../screens/owner/owner_home_screen.dart';
import '../screens/owner/company_settings_screen.dart';
import '../screens/owner/employee_list_screen.dart';
import '../screens/owner/attendance_report_screen.dart';
import '../screens/owner/today_attendance_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String employeeHome = '/employee/home';
  static const String faceRegister = '/employee/face-register';
  static const String faceLogin = '/employee/face-login';
  static const String attendanceHistory = '/employee/attendance-history';
  static const String ownerHome = '/owner/home';
  static const String companySettings = '/owner/company-settings';
  static const String employeeList = '/owner/employee-list';
  static const String attendanceReport = '/owner/attendance-report';
  static const String todayAttendance = '/owner/today-attendance';

  static Map<String, WidgetBuilder> get routes => {
    splash: (context) => const SplashScreen(),
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    employeeHome: (context) => const EmployeeHomeScreen(),
    faceRegister: (context) => const FaceRegisterScreen(),
    faceLogin: (context) => const FaceLoginScreen(),
    attendanceHistory: (context) => const AttendanceHistoryScreen(),
    ownerHome: (context) => const OwnerHomeScreen(),
    companySettings: (context) => const CompanySettingsScreen(),
    employeeList: (context) => const EmployeeListScreen(),
    attendanceReport: (context) => const AttendanceReportScreen(),
    todayAttendance: (context) => const TodayAttendanceScreen(),
  };
}
