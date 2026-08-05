# Volex — Release Build Guide (idiot-proof)

This builds an installable Android app of Volex. Two paths:

- **A. Quick release APK** — to install on your phone or share a file. Zero setup.
- **B. Play Store release** — a proper signed app bundle to upload to Google Play.

Everything runs in **PowerShell**, from the project folder:

```powershell
cd "C:\Users\User\Desktop\volex trade latest"
```

---

## A. Quick release APK (install / share)

You already ran the app in debug, so your machine has the standard Android
debug keystore. The project is set up to sign release builds with it
automatically — so you need **one command**.

```powershell
git pull origin claude/practical-turing-4sudw9
flutter build apk --release
```

When it finishes it prints a path. The file is here:

```
build\app\outputs\flutter-apk\app-release.apk
```

**Install it on your phone (USB connected):**
```powershell
flutter install --release
```
or copy `app-release.apk` to the phone and tap it (allow "install from this
source" if asked).

> First release build is slow (a few minutes). That's normal.

### Smaller, faster-download APKs (optional)
One APK per phone type instead of one big universal file:
```powershell
flutter build apk --release --split-per-abi
```
Most modern phones use `app-arm64-v8a-release.apk`.

---

## B. Play Store release (signed app bundle)

Google Play needs an **app bundle** (`.aab`) signed with **your own** key
(not the debug key). Do the keystore step **once**, then reuse it forever.

### 1. Create your signing key (one time)
```powershell
keytool -genkey -v -keystore "$env:USERPROFILE\volex-upload.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias volex
```
It asks for a password (twice) and some name/org details. **Write the password
down** — losing it means you can never update the app again.

### 2. Tell the project about the key (one time)
Create a file named `key.properties` inside the `android` folder
(`android\key.properties`) with these 4 lines (use YOUR password and path):
```
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=volex
storeFile=C:/Users/User/volex-upload.jks
```
> Use forward slashes `/` in `storeFile`. Never commit this file or the `.jks`
> to git (they're your private keys).

### 3. Build the bundle
```powershell
flutter build appbundle --release
```
Output:
```
build\app\outputs\bundle\release\app-release.aab
```
Upload that `.aab` at **play.google.com/console** → your app → Testing →
Internal testing → Create release.

---

## Before a PUBLIC store launch (not needed for testing)
These are tracked in `ROADMAP.md` under **M6**:
- Bump `version:` in `pubspec.yaml` for each release (e.g. `1.0.2+11`).
- Re-enable `minifyEnabled`/`shrinkResources` in `android/app/build.gradle`
  **and test the release APK still runs** (ProGuard can break Firebase).
- App icon, store screenshots, privacy policy, content rating.
- If you want real login / cloud sync, add a Firebase project's
  `google-services.json` to `android/app/` (the app runs fine without it).

---

## If a build fails
- `flutter doctor` — fix anything with a red ✗.
- `flutter clean; flutter pub get; flutter build apk --release` — clean rebuild.
- Licenses error: `flutter doctor --android-licenses` then type `y` to each.
- Paste the last ~20 lines of the error and ask for help.
