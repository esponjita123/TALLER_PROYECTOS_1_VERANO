import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datos/globales.dart';
import '../modelos/modelo_empleo.dart';
import '../servicios/servicio_imagen.dart';
import '../servicios/servicio_recomendacion.dart';
import 'pantalla_detalle_empleo.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with TickerProviderStateMixin {
  List<Job> jobs = [];
  List<Job> filteredJobs = [];
  bool isLoading = true;
  String searchQuery = "";
  String selectedFilter = "Todos";
  late AnimationController _listAnimationController;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadJobs();
  }

  void _loadJobs() {
    FirebaseFirestore.instance
        .collection('wanka_jobs')
        .orderBy('postedDate', descending: true)
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              jobs =
                  snapshot.docs.map((doc) {
                    final data = doc.data();
                    data['id'] = doc.id;
                    return Job.fromJson(data);
                  }).toList();

              if (loggedUser != null) {
                jobs = RecommendationService.rankJobsByRelevance(
                  jobs,
                  loggedUser!,
                );
              }

              _applyFilters();
              isLoading = false;
            });
            _listAnimationController.reset();
            _listAnimationController.forward();
          }
        });
  }

  void _applyFilters() {
    filteredJobs =
        jobs.where((job) {
          final matchesSearch =
              job.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
              job.company.toLowerCase().contains(searchQuery.toLowerCase());

          if (selectedFilter == "Todos") return matchesSearch;
          if (selectedFilter == "Remoto")
            return matchesSearch &&
                job.location.toLowerCase().contains("remoto");
          if (selectedFilter == "Presencial")
            return matchesSearch &&
                !job.location.toLowerCase().contains("remoto");

          return matchesSearch;
        }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Colors.blue.withOpacity(0.15), Colors.transparent],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildModernHeader(),
                _buildFilterChips(),

                Expanded(
                  child:
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : filteredJobs.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            itemCount: filteredJobs.length,
                            itemBuilder:
                                (context, index) =>
                                    _buildJobCard(filteredJobs[index], index),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
              Text(
                'Empleos',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Colors.blueGrey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Buscar cargo o empresa...',
                    hintStyle: TextStyle(
                      color: Colors.blueGrey.shade300,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    icon: Icon(
                      Icons.search_rounded,
                      color: Colors.blue.shade400,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ["Todos", "Remoto", "Presencial"];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children:
            filters.map((filter) {
              final isSelected = selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.blueGrey.shade600,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      selectedFilter = filter;
                      _applyFilters();
                    });
                  },
                  backgroundColor: Colors.grey.shade100,
                  selectedColor: Colors.blue.shade600,
                  checkmarkColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          Text(
            'No encontramos resultados',
            style: TextStyle(
              fontSize: 18,
              color: Colors.blueGrey.shade400,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos o filtros',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Job job, int index) {
    final isMyJob = job.employerEmail == loggedUser?.email;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Interval(index * 0.1, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: animation,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Company Icon/Image Placeholder
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child:
                              job.imagePath.isNotEmpty &&
                                      ImageService.isBase64(job.imagePath)
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(15),
                                    child: Image.memory(
                                      ImageService.base64ToImage(job.imagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : Icon(
                                    Icons.business_rounded,
                                    color: Colors.blue.shade300,
                                  ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A237E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                job.company,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.blueGrey.shade400,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMyJob)
                          _buildMyJobBadge()
                        else if (job.matchScore > 75)
                          _buildMatchBadge(job.matchScore),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _infoChip(
                          Icons.location_on_outlined,
                          job.location,
                          Colors.red.shade400,
                        ),
                        const SizedBox(width: 12),
                        if (job.salaryMax > 0)
                          _infoChip(
                            Icons.payments_outlined,
                            'S/ ${job.salaryMax.toInt()}',
                            Colors.green.shade500,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyJobBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'TUYO',
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildMatchBadge(double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade400],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            '${score.toInt()}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    super.dispose();
  }
}
