import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/modelo_empleo.dart';
// import '../modelos/modelo_usuario.dart'; // Linter says unused, implied by globales?
import '../modelos/modelo_chat.dart';
import '../servicios/servicio_imagen.dart';
import '../servicios/servicio_chat.dart';
import '../servicios/servicio_recomendacion.dart';
import '../utilidades/normalizador_datos.dart';
import '../datos/globales.dart';
import 'pantalla_chat_detalle.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _gaugeController;

  @override
  void initState() {
    super.initState();
    _gaugeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _gaugeController.dispose();
    super.dispose();
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri uri = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se puede abrir la aplicación de teléfono'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al llamar: $e')));
      }
    }
  }

  Future<void> _launchWhatsApp(
    BuildContext context,
    String phone,
    String message,
  ) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.startsWith('9') && cleanPhone.length == 9) {
      cleanPhone = '51$cleanPhone';
    }
    final Uri uri = Uri.parse(
      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se puede abrir WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al abrir WhatsApp: $e')));
      }
    }
  }

  Future<void> _applyToJob(BuildContext context) async {
    if (loggedUser == null) return;

    if (loggedUser!.email == widget.job.employerEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No puedes postular a tu propio empleo'),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final msgCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Postular al empleo'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('¿Deseas enviar tu perfil a ${widget.job.company}?'),
                const SizedBox(height: 16),
                TextField(
                  controller: msgCtrl,
                  decoration: InputDecoration(
                    labelText: 'Mensaje opcional',
                    hintText: 'Hola, me interesa este puesto...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Enviar Postulación'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        final applicationData = {
          'jobId': widget.job.id,
          'jobTitle': widget.job.title,
          'applicantEmail': loggedUser!.email,
          'applicantName': loggedUser!.name,
          'employerEmail': widget.job.employerEmail,
          'status': 'Enviado',
          'message': msgCtrl.text,
          'date': DateTime.now().toIso8601String(),
        };

        await FirebaseFirestore.instance
            .collection('wanka_applications')
            .add(applicationData);

        final conversation = await ChatService.createOrGetConversation(
          jobId: widget.job.id!,
          jobTitle: widget.job.title,
          employerEmail: widget.job.employerEmail,
          employerName: widget.job.company,
          applicantEmail: loggedUser!.email,
          applicantName: loggedUser!.name,
        );

        if (msgCtrl.text.isNotEmpty && conversation.id != null) {
          await ChatService.sendMessage(
            conversationId: conversation.id!,
            message: ChatMessage(
              jobId: widget.job.id!,
              senderEmail: loggedUser!.email,
              senderName: loggedUser!.name,
              receiverEmail: widget.job.employerEmail,
              content: msgCtrl.text,
            ),
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('¡Postulación enviada exitosamente!'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'CHAT',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => ChatDetailScreen(conversation: conversation),
                    ),
                  );
                },
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al postular: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFCE93D8) : Colors.purple.shade700;

    final scoreColor = _getScoreColor(widget.job.matchScore);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image Header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.job.imagePath.isNotEmpty &&
                      ImageService.isBase64(widget.job.imagePath))
                    Image.memory(
                      ImageService.base64ToImage(widget.job.imagePath),
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [accent.withValues(alpha: 0.8), cs.primary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.work_outline,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                widget.job.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                ),
              ),
              centerTitle: false,
            ),
            backgroundColor: cs.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Company & Score Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.job.company,
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    color: cs.error,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      widget.job.location,
                                      style: TextStyle(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // Date Posted
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    color: Colors.grey,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Publicado hace ${DateTime.now().difference(widget.job.postedDate).inDays} días',
                                    style: TextStyle(
                                      color: cs.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Circular Gauge
                        if (loggedUser != null)
                          _buildCircularGauge(
                            widget.job.matchScore,
                            scoreColor,
                            64,
                            isDark,
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Salary Badge
                    if (widget.job.salaryMin > 0 || widget.job.salaryMax > 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.attach_money,
                              color: Colors.green,
                              size: 28,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'S/ ${widget.job.salaryMin.toStringAsFixed(0)} - S/ ${widget.job.salaryMax.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color:
                                    isDark
                                        ? Colors.greenAccent
                                        : Colors.green.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (loggedUser != null) ...[
                      const SizedBox(height: 24),
                      // Match Explanation
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? cs.surfaceContainerHighest
                                  : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.auto_awesome,
                                  color: accent,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Análisis de Compatibilidad',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              RecommendationService.getMatchExplanation(
                                widget.job,
                                loggedUser!,
                              ),
                              style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.8),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      // Skills
                      Text(
                        'Habilidades Requeridas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._getMatchedSkills(
                            widget.job,
                          ).map((s) => _buildSkillChip(s, true, isDark)),
                          ..._getMissingSkills(
                            widget.job,
                          ).map((s) => _buildSkillChip(s, false, isDark)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Description
                    Text(
                      'Descripción del puesto',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.job.description,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: cs.onSurface.withValues(alpha: 0.8),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: () => _applyToJob(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.send_rounded),
                        label: const Text(
                          'POSTULAR AHORA',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact
                    Center(
                      child: Text(
                        'O contáctalos directamente:',
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                () => _launchPhone(context, widget.job.phone),
                            icon: const Icon(Icons.phone),
                            label: const Text('LLAMAR'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: cs.primary),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                () => _launchWhatsApp(
                                  context,
                                  widget.job.phone,
                                  'Hola, estoy interesado en el puesto de ${widget.job.title}',
                                ),
                            icon: const Icon(Icons.chat_bubble_outline),
                            label: const Text('WHATSAPP'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Colors.green),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularGauge(
    double score,
    Color color,
    double size,
    bool isDark,
  ) {
    return AnimatedBuilder(
      animation: _gaugeController,
      builder: (context, _) {
        final animatedScore = score * _gaugeController.value;
        return Column(
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _CircularGaugePainter(
                  score: animatedScore / 100,
                  color: color,
                  bgColor: color.withValues(alpha: 0.15),
                  strokeWidth: size * 0.1,
                ),
                child: Center(
                  child: Text(
                    '${animatedScore.toInt()}%',
                    style: TextStyle(
                      fontSize: size * 0.25,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Compatible',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSkillChip(String skill, bool isMatch, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color:
            isMatch
                ? (isDark
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.1))
                : (isDark
                    ? Colors.grey.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isMatch
                  ? (isDark
                      ? Colors.greenAccent.withValues(alpha: 0.5)
                      : Colors.green.withValues(alpha: 0.5))
                  : (isDark
                      ? Colors.grey.withValues(alpha: 0.4)
                      : Colors.grey.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMatch ? Icons.check_circle : Icons.circle_outlined,
            size: 14,
            color:
                isMatch
                    ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                    : (isDark ? Colors.grey : Colors.grey.shade600),
          ),
          const SizedBox(width: 6),
          Text(
            skill[0].toUpperCase() + skill.substring(1),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color:
                  isMatch
                      ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  List<String> _getMatchedSkills(Job job) {
    if (loggedUser == null) return [];
    final nUser = DataNormalizer.normalizeList(loggedUser!.skills);
    final nReq = DataNormalizer.normalizeList(job.requirements);
    return nReq
        .where((r) => nUser.any((u) => u.contains(r) || r.contains(u)))
        .toList();
  }

  List<String> _getMissingSkills(Job job) {
    if (loggedUser == null) return [];
    final nUser = DataNormalizer.normalizeList(loggedUser!.skills);
    final nReq = DataNormalizer.normalizeList(job.requirements);
    return nReq
        .where((r) => !nUser.any((u) => u.contains(r) || r.contains(u)))
        .toList();
  }
}

class _CircularGaugePainter extends CustomPainter {
  final double score;
  final Color color;
  final Color bgColor;
  final double strokeWidth;

  _CircularGaugePainter({
    required this.score,
    required this.color,
    required this.bgColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint =
        Paint()
          ..color = bgColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    final scorePaint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * score,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.color != color;
  }
}
