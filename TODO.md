# Attendance App with Face Recognition - Project Plan

## Project Overview
- **Project Name**: attendance_app
- **Type**: Flutter Android Application
- **Core Functionality**: Employee attendance system using face recognition with two user roles (Employee/Owner)
- **Target Users**: Company employees and owners

## Tech Stack
1. Flutter (Android)
2. Firebase Authentication (Email/Password)
3. Cloud Firestore (Database)
4. Firebase Storage (Face images backup)
5. On-device Face Recognition (TFLite FaceNet)
6. Geolocator (GPS validation)

## Features Breakdown

### Authentication
- [ ] Email/Password login
- [ ] User registration with role selection (Employee/Owner)
- [ ] Role-based access control

### Employee Features
- [ ] Face registration (capture face images)
- [ ] Face login for attendance
- [ ] GPS location validation
- [ ] View attendance history
- [ ] View company details

### Owner Features
- [ ] Company profile management
- [ ] Set company location (latitude/longitude with radius)
- [ ] Manage employees
- [ ] View all attendance records
- [ ] View attendance reports/analytics

### Core Features
- [ ] Face recognition using TFLite (offline capable)
- [ ] GPS location checking against company location
- [ ] Cloud Firestore for data storage
- [ ] Firebase Storage for face image backup

## Project Structure

```
lib/
├── main.dart
├── app.dart
├── config/
│   ├── theme.dart
│   └── routes.dart
├── models/
│   ├── user_model.dart
│   ├── attendance_model.dart
│   └── company_model.dart
├── services/
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   ├── face_recognition_service.dart
│   └── location_service.dart
├── screens/
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── employee/
│   │   ├── employee_home_screen.dart
│   │   ├── face_register_screen.dart
│   │   ├── face_login_screen.dart
│   │   └── attendance_history_screen.dart
│   └── owner/
│       ├── owner_home_screen.dart
│       ├── company_settings_screen.dart
│       ├── employee_list_screen.dart
│       └── attendance_report_screen.dart
└── widgets/
    ├── custom_button.dart
    ├── custom_text_field.dart
    └── face_scanner_widget.dart

android/
├── app/
│   └── build.gradle (TFLite and camera dependencies)
└── ... (Firebase and Google services config)

assets/
├── models/
│   └── face_net_model.tflite (FaceNet model files)
└── images/
    └── app_logo.png
```

## Implementation Steps

### Step 1: Project Setup
- [ ] Create Flutter project
- [ ] Configure pubspec.yaml with dependencies
- [ ] Set up Firebase project
- [ ] Configure Android manifest

### Step 2: Core Services
- [ ] Implement Auth Service
- [ ] Implement Firestore Service
- [ ] Implement Location Service
- [ ] Implement Face Recognition Service

### Step 3: Models
- [ ] User Model
- [ ] Attendance Model
- [ ] Company Model

### Step 4: Authentication Screens
- [ ] Splash Screen
- [ ] Login Screen
- [ ] Register Screen

### Step 5: Employee Screens
- [ ] Employee Home
- [ ] Face Registration
- [ ] Face Login/Attendance
- [ ] Attendance History

### Step 6: Owner Screens
- [ ] Owner Home
- [ ] Company Settings
- [ ] Employee List
- [ ] Attendance Reports

## Dependencies (pubspec.yaml)

```
yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.13.0
  firebase_auth: ^5.5.2
  cloud_firestore: ^5.6.6
  firebase_storage: ^12.4.4
  google_mlkit_face_detection: ^0.12.0
  camera: ^0.11.1
  geolocator: ^13.0.2
  permission_handler: ^11.4.0
  image_picker: ^1.1.2
  path_provider: ^2.1.5
  tflite_flutter: ^0.11.0
  uuid: ^4.5.1
  intl: ^0.20.2
  provider: ^6.1.5
  shared_preferences: ^2.5.3
  flutter_local_notifications: ^19.2.1
```

## Firebase Setup Required
1. Create Firebase project
2. Enable Authentication (Email/Password)
3. Enable Cloud Firestore
4. Enable Firebase Storage
5. Add Android app and download google-services.json

## Important Notes
- Use Google ML Kit for face detection (free tier)
- Use TFLite for face recognition (offline)
- FaceNet model will be bundled in assets
- GPS radius typically set to 100-500 meters
- All features use free Firebase tier (no paid features)
