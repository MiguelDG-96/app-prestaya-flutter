import 'package:app_prestaya_flutter/injection_container.dart' as di;
import 'package:app_prestaya_flutter/main.dart';
import 'package:app_prestaya_flutter/features/clients/presentation/pages/client_detail_page.dart';
import 'package:app_prestaya_flutter/features/clients/domain/repositories/client_repository.dart';
import 'package:app_prestaya_flutter/features/rentals/presentation/pages/rental_detail_page.dart';
import 'package:app_prestaya_flutter/features/rentals/domain/repositories/rentals_repository.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as fln;
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);

      const fln.AndroidNotificationChannel channel = fln.AndroidNotificationChannel(
        'high_importance_channel',
        'Notificaciones Importantes',
        description: 'Canal para alertas críticas y pagos.',
        importance: fln.Importance.max,
        playSound: true,
      );

      // Usamos dynamic para evitar el error de argumentos posicionales del compilador
      final dynamic notificationsPlugin = di.sl<fln.FlutterLocalNotificationsPlugin>();

      await notificationsPlugin
          .resolvePlatformSpecificImplementation<fln.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      const fln.AndroidInitializationSettings initializationSettingsAndroid = fln.AndroidInitializationSettings('@mipmap/ic_launcher');
      const fln.InitializationSettings initializationSettings = fln.InitializationSettings(android: initializationSettingsAndroid);
      
      await notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (fln.NotificationResponse details) async {
          if (details.payload != null) {
            final payload = details.payload!;
            
            if (payload.startsWith('CLIENT:')) {
              final clientId = payload.replaceFirst('CLIENT:', '');
              final repo = di.sl<ClientRepository>();
              final result = await repo.getClients();
              result.fold((_) => null, (clients) {
                try {
                  final client = clients.firstWhere((c) => c.id == clientId);
                  navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => ClientDetailPage(client: client)));
                } catch (_) {}
              });
            } else if (payload.startsWith('RENTAL:')) {
              final rentalId = payload.replaceFirst('RENTAL:', '');
              final repo = di.sl<RentalsRepository>();
              final result = await repo.getRentals();
              result.fold((_) => null, (rentals) {
                try {
                  final rental = rentals.firstWhere((r) => r.id == rentalId);
                  navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => RentalDetailPage(rental: rental)));
                } catch (_) {}
              });
            }
          }
        },
      );

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          showInstantNotification(
            title: message.notification?.title ?? "Aviso",
            body: message.notification?.body ?? "",
          );
        }
      });
      
    } catch (e) {
      if (kDebugMode) print('Error Firebase: $e');
    }
  }

  static void showInstantNotification({required String title, required String body, String? payload}) async {
    const fln.AndroidNotificationDetails androidPlatformChannelSpecifics = fln.AndroidNotificationDetails(
      'high_importance_channel', 
      'Avisos de Cobro',
      importance: fln.Importance.max,
      priority: fln.Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
    );
    
    const fln.NotificationDetails platformChannelSpecifics = fln.NotificationDetails(android: androidPlatformChannelSpecifics);
    
    final dynamic notificationsPlugin = di.sl<fln.FlutterLocalNotificationsPlugin>();
    
    await notificationsPlugin.show(
      payload.hashCode, 
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
