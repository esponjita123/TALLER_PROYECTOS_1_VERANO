import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datos/globales.dart';

class MyApplicationsScreen extends StatelessWidget {
  const MyApplicationsScreen({super.key});

  Future<void> _deleteApplication(
    BuildContext context,
    String applicationId,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Retirar Postulación'),
            content: const Text('¿Estás seguro de cancelar esta postulación?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Volver'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Sí, retirar'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('wanka_applications')
          .doc(applicationId)
          .delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Postulación retirada correctamente'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background decoration
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.orange.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('wanka_applications')
                            .where(
                              'applicantEmail',
                              isEqualTo: loggedUser?.email,
                            )
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return _buildErrorState();
                      if (snapshot.connectionState == ConnectionState.waiting)
                        return _buildLoadingState();
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                        return _buildEmptyState();

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final date =
                              data['date'] != null
                                  ? DateTime.parse(data['date'])
                                  : DateTime.now();

                          return Hero(
                            tag: 'app_${doc.id}',
                            child: _buildApplicationCard(
                              context,
                              doc,
                              data,
                              date,
                              index,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor: Colors.grey.shade100,
              foregroundColor: Colors.blueGrey.shade800,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mis Postulaciones',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Seguimiento de tus aplicaciones',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    DocumentSnapshot doc,
    Map<String, dynamic> data,
    DateTime date,
    int index,
  ) {
    String status = data['status'] ?? 'Enviado';
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'visto':
        statusColor = Colors.blue.shade600;
        statusIcon = Icons.visibility_outlined;
        break;
      case 'aceptado':
        statusColor = Colors.green.shade600;
        statusIcon = Icons.check_circle_outline;
        break;
      case 'rechazado':
        statusColor = Colors.red.shade600;
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = Colors.orange.shade600;
        statusIcon = Icons.send_rounded;
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {}, // Future: Job detail
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusChip(status, statusColor, statusIcon),
                      Text(
                        '${date.day}/${date.month}',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    data['jobTitle'] ?? 'Puesto no especificado',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.blueGrey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.business_rounded,
                        size: 14,
                        color: Colors.blueGrey.shade300,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Empresa Local', // Could be fetched if added to model
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blueGrey.shade400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () => _deleteApplication(context, doc.id),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text(
                          'CANCELAR',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 1,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade400,
                          backgroundColor: Colors.red.shade50,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.assignment_ind_outlined,
              size: 80,
              color: Colors.orange.shade300,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '¡Aún no hay postulaciones!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tu próxima oportunidad está esperando.\n¡Postula hoy mismo!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator(color: Colors.orange));
  }

  Widget _buildErrorState() {
    return const Center(child: Text('Algo salió mal al cargar tus datos'));
  }
}
