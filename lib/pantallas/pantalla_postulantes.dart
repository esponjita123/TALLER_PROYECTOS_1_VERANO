import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datos/globales.dart';
import '../modelos/modelo_usuario.dart';
import '../servicios/servicio_imagen.dart';

class ApplicantsScreen extends StatelessWidget {
  const ApplicantsScreen({super.key});

  Future<void> _updateStatus(
    BuildContext context,
    String docId,
    String newStatus,
  ) async {
    try {
      await FirebaseFirestore.instance
          .collection('wanka_applications')
          .doc(docId)
          .update({'status': newStatus});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Estado actualizado a $newStatus'),
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
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<AppUser?> _getUserData(String email) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('wanka_users')
              .doc(email)
              .get();

      if (doc.exists) {
        return AppUser.fromJson(doc.data()!);
      }
    } catch (e) {
      print('Error loading user: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.purple.shade700, Colors.grey.shade50],
            stops: const [0.0, 0.25],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Postulantes',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Gestiona las postulaciones recibidas',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Applicants List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('wanka_applications')
                            .where(
                              'employerEmail',
                              isEqualTo: loggedUser?.email,
                            )
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 60,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text('Error: ${snapshot.error}'),
                            ],
                          ),
                        );
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 100,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No tienes postulantes aún',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final String status = data['status'] ?? 'Enviado';
                          final Color statusColor =
                              status == 'Aceptado'
                                  ? Colors.green
                                  : status == 'Rechazado'
                                  ? Colors.red
                                  : Colors.orange;

                          return FutureBuilder<AppUser?>(
                            future: _getUserData(data['applicantEmail']),
                            builder: (context, userSnapshot) {
                              final user = userSnapshot.data;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 20),
                                elevation: 4,
                                shadowColor: Colors.purple.withOpacity(0.2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          // Profile Picture
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: statusColor,
                                                width: 3,
                                              ),
                                            ),
                                            child: ClipOval(
                                              child:
                                                  user != null &&
                                                          user
                                                              .profileImagePath
                                                              .isNotEmpty &&
                                                          ImageService.isBase64(
                                                            user.profileImagePath,
                                                          )
                                                      ? Image.memory(
                                                        ImageService.base64ToImage(
                                                          user.profileImagePath,
                                                        ),
                                                        fit: BoxFit.cover,
                                                      )
                                                      : Container(
                                                        color: statusColor
                                                            .withOpacity(0.2),
                                                        child: Center(
                                                          child: Text(
                                                            (data['applicantName']?[0] ??
                                                                    '?')
                                                                .toUpperCase(),
                                                            style: TextStyle(
                                                              fontSize: 24,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  statusColor,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                            ),
                                          ),
                                          const SizedBox(width: 16),

                                          // Info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  data['applicantName'] ??
                                                      'Desconocido',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  'Postuló a: ${data['jobTitle'] ?? 'Sin empleo'}',
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: statusColor
                                                        .withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: statusColor,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    status,
                                                    style: TextStyle(
                                                      color: statusColor,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (data['message'] != null &&
                                          data['message'].isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        const Divider(),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.message_outlined,
                                                size: 20,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  data['message'],
                                                  style: const TextStyle(
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed:
                                                  () => _updateStatus(
                                                    context,
                                                    doc.id,
                                                    'Rechazado',
                                                  ),
                                              icon: const Icon(Icons.close),
                                              label: const Text('Rechazar'),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.red,
                                                side: const BorderSide(
                                                  color: Colors.red,
                                                  width: 2,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed:
                                                  () => _updateStatus(
                                                    context,
                                                    doc.id,
                                                    'Aceptado',
                                                  ),
                                              icon: const Icon(Icons.check),
                                              label: const Text('Aceptar'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Colors.green.shade600,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
