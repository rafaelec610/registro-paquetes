import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

import 'firebase/fcm_background_handler.dart';
import 'services/fcm_service.dart';

// WEB
import 'web/web_login.dart';
import 'web/web_admin_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive (solo móvil, en web no se usa)
  if (!kIsWeb) {
    await Hive.initFlutter();
  }

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FCM solo móvil
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(
      firebaseMessagingBackgroundHandler,
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Registro de Paquetes',
      theme: AppTheme.lightTheme,
      home: kIsWeb ? const WebRoot() : const RootInitializer(),
    );
  }
}

/// ===============================
/// WEB ROOT
/// ===============================
class WebRoot extends StatelessWidget {
  const WebRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const WebLoginScreen();
        }
        return const WebAdminHome();
      },
    );
  }
}

/// ===============================
/// MOBILE ROOT
/// ===============================
class RootInitializer extends StatefulWidget {
  const RootInitializer({super.key});

  @override
  State<RootInitializer> createState() => _RootInitializerState();
}

class _RootInitializerState extends State<RootInitializer> {
  @override
  void initState() {
    super.initState();

    // Inicializar FCM solo móvil
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FCMService.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
