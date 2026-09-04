import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase options read from a `.env` file at runtime.
///
/// **Android does not use this.** `main.dart` calls the no-argument
/// `Firebase.initializeApp()` there, which reads the native
/// `google-services.json`; this class is only reached on iOS.
///
/// That matters because `dotenv.load()` is never called — it was removed so
/// the `.env` file would not be bundled onto the device — so every `!` below
/// would throw on a null. On iOS, wire `dotenv.load()` into `main()` before
/// Firebase init, or switch iOS to `GoogleService-Info.plist` and the
/// no-argument initializer the way Android already does. Firebase init in
/// `main.dart` is inside a try/catch, so today this fails to a Firebase-free
/// guest mode rather than a crash.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_ANDROID']!,
        appId: dotenv.env['FIREBASE_APP_ID_ANDROID']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: dotenv.env['FIREBASE_API_KEY_IOS']!,
        appId: dotenv.env['FIREBASE_APP_ID_IOS']!,
        messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
        projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
        iosBundleId: 'com.antigravity.volextrade',
      );
}
