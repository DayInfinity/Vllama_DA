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

### 🔒 Locked Versions for Stability
I have locked the versions of several key libraries (like `path`, `http`, and `flutter_lints`) in `pubspec.yaml`. 

**Why?**
Your local environment uses Dart 3.0.3. Newer versions of these packages require Dart 3.4.0+, which causes "Version solving failed" errors. By locking these, we ensure the app builds "once and for all" on your current machine while still working perfectly in GitHub Actions.
