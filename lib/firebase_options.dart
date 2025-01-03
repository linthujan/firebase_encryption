// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA_QKLka8aNp2-yiXOW9lfmgliQ4R9CoVY',
    appId: '1:1024501112009:web:a71c9f25ca41171f124118',
    messagingSenderId: '1024501112009',
    projectId: 'flutterfirebaseencryption',
    authDomain: 'flutterfirebaseencryption.firebaseapp.com',
    storageBucket: 'flutterfirebaseencryption.appspot.com',
    measurementId: 'G-1DJ6M1M55D',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB8Ukfkijx5d3r1iRcKczlKT7OG93vMcgI',
    appId: '1:1024501112009:android:ceb5f1363a732b08124118',
    messagingSenderId: '1024501112009',
    projectId: 'flutterfirebaseencryption',
    storageBucket: 'flutterfirebaseencryption.appspot.com',
  );
}
