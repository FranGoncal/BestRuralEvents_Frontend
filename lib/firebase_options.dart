import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static String _env(String key) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception('Missing env var: $key');
    }
    return value;
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: _env('FIREBASE_API_KEY'),
    appId: _env('FIREBASE_APP_ID_WEB'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    authDomain: _env('FIREBASE_AUTH_DOMAIN'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
    measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: _env('FIREBASE_API_KEY'),
    appId: _env('FIREBASE_APP_ID_ANDROID'),
    messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
    projectId: _env('FIREBASE_PROJECT_ID'),
    storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
  );
}