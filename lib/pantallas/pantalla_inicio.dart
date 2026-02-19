import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../datos/globales.dart';
import '../servicios/servicio_imagen.dart';
import '../servicios/servicio_chat.dart';
import '../servicios/servicio_tema.dart';
import 'pantalla_para_ti.dart';
import 'pantalla_empleos.dart';
import 'pantalla_agregar_empleo.dart';
import 'pantalla_editar_perfil.dart';
import 'pantalla_mis_aplicaciones.dart';
import 'pantalla_mis_publicaciones.dart';
import 'pantalla_login_moderna.dart';
import 'pantalla_conversaciones.dart';
import 'pantalla_mapa_empleos.dart';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors:
                    isDark
                        ? [
                          const Color(0xFF0A1628),
                          const Color(0xFF0D2137),
                          const Color(0xFF14304A),
                        ]
                        : [
                          const Color(0xFF0D47A1),
                          const Color(0xFF1976D2),
                          const Color(0xFF42A5F5),
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
                color: Colors.white.withOpacity(isDark ? 0.03 : 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.secondary.withOpacity(isDark ? 0.08 : 0.06),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header — FIXED: Expanded on name column prevents overflow
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '¡Hola!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withOpacity(0.75),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  loggedUser!.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildMenuButton(context),
                          const SizedBox(width: 8),
                          _buildChatButton(context),
                          const SizedBox(width: 8),
                          _buildProfileAvatar(context),
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
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(36),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                isDark ? 0.3 : 0.1,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explora tus opciones',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Featured: AI Recommendations
                              _buildGlassMorphismCard(context),

                              const SizedBox(height: 28),
                              Text(
                                'Panel Central',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(height: 14),

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
            width: 52,
            height: 52,
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
                              fontSize: 22,
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
            width: 13,
            height: 13,
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

  Widget _buildChatButton(BuildContext context) {
    return StreamBuilder<int>(
      stream:
          loggedUser != null
              ? ChatService.getUnreadCount(loggedUser!.email)
              : Stream.value(0),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConversationsScreen(),
                  ),
                );
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.25)),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            if (unreadCount > 0)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGlassMorphismCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 170,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(isDark ? 0.15 : 0.2),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors:
                      isDark
                          ? [const Color(0xFF2A1A4A), const Color(0xFF1A2A4A)]
                          : [Colors.indigo.shade800, Colors.purple.shade700],
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(color: Colors.white.withOpacity(0.05)),
              ),
            ),
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
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(
                                isDark ? 0.15 : 1.0,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'IA',
                              style: TextStyle(
                                color:
                                    isDark
                                        ? Colors.white
                                        : const Color(0xFF673AB7),
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
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
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Recomendaciones inteligentes para ti',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Buscar',
                icon: Icons.search_rounded,
                color: isDark ? const Color(0xFF42A5F5) : Colors.blue,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const JobsScreen()),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Publicar',
                icon: Icons.add_circle_outline_rounded,
                color: isDark ? const Color(0xFF66BB6A) : Colors.green,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddJobScreen()),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Postulaciones',
                icon: Icons.send_rounded,
                color: isDark ? const Color(0xFFFFB74D) : Colors.orange,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyApplicationsScreen(),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Publicaciones',
                icon: Icons.business_center_rounded,
                color: isDark ? const Color(0xFF7986CB) : Colors.indigo,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyPostsScreen()),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Mensajes',
                icon: Icons.chat_bubble_outline_rounded,
                color: isDark ? const Color(0xFFBA68C8) : Colors.purple,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConversationsScreen(),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Perfil',
                icon: Icons.person_outline_rounded,
                color: isDark ? const Color(0xFF4DB6AC) : Colors.teal,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildCompactActionCard(
                context,
                title: 'Mapa',
                icon: Icons.map_rounded,
                color: isDark ? const Color(0xFFE57373) : Colors.red,
                onTap:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MapaEmpleosScreen(),
                      ),
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Expanded(
                  child: _buildCompactActionCard(
                    context,
                    title: themeProvider.isDarkMode ? 'Claro' : 'Oscuro',
                    icon:
                        themeProvider.isDarkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                    color: isDark ? const Color(0xFF90A4AE) : Colors.blueGrey,
                    onTap: () => themeProvider.toggleTheme(),
                  ),
                );
              },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(22),
      elevation: isDark ? 0 : 1,
      shadowColor: color.withOpacity(0.1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.08),
              width: isDark ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment:
                fullWidth ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.15 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: fullWidth ? 16 : 10),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
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
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
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
