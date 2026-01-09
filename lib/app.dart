import 'package:flutter/material.dart';
import 'screens/role_screen.dart';

class JobLinkApp extends StatelessWidget {
  const JobLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'JobLink',
      home: RoleScreen(),
    );
  }
}
