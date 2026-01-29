import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datos/globales.dart';
import '../modelos/modelo_empleo.dart';
import '../servicios/servicio_imagen.dart';
import 'pantalla_agregar_empleo.dart';
import 'pantalla_detalle_empleo.dart';
import 'pantalla_postulantes.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  Future<void> _deleteJob(BuildContext context, String jobId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange),
                SizedBox(width: 12),
                Text('Confirmar eliminación'),
              ],
            ),
            content: const Text('¿Estás seguro de eliminar esta publicación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('wanka_jobs')
            .doc(jobId)
            .delete();

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Publicación eliminada'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.shade700, Colors.grey.shade50],
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
                            'Mis Publicaciones',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Administra tus empleos publicados',
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

              // Posts List
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
                            .collection('wanka_jobs')
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
                                Icons.work_off_outlined,
                                size: 100,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'No has publicado empleos aún',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '¡Publica tu primer empleo!',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AddJobScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Publicar Empleo'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade700,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
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
                          data['id'] = doc.id;
                          final job = Job.fromJson(data);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 20),
                            elevation: 6,
                            shadowColor: Colors.indigo.withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen si existe
                                if (job.imagePath.isNotEmpty &&
                                    ImageService.isBase64(job.imagePath))
                                  ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(24),
                                    ),
                                    child: Image.memory(
                                      ImageService.base64ToImage(job.imagePath),
                                      height: 180,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),

                                Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              job.title,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) => AddJobScreen(
                                                          jobToEdit: job,
                                                        ),
                                                  ),
                                                );
                                              } else if (value == 'delete') {
                                                _deleteJob(context, job.id!);
                                              } else if (value == 'view') {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder:
                                                        (_) => JobDetailScreen(
                                                          job: job,
                                                        ),
                                                  ),
                                                );
                                              }
                                            },
                                            itemBuilder:
                                                (context) => [
                                                  const PopupMenuItem(
                                                    value: 'view',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .visibility_outlined,
                                                          color: Colors.blue,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Ver detalle'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'edit',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.edit_outlined,
                                                          color: Colors.orange,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Editar'),
                                                      ],
                                                    ),
                                                  ),
                                                  const PopupMenuItem(
                                                    value: 'delete',
                                                    child: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.delete_outline,
                                                          color: Colors.red,
                                                        ),
                                                        SizedBox(width: 8),
                                                        Text('Eliminar'),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.shade50,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.business_outlined,
                                              size: 18,
                                              color: Colors.indigo.shade700,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              job.company,
                                              style: TextStyle(
                                                color: Colors.indigo.shade900,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_outlined,
                                            size: 18,
                                            color: Colors.red.shade400,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            job.location,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),

                                      if (job.salaryMin > 0 ||
                                          job.salaryMax > 0) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.green.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.attach_money,
                                                size: 18,
                                                color: Colors.green.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'S/ ${job.salaryMin.toStringAsFixed(0)} - S/ ${job.salaryMax.toStringAsFixed(0)}',
                                                style: TextStyle(
                                                  color: Colors.green.shade900,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],

                                      const SizedBox(height: 8),
                                      Text(
                                        job.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      const Divider(),
                                      const SizedBox(height: 8),

                                      // Applicant Count Badge & Action
                                      StreamBuilder<QuerySnapshot>(
                                        stream:
                                            FirebaseFirestore.instance
                                                .collection(
                                                  'wanka_applications',
                                                )
                                                .where(
                                                  'jobId',
                                                  isEqualTo: job.id,
                                                )
                                                .snapshots(),
                                        builder: (context, appSnapshot) {
                                          final count =
                                              appSnapshot.data?.docs.length ??
                                              0;
                                          return Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(
                                                    Icons.people_outline,
                                                    color:
                                                        count > 0
                                                            ? Colors.purple
                                                            : Colors.grey,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    count == 1
                                                        ? '1 postulante'
                                                        : '$count postulantes',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          count > 0
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                      color:
                                                          count > 0
                                                              ? Colors.purple
                                                              : Colors
                                                                  .grey
                                                                  .shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              TextButton.icon(
                                                onPressed: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder:
                                                          (_) =>
                                                              ApplicantsScreen(
                                                                jobId: job.id,
                                                              ),
                                                    ),
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons
                                                      .arrow_circle_right_outlined,
                                                  size: 20,
                                                ),
                                                label: const Text(
                                                  'Ver Candidatos',
                                                ),
                                                style: TextButton.styleFrom(
                                                  foregroundColor:
                                                      Colors.indigo.shade700,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddJobScreen()),
          );
        },
        backgroundColor: Colors.indigo.shade700,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva Publicación',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 8,
      ),
    );
  }
}
