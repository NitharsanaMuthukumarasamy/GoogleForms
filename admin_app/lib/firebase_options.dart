// File generated for FlutterFire configuration.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB3t5wbyVme6V4eVVPA4ykdp3jWe6f6Dk4',
    appId: '1:545670362177:web:7541edff20741f498382c0',
    messagingSenderId: '545670362177',
    projectId: 'alumni-feedback-5b0e1',
    authDomain: 'alumni-feedback-5b0e1.firebaseapp.com',
    storageBucket: 'alumni-feedback-5b0e1.firebasestorage.app',
    measurementId: 'G-PVN7P5Z4NS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC3FskVYrhg3c31-mKUqu8L93A7NUwbju8',
    appId: '1:545670362177:android:4e7423474118d2608382c0',
    messagingSenderId: '545670362177',
    projectId: 'alumni-feedback-5b0e1',
    storageBucket: 'alumni-feedback-5b0e1.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC3FskVYrhg3c31-mKUqu8L93A7NUwbju8',
    appId: '1:545670362177:ios:4e7423474118d2608382c0',
    messagingSenderId: '545670362177',
    projectId: 'alumni-feedback-5b0e1',
    storageBucket: 'alumni-feedback-5b0e1.firebasestorage.app',
    iosBundleId: 'com.college.alumnifeedback.admin',
  );
}
