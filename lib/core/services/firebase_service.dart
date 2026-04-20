import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:flutter/foundation.dart';
import 'package:app_prestaya_flutter/injection_container.dart';

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // 1. Inicializar Firebase (Requiere google-services.json en android/app)
    try {
      await Firebase.initializeApp();
      
      // 2. Solicitar permisos (iOS)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (kDebugMode) {
        print('User granted permission: ${settings.authorizationStatus}');
      }

      // 3. Obtener el Token (Este se debe enviar al backend)
      String? token = await _firebaseMessaging.getToken();
      if (kDebugMode) {
        print('FCM Token: $token');
      }

      // 4. Configurar notificaciones locales para Android
      const fln.AndroidInitializationSettings initializationSettingsAndroid = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
      const fln.InitializationSettings initializationSettings = fln.InitializationSettings(android: initializationSettingsAndroid);
      await sl<fln.FlutterLocalNotificationsPlugin>().initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (fln.NotificationResponse details) {
          // Manejar click en notificación
        },
      );

      // 5. Manejar mensajes en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (kDebugMode) {
          print('Got a message whilst in the foreground!');
          print('Message data: ${message.data}');
        }

        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('Error inicializando Firebase: $e');
      }
    }
  }

  static void _showLocalNotification(RemoteMessage message) {
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics = fln.AndroidNotificationDetails(
      'high_importance_channel', 
      'Notificaciones Importantes',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      showWhen: true,
    );
    const fln.NotificationDetails platformChannelSpecifics = fln.NotificationDetails(android: androidPlatformChannelSpecifics);
    
    sl<fln.FlutterLocalNotificationsPlugin>().show(
      id: message.hashCode,
      title: message.notification?.title ?? '',
      body: message.notification?.body ?? '',
      notificationDetails: platformChannelSpecifics,
    );
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
