import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'aplicacion.dart';
import 'servicios/servicio_recomendacion.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await RecommendationService.initialize();
  runApp(const JobLinkApp());
}
