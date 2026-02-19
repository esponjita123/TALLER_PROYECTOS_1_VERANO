import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'aplicacion.dart';
import 'servicios/servicio_recomendacion.dart';
import 'servicios/servicio_notificaciones.dart';
import 'servicios/servicio_tema.dart';
import 'utilidades/seed_data.dart'; // ← TEMPORAL: quitar después de insertar

// Handler para mensajes en background
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📩 Background message: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Configurar handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Inicializar servicios
  await RecommendationService.initialize();
  await NotificationService.initialize();

  // ⚠️ TEMPORAL: Descomentar para insertar datos, luego volver a comentar
  //await SeedData.insertSampleJobs();//

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const JobLinkApp(),
    ),
  );
}
