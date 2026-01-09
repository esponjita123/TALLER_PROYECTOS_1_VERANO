import 'package:flutter/material.dart';
import '../data/fake_db.dart';
import 'jobs_screen.dart';
import 'add_job_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isPostulante = loggedUser!.role == "postulante";
    final Color mainColor = isPostulante ? Colors.green : Colors.blueAccent;

    // Widgets comunes
    Widget buildAvatar() {
      return CircleAvatar(
        radius: 50,
        backgroundColor: mainColor,
        child: Text(
          loggedUser!.name[0].toUpperCase(),
          style: const TextStyle(
            fontSize: 40,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    Widget buildGreeting() {
      return Column(
        children: [
          Text(
            "Hola, ${loggedUser!.name}",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isPostulante
                ? "Encuentra las mejores oportunidades de empleo cerca de ti"
                : "Gestiona tus ofertas de empleo",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ],
      );
    }

    Widget buildButton(
      String text,
      IconData icon,
      VoidCallback onPressed, {
      bool outlined = false,
    }) {
      if (outlined) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: Icon(icon, size: 28, color: mainColor),
            label: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: mainColor,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: mainColor, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: onPressed,
          ),
        );
      } else {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(icon, size: 28),
            label: Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: mainColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 5,
              shadowColor: Colors.black45,
            ),
            onPressed: onPressed,
          ),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Bienvenido, ${loggedUser!.name}"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: mainColor,
      ),
      backgroundColor: Colors.grey[100],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildAvatar(),
            const SizedBox(height: 20),
            buildGreeting(),
            const SizedBox(height: 40),

            if (isPostulante) ...[
              buildButton("Ver Empleos", Icons.work, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JobsScreen()),
                );
              }),
              const SizedBox(height: 20),
              buildButton("Mi Perfil", Icons.person, () {
                // Navegar a perfil
              }, outlined: true),
            ] else ...[
              buildButton("Publicar Empleo", Icons.add_box, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => AddJobScreen()),
                );
              }),
              const SizedBox(height: 20),
              buildButton("Mi Perfil", Icons.person, () {
                // Navegar a perfil
              }, outlined: true),
            ],
          ],
        ),
      ),
    );
  }
}
