import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datos/globales.dart';
import '../modelos/modelo_usuario.dart';
import '../modelos/modelo_empleo.dart';
import '../modelos/modelo_chat.dart';
import '../servicios/servicio_imagen.dart';
import '../servicios/servicio_recomendacion.dart';
import '../servicios/servicio_chat.dart';
import 'pantalla_chat_detalle.dart';

class ApplicantsScreen extends StatefulWidget {
  final String? jobId;
  const ApplicantsScreen({super.key, this.jobId});

  @override
  State<ApplicantsScreen> createState() => _ApplicantsScreenState();
}

class _ApplicantsScreenState extends State<ApplicantsScreen> {
  Job? _targetJob;
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit && widget.jobId != null) {
      _loadJob();
      _isInit = true;
    }
  }

  Future<void> _loadJob() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('wanka_jobs')
            .doc(widget.jobId)
            .get();
    if (doc.exists && mounted) {
      setState(() {
        final data = doc.data()!;
        data['id'] = doc.id;
        _targetJob = Job.fromJson(data);
      });
    }
  }

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
      if (mounted) {
        _showSnackBar('Estado actualizado a $newStatus', isError: false);
      }
    } catch (e) {
      if (mounted) _showSnackBar('Error: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<AppUser?> _getUserData(String email) async {
    final doc =
        await FirebaseFirestore.instance
            .collection('wanka_users')
            .doc(email)
            .get();
    return doc.exists ? AppUser.fromJson(doc.data()!) : null;
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
              _buildHeader(),
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
                        widget.jobId != null
                            ? FirebaseFirestore.instance
                                .collection('wanka_applications')
                                .where('jobId', isEqualTo: widget.jobId)
                                .snapshots()
                            : FirebaseFirestore.instance
                                .collection('wanka_applications')
                                .where(
                                  'employerEmail',
                                  isEqualTo: loggedUser?.email,
                                )
                                .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return const Center(child: CircularProgressIndicator());
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                        return _buildEmptyState();

                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          return FutureBuilder<AppUser?>(
                            future: _getUserData(data['applicantEmail']),
                            builder: (context, userSnap) {
                              final user = userSnap.data;
                              double score = 0;
                              if (user != null && _targetJob != null) {
                                score =
                                    RecommendationService.calculateRelevanceScore(
                                      _targetJob!,
                                      user,
                                    );
                              }

                              return _buildApplicantItem(
                                docs[index].id,
                                data,
                                user,
                                score,
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Postulantes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Clasificados por relevancia IA',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantItem(
    String docId,
    Map<String, dynamic> data,
    AppUser? user,
    double score,
  ) {
    final status = data['status'] ?? 'Enviado';
    final statusColor =
        status == 'Aceptado'
            ? Colors.green
            : (status == 'Rechazado' ? Colors.red : Colors.orange);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAvatar(user, data['applicantName'], statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailsCard(data, status, statusColor, score),
                if (status == 'Enviado') ...[
                  const SizedBox(height: 12),
                  _buildActions(docId, data),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(AppUser? user, String? name, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: ClipOval(
        child:
            user != null &&
                    user.profileImagePath.isNotEmpty &&
                    ImageService.isBase64(user.profileImagePath)
                ? Image.memory(
                  ImageService.base64ToImage(user.profileImagePath),
                  fit: BoxFit.cover,
                )
                : Container(
                  color: color.withOpacity(0.1),
                  child: Center(
                    child: Text(
                      (name?[0] ?? '?').toUpperCase(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildDetailsCard(
    Map<String, dynamic> data,
    String status,
    Color statusColor,
    double score,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  data['applicantName'] ?? 'Candidato',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: Color(0xFF1A237E),
                  ),
                ),
              ),
              if (score > 80) _buildTopTalentBadge(),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Estado: ${status.toUpperCase()}',
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (score > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '• Match IA: ${score.toInt()}%',
                  style: const TextStyle(
                    color: Colors.purple,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data['message']?.isNotEmpty == true
                ? data['message']
                : "Interesado en la vacante. Por favor revisar mi perfil.",
            style: const TextStyle(
              height: 1.4,
              color: Color(0xFF455A64),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopTalentBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 12),
          SizedBox(width: 4),
          Text(
            'TOP TALENT',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(String docId, Map<String, dynamic> data) {
    return Row(
      children: [
        _circleBtn(
          Icons.close_rounded,
          Colors.red,
          () => _updateStatus(context, docId, 'Rechazado'),
        ),
        const SizedBox(width: 12),
        _circleBtn(
          Icons.check_rounded,
          Colors.green,
          () => _updateStatus(context, docId, 'Aceptado'),
        ),
        const SizedBox(width: 12),
        _circleBtn(
          Icons.chat_bubble_outline_rounded,
          Colors.blue,
          () => _startChat(context, data),
        ),
        const SizedBox(width: 12),
        const Text(
          '¿Aceptar candidato?',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<void> _startChat(BuildContext context, Map<String, dynamic> data) async {
    try {
      final jobId = data['jobId'];
      final jobTitle = data['jobTitle'];
      final applicantEmail = data['applicantEmail'];
      final applicantName = data['applicantName'];
      final employerEmail = data['employerEmail'];
      
      // Obtener nombre del empleador
      final employerDoc = await FirebaseFirestore.instance
          .collection('wanka_users')
          .doc(employerEmail)
          .get();
      String employerName = 'Empleador';
      if (employerDoc.exists) {
        employerName = employerDoc.data()?['name'] ?? 'Empleador';
      }

      final conversation = await ChatService.createOrGetConversation(
        jobId: jobId,
        jobTitle: jobTitle,
        employerEmail: employerEmail,
        employerName: employerName,
        applicantEmail: applicantEmail,
        applicantName: applicantName,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(conversation: conversation),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar('Error al iniciar chat: $e', isError: true);
      }
    }
  }

  Widget _circleBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline_rounded,
            size: 80,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin postulantes aún',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
