## 📥 Download App

<a href="https://github.com/tharun-1605/attend_app_fluter/releases/download/v0.1/app-release.apk">
  <img src="https://img.shields.io/badge/Download-APK-green?style=for-the-badge&logo=android" />
</a>
# Attendance App

A robust, cross-platform attendance tracking application built with [Flutter](https://flutter.dev/). This application features location-based tracking, camera capabilities, and automated CI/CD for seamless Android APK releases.

## Features

* **Cross-Platform:** Supports Android, Web, Windows, and Linux.
* **Location Tracking:** Captures fine, coarse, and background location to ensure accurate, geo-fenced attendance logging.
* **Camera Integration:** Supports image capture for photo check-ins and identity verification.
* **Notifications:** Push notification support and boot-completed listening.
* **Automated Builds (CI/CD):** Configured with GitHub Actions to automatically build and publish an Android Release APK when a new version tag (`v*`) is pushed.

## Prerequisites

* Flutter SDK (Stable Channel)
* Android Studio (for Android builds and emulators)
* Java 17 (for Android compilation)

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone <your-repository-url>
   cd attend_app_fluter/attendance_app
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   # Run on an available emulator or connected device
   flutter run
   ```

## CI/CD Workflow (GitHub Actions)

This project uses GitHub Actions to automate the Android release process. 

To trigger a new automated APK build and GitHub Release:
1. Commit your code changes.
2. Create and push a new tag starting with `v` (e.g., `v1.0.0`):
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
3. The GitHub Action will automatically set up the environment, analyze the code, build the `app-release.apk`, and attach it to a new GitHub Release.

## Android Permissions Used

The app requests the following core permissions to function properly (see `AndroidManifest.xml`):
* **Location:** `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION`
* **Camera & Media:** `CAMERA`, `READ_MEDIA_IMAGES`
* **Storage:** `READ_EXTERNAL_STORAGE`, `WRITE_EXTERNAL_STORAGE`
* **System & Network:** `INTERNET`, `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`
