import 'package:flutter/material.dart';
import 'pantallas/pantalla_splash.dart';

class JobLinkApp extends StatelessWidget {
  const JobLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wanka Trabajo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SplashScreen(),
    );
  }
}
