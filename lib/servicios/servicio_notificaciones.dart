import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio para manejar notificaciones push
class NotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  static bool _isInitialized = false;
  static Function(RemoteMessage)? _onMessageOpenedApp;

  /// Inicializa el servicio de notificaciones
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Solicitar permisos
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('🔔 Permiso de notificaciones: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Configurar notificaciones locales
        await _initializeLocalNotifications();
        
        // Configurar handlers de FCM
        _configureFCMHandlers();
        
        // Obtener token FCM
        final token = await _firebaseMessaging.getToken();
        print('📱 FCM Token: $token');
        
        _isInitialized = true;
      }
    } catch (e) {
      print('❌ Error al inicializar notificaciones: $e');
    }
  }

  /// Configura notificaciones locales
  static Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar tap en notificación local
        print('📲 Notificación local tocada: ${details.payload}');
      },
    );
  }

  /// Configura los handlers de Firebase Cloud Messaging
  static void _configureFCMHandlers() {
    // Mensaje recibido en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Mensaje recibido en primer plano:');
      print('   Título: ${message.notification?.title}');
      print('   Cuerpo: ${message.notification?.body}');
      print('   Datos: ${message.data}');

      // Mostrar notificación local
      _showLocalNotification(message);
    });

    // Mensaje abierto desde notificación (app en background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 App abierta desde notificación:');
      print('   Datos: ${message.data}');
      
      _onMessageOpenedApp?.call(message);
    });

    // Obtener mensaje que abrió la app (app cerrada)
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('📲 App abierta desde notificación (cerrada):');
        print('   Datos: ${message.data}');
        
        _onMessageOpenedApp?.call(message);
      }
    });
  }

  /// Muestra una notificación local
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'chat_channel',
      'Mensajes de Chat',
      channelDescription: 'Notificaciones de mensajes nuevos',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  /// Muestra una notificación local manualmente
  static Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'general_channel',
      'Notificaciones Generales',
      channelDescription: 'Notificaciones de la app',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: payload != null ? jsonEncode(payload) : null,
    );
  }

  /// Obtiene el token FCM actual
  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }

  /// Suscribe a un tema
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
    print('✅ Suscrito al tema: $topic');
  }

  /// Cancela suscripción a un tema
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
    print('✅ Desuscrito del tema: $topic');
  }

  /// Configura el callback cuando se abre la app desde una notificación
  static void setOnMessageOpenedAppCallback(Function(RemoteMessage) callback) {
    _onMessageOpenedApp = callback;
  }

  /// Actualiza el badge de notificaciones (solo iOS)
  static Future<void> setBadge(int count) async {
    // En Android esto no hace nada, en iOS actualiza el badge
    await _localNotifications.show(
      0,
      null,
      null,
      const NotificationDetails(
        iOS: DarwinNotificationDetails(badgeNumber: 0),
      ),
    );
  }

  /// Guarda el token FCM del usuario en Firestore
  static Future<void> saveTokenToFirestore(String userEmail) async {
    try {
      final token = await getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('wanka_users')
            .doc(userEmail)
            .update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': DateTime.now().toIso8601String(),
        });
        print('✅ Token FCM guardado para $userEmail');
      }
    } catch (e) {
      print('❌ Error al guardar token FCM: $e');
    }
  }

  /// Escucha cambios de token y los actualiza
  static void listenToTokenRefresh(String userEmail) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) async {
      print('🔄 Token FCM actualizado');
      await saveTokenToFirestore(userEmail);
    });
  }
}

/// Extension para manejar mensajes en background
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('📩 Mensaje recibido en background:');
  print('   Título: ${message.notification?.title}');
  print('   Cuerpo: ${message.notification?.body}');
  print('   Datos: ${message.data}');
  
  // Aquí puedes hacer procesamiento en background
  // como guardar en base de datos local
}
