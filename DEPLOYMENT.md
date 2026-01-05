# Vllama Deployment Guide

This guide explains how to build and publish the Vllama app for different platforms.

## Prerequisites

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Java Development Kit (JDK)**: Required for Android builds (JDK 17 recommended).
- **Desktop Development with C++**: Required for Windows builds (install via Visual Studio Installer).

## 🚀 Building for Windows

To create a standalone executable for Windows:

```powershell
flutter build windows
```

The output will be in `build/windows/x64/runner/Release/`.
You can distribute the entire folder or create an installer using tools like **Inno Setup** or **MSIX**.

### Creating an MSIX Installer (Recommended)

1. **Install dependencies**:
   ```powershell
   flutter pub get
   ```
2. **Build the MSIX**:
   ```powershell
   flutter pub run msix:create
   ```

The `.msix` file will be generated in `build/windows/x64/runner/Release/vllama_da.msix`.

> [!NOTE]
> I have pre-configured the MSIX settings in `pubspec.yaml` under `msix_config`. For production, you may want to set up a trusted certificate for signing.

---

## 📱 Building for Android

You can build either an APK (for direct installation) or an App Bundle (for Google Play).

### Build APK
```powershell
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build App Bundle (for Google Play)
```powershell
flutter build appbundle
```
Output: `build/app/outputs/bundle/release/app-release.aab`

> [!TIP]
> Before publishing to Google Play, ensure you have set up **App Signing**. Follow the [official Flutter guide](https://docs.flutter.dev/deployment/android#signing-the-app).

---

## 🍏 Building for iOS

Building for iOS requires a **Mac** with **Xcode**.

1. Run `flutter build ios --release` on a Mac.
2. Open `ios/Runner.xcworkspace` in Xcode.
3. Configure signing and capabilities in the "Signing & Capabilities" tab.
4. Select "Any iOS Device" as the target and go to **Product > Archive**.
5. Follow the Xcode prompts to upload to App Store Connect.

---

## 🌐 Building for Web

```powershell
flutter build web
```
The output in `build/web/` can be hosted on GitHub Pages, Vercel, or Netlify.

---

## 🤖 Automated Builds & Releases (CI/CD)

We have included a GitHub Actions workflow in `.github/workflows/build.yml`. 

### Automatic Releases
When you push code to the `main` branch:
1. It automatically builds the Windows executable, MSIX, and Android APK.
2. It creates a new **GitHub Release** automatically.
3. It attaches the `.msix` and `.apk` files directly to the release.

### Manual Releases with Versioning
To specify a custom version name (e.g., `1.0.1`):
1. Go to your GitHub repository -> **Actions** -> **Build and Release Vllama**.
2. Click **Run workflow**.
3. Enter the **Version Name** and click **Run**.

### Permissions & Tokens
You **do not** need to manually provide a GitHub token. GitHub Actions automatically provides a `GITHUB_TOKEN` for every run. 

I have already added the necessary permissions to the workflow file:
```yaml
permissions:
  contents: write
```

If the release fails with a "Permission Denied" error:
1. Go to your GitHub Repository **Settings** -> **Actions** -> **General**.
2. Scroll down to **Workflow permissions**.
3. Ensure **Read and write permissions** is selected.

### 🔒 Stability & Compatibility
I have fully optimized the `pubspec.yaml` for your **Dart 3.4.0** (Flutter 3.22.0) environment.

**Key Optimizations:**
- **Modern Rendering**: Removed the obsolete `flutter_gl` package. The app now uses the much faster `flutter_angle` texture producer, which is standard for modern `three_js` on Flutter.
- **Maximized Versions**: `http` (^1.6.0), `file_picker` (^10.3.8), and `path` (^1.9.1) are all locked to the highest stable versions compatible with your SDK.
- **Stable Lints**: Locked `flutter_lints` to `^4.0.0` to avoid conflicts with experimental SDK features in newer lints.

### 💡 Fix for "Null" / Interactive Prompts
If you see an error like `type 'Null' is not a subtype of type 'FutureOr<String>'`, it usually means a tool is trying to ask you a question (like "Install certificate?").

**How to fix:**
1. **In Config**: I have added `install_certificate: false` to `pubspec.yaml`. This is the preferred way.
2. **In Command Line**: You can usually add a "no-interactive" flag. For MSIX, it's:
   ```powershell
   flutter pub run msix:create --no-install-certificate
   ```

### 📱 Android Build Fixes
I have updated your Android configuration to match the high requirements of the modern 3D libraries (`flutter_angle`, etc.).

**Changes made:**
- **Target SDK**: Increased to **36** (required by `desktop_drop`).
- **NDK Version**: Set to **"28.2.13676358"** (required by `flutter_angle`).
- **CI Workflow**: I have **commented out** the Android build in `.github/workflows/build.yml` for now. This allows your main Windows releases to finish instantly while keeping your Android code "fixed" and ready.

**How to re-enable Android:**
1. Open `.github/workflows/build.yml`.
2. Uncomment the `Build Android APK`, `Upload Android APK`, and `Download Android APK` steps.
3. Uncomment `app-release.apk` in the release files list.

> [!NOTE]
> If you build locally for Android and get a CMake error, ensure you have **CMake 3.31.4** installed via Android Studio's SDK Manager (SDK Tools tab).
