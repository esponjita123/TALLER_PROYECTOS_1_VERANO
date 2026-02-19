import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pantallas/pantalla_splash.dart';
import 'servicios/servicio_tema.dart';

class JobLinkApp extends StatelessWidget {
  const JobLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Wanka Trabajo',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
