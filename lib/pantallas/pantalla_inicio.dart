import 'dart:ui';
import 'package:flutter/material.dart';
import '../datos/globales.dart';
import '../servicios/servicio_imagen.dart';
import 'pantalla_para_ti.dart';
import 'pantalla_empleos.dart';
import 'pantalla_agregar_empleo.dart';
import 'pantalla_editar_perfil.dart';
import 'pantalla_mis_aplicaciones.dart';
import 'pantalla_mis_publicaciones.dart';
import 'pantalla_login_moderna.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0D47A1), // Blue 900
                  const Color(0xFF1976D2), // Blue 700
                  const Color(0xFF42A5F5), // Blue 400
                ],
              ),
            ),
          ),

          // Decorative elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '¡Hola!',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                loggedUser!.name,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -1,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              _buildMenuButton(context),
                              const SizedBox(width: 12),
                              _buildProfileAvatar(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content Area
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(40),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 20,
                              offset: Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Explora tus opciones',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Featured: AI Recommendations
                              _buildGlassMorphismCard(context),

                              const SizedBox(height: 32),
                              const Text(
                                'Panel Central',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3949AB),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Action Cards
                              _buildActionGrid(context),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            );
          },
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child:
                  loggedUser!.profileImagePath.isNotEmpty &&
                          ImageService.isBase64(loggedUser!.profileImagePath)
                      ? Image.memory(
                        ImageService.base64ToImage(
                          loggedUser!.profileImagePath,
                        ),
                        fit: BoxFit.cover,
                      )
                      : Container(
                        color: Colors.white,
                        child: Center(
                          child: Text(
                            loggedUser!.name[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ),
                      ),
            ),
          ),
        ),
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.greenAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassMorphismCard(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Stack(
          children: [
            // Background Image/Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo.shade800, Colors.purple.shade700],
                ),
              ),
            ),
            // Glass effect overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(color: Colors.white.withOpacity(0.05)),
              ),
            ),
            // Content
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ForYouScreen()),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'INTELIGENCIA ARTIFICIAL',
                              style: TextStyle(
                                color: Color(0xFF673AB7),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const Text(
                        'Match Perfecto',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'Recomendaciones inteligentes hoy',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionGrid(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Buscar',
                icon: Icons.search_rounded,
                color: Colors.blue,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JobsScreen()),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Publicar',
                icon: Icons.add_circle_outline_rounded,
                color: Colors.green,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddJobScreen()),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Postulaciones',
                icon: Icons.send_rounded,
                color: Colors.orange,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyApplicationsScreen(),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Publicaciones',
                icon: Icons.business_center_rounded,
                color: Colors.indigo,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactActionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    bool fullWidth = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withOpacity(0.1), width: 1),
          ),
          child: Row(
            mainAxisAlignment:
                fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: fullWidth ? 20 : 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.blueGrey.shade900,
                ),
              ),
              if (fullWidth) const Spacer(),
              if (fullWidth)
                Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, color: Colors.white),
      ),
      onSelected: (value) async {
        if (value == 'profile') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          );
        } else if (value == 'postulaciones') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyApplicationsScreen()),
          );
        } else if (value == 'publicaciones') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyPostsScreen()),
          );
        } else if (value == 'logout') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('user_email');
          loggedUser = null;
          if (context.mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const ModernLoginScreen()),
              (route) => false,
            );
          }
        }
      },
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Text('Mi Perfil'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'postulaciones',
              child: Row(
                children: [
                  Icon(Icons.send_rounded, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('Mis Postulaciones'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'publicaciones',
              child: Row(
                children: [
                  Icon(Icons.business_center_rounded, color: Colors.indigo),
                  SizedBox(width: 12),
                  Text('Mis Publicaciones'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout_rounded, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Cerrar Sesión'),
                ],
              ),
            ),
          ],
    );
  }
}
