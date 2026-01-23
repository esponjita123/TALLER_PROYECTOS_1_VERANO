import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/modelo_empleo.dart';
import '../servicios/servicio_imagen.dart';
import '../datos/globales.dart';

class JobDetailScreen extends StatelessWidget {
  final Job job;

  const JobDetailScreen({super.key, required this.job});

  Future<void> _launchPhone(BuildContext context, String phone) async {
    // Limpiar el número de teléfono
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
    // Limpiar el número y asegurar que tenga código de país
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

    // Si el número empieza con 9 y tiene 9 dígitos, agregar código de Perú (51)
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

    if (loggedUser!.email == job.employerEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Text('No puedes postular a tu propio empleo'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
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
                Text('¿Deseas enviar tu perfil a ${job.company}?'),
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
                    fillColor: Colors.grey.shade50,
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
                  backgroundColor: Colors.blue.shade700,
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
          'jobId': job.id,
          'jobTitle': job.title,
          'applicantEmail': loggedUser!.email,
          'applicantName': loggedUser!.name,
          'employerEmail': job.employerEmail,
          'status': 'Enviado',
          'message': msgCtrl.text,
          'date': DateTime.now().toIso8601String(),
        };

        await FirebaseFirestore.instance
            .collection('wanka_applications')
            .add(applicationData);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('¡Postulación enviada exitosamente!'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
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
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Image Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background:
                  job.imagePath.isNotEmpty &&
                          ImageService.isBase64(job.imagePath)
                      ? Image.memory(
                        ImageService.base64ToImage(job.imagePath),
                        fit: BoxFit.cover,
                      )
                      : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.work_outline,
                            size: 80,
                            color: Colors.white70,
                          ),
                        ),
                      ),
            ),
            backgroundColor: Colors.blue.shade700,
          ),

          // Content
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              transform: Matrix4.translationValues(0, -20, 0),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Company
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.business_outlined,
                            color: Colors.blue.shade700,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            job.company,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.red.shade400,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          job.location,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Phone
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(job.phone, style: const TextStyle(fontSize: 16)),
                      ],
                    ),

                    // Salary
                    if (job.salaryMin > 0 || job.salaryMax > 0) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_money,
                              color: Colors.green.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'S/ ${job.salaryMin.toStringAsFixed(0)} - S/ ${job.salaryMax.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      job.description,
                      style: const TextStyle(fontSize: 16, height: 1.6),
                    ),
                    const SizedBox(height: 40),

                    // Apply Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () => _applyToJob(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_outlined, size: 24),
                            SizedBox(width: 12),
                            Text(
                              'POSTULAR AHORA',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Contact Options
                    const Center(
                      child: Text(
                        'O contáctalos directamente:',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _launchPhone(context, job.phone),
                            icon: const Icon(Icons.phone),
                            label: const Text('LLAMAR'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                () => _launchWhatsApp(
                                  context,
                                  job.phone,
                                  'Hola, estoy interesado en el puesto de ${job.title}',
                                ),
                            icon: const Icon(Icons.chat),
                            label: const Text('WHATSAPP'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade700,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
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
