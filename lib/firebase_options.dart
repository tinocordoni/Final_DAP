import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// Identificadores de las apps registradas en Firebase. Las reglas de Firestore
// y la sesión del usuario determinan quién puede acceder a los libros.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => throw UnsupportedError('Usá Android, iOS o Chrome.'),
    };
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyAB--ULqL3LYLjrOBC-3uZ2Bmue720en4o',
    appId: '1:566848830131:web:62d4e3aeac0345067bcec6',
    messagingSenderId: '566848830131',
    projectId: 'final-dap',
    authDomain: 'final-dap.firebaseapp.com',
    storageBucket: 'final-dap.firebasestorage.app',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyCkAGTTM9eWnELdfhcKdJV7ymNHzATRGm8',
    appId: '1:566848830131:android:ccc001dfc81483757bcec6',
    messagingSenderId: '566848830131',
    projectId: 'final-dap',
    storageBucket: 'final-dap.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyApIdL4NV3wNHd2HRteb_83mAb8W0oVX_4',
    appId: '1:566848830131:ios:fdecaec36971599d7bcec6',
    messagingSenderId: '566848830131',
    projectId: 'final-dap',
    storageBucket: 'final-dap.firebasestorage.app',
    iosBundleId: 'ar.edu.ort.finalDap',
  );
}
