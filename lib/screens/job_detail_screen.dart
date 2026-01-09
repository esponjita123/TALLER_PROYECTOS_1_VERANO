import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/job_model.dart';

class JobDetailScreen extends StatelessWidget {
  final Job job;

  const JobDetailScreen({required this.job, super.key});

  Future<void> _callPhone(String phone) async {
    final Uri uri = Uri.parse("tel:$phone");
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Detalle del empleo"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (job.imagePath.isNotEmpty)
              Image.file(
                File(job.imagePath),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    job.company,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Icon(Icons.location_on),
                      const SizedBox(width: 6),
                      Text(job.location),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      const Icon(Icons.phone),
                      const SizedBox(width: 6),
                      Expanded(child: Text(job.phone)),

                      // Copiar
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: job.phone));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Número copiado al portapapeles"),
                            ),
                          );
                        },
                      ),

                      // Llamar
                      IconButton(
                        icon: const Icon(Icons.call, color: Colors.green),
                        onPressed: () => _callPhone(job.phone),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Descripción",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 8),

                  Text(job.description, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
