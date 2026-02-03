import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Inicialización general
  static Future<void> initialize(BuildContext context) async {
    // Permisos (Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Obtener token
    final token = await _messaging.getToken();
    final user = _auth.currentUser;

    if (token != null && user != null) {
      await _firestore.collection('usuarios').doc(user.uid).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        await _firestore.collection('usuarios').doc(currentUser.uid).update({
          'fcmToken': newToken,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });

    // App en primer plano
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalDialog(context, message);
    });

    // App en segundo plano (tap)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNavigation(context, message);
    });

    // App cerrada
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(context, initialMessage);
    }
  }

  /// Navegación desde notificación
  static void _handleNavigation(BuildContext context, RemoteMessage message) {
    final data = message.data;

    if (data['type'] == 'alerta_paquete') {
      Navigator.pushNamed(context, '/todos_paquetes');
    }
  }

  /// Mostrar alerta simple en foreground
  static void _showLocalDialog(BuildContext context, RemoteMessage message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(message.notification?.title ?? 'Alerta'),
        content: Text(message.notification?.body ?? ''),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
