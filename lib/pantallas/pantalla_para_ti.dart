import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datos/globales.dart';
import '../modelos/modelo_empleo.dart';
import '../servicios/servicio_imagen.dart';
import '../servicios/servicio_recomendacion.dart';
import 'pantalla_detalle_empleo.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen>
    with TickerProviderStateMixin {
  List<Job> recommendedJobs = [];
  bool isLoading = true;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadRecommendedJobs();
  }

  Future<void> _loadRecommendedJobs() async {
    if (loggedUser == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('wanka_jobs')
              .orderBy('postedDate', descending: true)
              .limit(50) // Limitar a 50 para performance
              .get();

      final allJobs =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Job.fromJson(data);
          }).toList();

      // Filtrar solo recomendaciones altas (score > 60)
      final recommended = RecommendationService.getRecommendedJobs(
        allJobs,
        loggedUser!,
      );

      setState(() {
        recommendedJobs = recommended;
        isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar recomendaciones: $e')),
        );
      }
    }
  }

  Future<void> _refreshRecommendations() async {
    setState(() => isLoading = true);
    await _loadRecommendedJobs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade700, Colors.blue.shade700],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
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
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: Colors.white,
                                size: 28,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Para Ti',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Empleos recomendados con IA',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _refreshRecommendations,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (loggedUser == null) {
      return _buildEmptyState(
        icon: Icons.login,
        title: 'Inicia sesión',
        subtitle: 'Para ver recomendaciones personalizadas',
      );
    }

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (recommendedJobs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No hay recomendaciones aún',
        subtitle:
            'Completa tu perfil con skills y experiencia para mejores resultados',
      );
    }

    return Column(
      children: [
        // Stats Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade50, Colors.blue.shade50],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.shade100),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat(
                  icon: Icons.star,
                  label: 'Recomendados',
                  value: '${recommendedJobs.length}',
                  color: Colors.purple.shade700,
                ),
                Container(width: 1, height: 40, color: Colors.purple.shade200),
                _buildStat(
                  icon: Icons.trending_up,
                  label: 'Mejor Match',
                  value: '${recommendedJobs.first.matchScore.toInt()}%',
                  color: Colors.blue.shade700,
                ),
              ],
            ),
          ),
        ),

        // Jobs List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: recommendedJobs.length,
            itemBuilder:
                (context, index) =>
                    _buildJobCard(recommendedJobs[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildJobCard(Job job, int index) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOut),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 8,
        shadowColor: Colors.purple.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with Match Badge
              if (job.imagePath.isNotEmpty &&
                  ImageService.isBase64(job.imagePath))
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: Image.memory(
                        ImageService.base64ToImage(job.imagePath),
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Match Score Badge
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade600,
                              Colors.blue.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.purple.withOpacity(0.5),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${job.matchScore.toInt()}% Match',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.business,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          job.company,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          job.location,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    // Match Explanation
                    if (loggedUser != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.shade100),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              size: 16,
                              color: Colors.purple.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                RecommendationService.getMatchExplanation(
                                  job,
                                  loggedUser!,
                                ),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple.shade900,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 100, color: Colors.grey.shade300),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}
