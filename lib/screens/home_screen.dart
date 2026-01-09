import 'package:flutter/material.dart';
import '../data/fake_db.dart';
import 'jobs_screen.dart';
import 'add_job_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bienvenido ${loggedUser!.name}")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Ver empleos"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JobsScreen()),
                );
              },
            ),
            if (loggedUser!.role == "empresa")
              ElevatedButton(
                child: const Text("Publicar empleo"),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AddJobScreen()),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
