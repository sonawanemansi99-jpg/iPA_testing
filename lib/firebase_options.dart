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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyAL_bIuP8lgGqKEnirVp8q2Yhnz2-7Qib4',
    appId: '1:114101119019:web:18ea7deb5b1b6996dfe26e',
    messagingSenderId: '114101119019',
    projectId: 'corporator-app-f245a',
    authDomain: 'corporator-app-f245a.firebaseapp.com',
    storageBucket: 'corporator-app-f245a.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCsUjCmIyM4WXshF8Cka9ewlAr9kBg4Kw0',
    appId: '1:114101119019:android:8a0542304b6fed0fdfe26e',
    messagingSenderId: '114101119019',
    projectId: 'corporator-app-f245a',
    storageBucket: 'corporator-app-f245a.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBJIg2XzIf6CNKEbKjGxdVY09Ei71l585U',
    appId: '1:114101119019:ios:d0ac948ed18dffccdfe26e',
    messagingSenderId: '114101119019',
    projectId: 'corporator-app-f245a',
    storageBucket: 'corporator-app-f245a.firebasestorage.app',
    iosBundleId: 'com.example.corporatorApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBJIg2XzIf6CNKEbKjGxdVY09Ei71l585U',
    appId: '1:114101119019:ios:d0ac948ed18dffccdfe26e',
    messagingSenderId: '114101119019',
    projectId: 'corporator-app-f245a',
    storageBucket: 'corporator-app-f245a.firebasestorage.app',
    iosBundleId: 'com.example.corporatorApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAL_bIuP8lgGqKEnirVp8q2Yhnz2-7Qib4',
    appId: '1:114101119019:web:8c7ff5968ebf51e3dfe26e',
    messagingSenderId: '114101119019',
    projectId: 'corporator-app-f245a',
    authDomain: 'corporator-app-f245a.firebaseapp.com',
    storageBucket: 'corporator-app-f245a.firebasestorage.app',
  );
}
