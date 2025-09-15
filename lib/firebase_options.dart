// File: lib/firebase_options.dart
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
    apiKey: 'AIzaSyDV3oiEX5lcE_p94ZGifY5AcbKb1p-JqB4',
    appId: '1:210379975180:web:5d01c2101b2fba3b381c29',
    messagingSenderId: '210379975180',
    projectId: 'talentfind-42020',
    authDomain: 'talentfind-42020.firebaseapp.com',
    storageBucket: 'talentfind-42020.firebasestorage.app',
    measurementId: 'G-86VQKZ1LXS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: '210379975180',
    projectId: 'talentfind-42020',
    storageBucket: 'talentfind-42020.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: '210379975180',
    projectId: 'talentfind-42020',
    storageBucket: 'talentfind-42020.firebasestorage.app',
    iosBundleId: 'com.example.talentFind',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR_MACOS_API_KEY',
    appId: 'YOUR_MACOS_APP_ID',
    messagingSenderId: '210379975180',
    projectId: 'talentfind-42020',
    storageBucket: 'talentfind-42020.firebasestorage.app',
    iosBundleId: 'com.example.talentFind',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR_WINDOWS_API_KEY',
    appId: 'YOUR_WINDOWS_APP_ID',
    messagingSenderId: '210379975180',
    projectId: 'talentfind-42020',
    storageBucket: 'talentfind-42020.firebasestorage.app',
  );
}