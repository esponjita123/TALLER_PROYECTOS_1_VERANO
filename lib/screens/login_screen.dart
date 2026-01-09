import 'package:flutter/material.dart';
import '../data/fake_db.dart';
import 'register_screen.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  final String role;

  LoginScreen({required this.role, super.key});

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // -------------------- Elegir imagen según rol --------------------
    final String backgroundUrl =
        role == "empresa"
            ? "https://images.unsplash.com/photo-1556740749-887f6717d7e4?fit=crop&w=800&q=80" // imagen para empresa
            : "https://images.unsplash.com/photo-1522202176988-66273c2fd55f?fit=crop&w=800&q=80"; // imagen para postulante

    final Color mainColor =
        role == "empresa" ? Colors.blueAccent : Colors.green;

    return Scaffold(
      body: Stack(
        children: [
          // -------------------- Imagen de fondo --------------------
          SizedBox.expand(
            child: Image.network(backgroundUrl, fit: BoxFit.cover),
          ),

          // -------------------- Filtro semi-transparente --------------------
          Container(color: Colors.black.withOpacity(0.4)),

          // -------------------- Contenido --------------------
          Center(
            child: SingleChildScrollView(
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      role == "empresa"
                          ? "Acceso para Empresas"
                          : "Acceso para Postulantes",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Ingresa tus datos para continuar",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 30),
                    TextField(
                      controller: emailCtrl,
                      decoration: InputDecoration(
                        labelText: "Correo electrónico",
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: passCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: "Contraseña",
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "INGRESAR",
                          style: TextStyle(
                            fontSize: 16,
                            letterSpacing: 1,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () {
                          for (var u in users) {
                            if (u.email == emailCtrl.text &&
                                u.password == passCtrl.text &&
                                u.role == role) {
                              loggedUser = u;
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                              );
                              return;
                            }
                          }

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Usuario o contraseña incorrectos"),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextButton(
                      child: const Text("¿No tienes cuenta? Regístrate"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RegisterScreen(role: role),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
