import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      case TargetPlatform.windows:
        return windows;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDemoPlaceholderWebKeyForDevelopment',
    appId: '1:100000000000:web:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'asisten-keuangan-dev',
    authDomain: 'asisten-keuangan-dev.firebaseapp.com',
    storageBucket: 'asisten-keuangan-dev.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemoPlaceholderAndroidKeyForDevelopment',
    appId: '1:100000000000:android:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'asisten-keuangan-dev',
    storageBucket: 'asisten-keuangan-dev.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemoPlaceholderIosKeyForDevelopment',
    appId: '1:100000000000:ios:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'asisten-keuangan-dev',
    storageBucket: 'asisten-keuangan-dev.appspot.com',
    iosBundleId: 'com.novantho.asistenKeuangan',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDemoPlaceholderWindowsKeyForDevelopment',
    appId: '1:100000000000:web:abcdef1234567890',
    messagingSenderId: '100000000000',
    projectId: 'asisten-keuangan-dev',
    storageBucket: 'asisten-keuangan-dev.appspot.com',
  );
}
