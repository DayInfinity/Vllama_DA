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

## 🤖 Automated Builds (CI/CD)

We have included a GitHub Actions workflow in `.github/workflows/build.yml`. 
When you push code to GitHub:
1. It automatically builds the Windows and Android versions.
2. It uploads them as **Artifacts** in the GitHub "Actions" tab.

To use this, simply push your repository to GitHub!
