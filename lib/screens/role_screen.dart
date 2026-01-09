import 'package:flutter/material.dart';
import 'login_screen.dart';

class RoleScreen extends StatelessWidget {
  const RoleScreen({super.key});

  // 👉 Aquí pon la URL de tu imagen de fondo
  final String backgroundUrl =
      "https://diariocorreo.pe/resizer/8956GdxZgFJvecACOjx1b_8Uywo=/1200x1200/smart/filters:format(jpeg):quality(75)/arc-anglerfish-arc2-prod-elcomercio.s3.amazonaws.com/public/LRSDAU2R6JHXVIII3VFGLBCC5Q.jpg";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Imagen de fondo
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(backgroundUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔹 Capa oscura para que el texto se lea bien
          Container(color: Colors.black.withOpacity(0.5)),

          // 🔹 Contenido
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "WancaTrabaja",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300, // Más elegante que bold
                      fontStyle: FontStyle.italic, // Toque profesional
                      letterSpacing: 2, // Espaciado entre letras
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2),
                          blurRadius: 6,
                          color: Color.fromARGB(137, 255, 254, 254),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    "Intermediación laboral inclusiva",
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    "¿Qué deseas hacer?",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text("BUSCAR EMPLEO"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(role: "postulante"),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.business_center),
                      label: const Text("PUBLICAR EMPLEO"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        textStyle: const TextStyle(fontSize: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LoginScreen(role: "empresa"),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
