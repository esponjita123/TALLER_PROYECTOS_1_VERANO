import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../datos/globales.dart';
import '../modelos/modelo_empleo.dart';
import '../modelos/modelo_usuario.dart';
import '../servicios/servicio_imagen.dart';
import '../servicios/servicio_recomendacion.dart';
import '../utilidades/normalizador_datos.dart';
import 'pantalla_detalle_empleo.dart';
import 'pantalla_editar_perfil.dart';

class ForYouScreen extends StatefulWidget {
  const ForYouScreen({super.key});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen>
    with TickerProviderStateMixin {
  List<Job> recommendedJobs = [];
  List<Job> filteredJobs = [];
  bool isLoading = true;
  String _selectedType = 'todos';
  late AnimationController _animationController;
  late AnimationController _gaugeController;

  final List<Map<String, dynamic>> _typeFilters = [
    {'key': 'todos', 'label': 'Todos', 'icon': Icons.apps_rounded},
    {
      'key': 'profesional',
      'label': 'Profesional',
      'icon': Icons.business_center,
    },
    {'key': 'temporal', 'label': 'Temporal', 'icon': Icons.schedule},
    {'key': 'medio-tiempo', 'label': 'Medio Tiempo', 'icon': Icons.timelapse},
    {'key': 'por-obra', 'label': 'Por Obra', 'icon': Icons.engineering},
    {'key': 'remoto', 'label': 'Remoto', 'icon': Icons.home_work},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _gaugeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
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
              .limit(100)
              .get();

      final allJobs =
          snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Job.fromJson(data);
          }).toList();

      var recommended = RecommendationService.getRecommendedJobs(
        allJobs,
        loggedUser!,
      );

      if (recommended.length < 3) {
        recommended = RecommendationService.rankJobsByRelevance(
          allJobs,
          loggedUser!,
        );
        recommended = recommended.take(20).toList();
      }

      setState(() {
        recommendedJobs = recommended;
        _applyFilter();
        isLoading = false;
      });

      _animationController.forward();
      _gaugeController.forward();
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar recomendaciones: $e')),
        );
      }
    }
  }

  void _applyFilter() {
    if (_selectedType == 'todos') {
      filteredJobs = List.from(recommendedJobs);
    } else {
      filteredJobs =
          recommendedJobs
              .where((j) => j.jobType.toLowerCase() == _selectedType)
              .toList();
    }
  }

  void _onFilterChanged(String type) {
    setState(() {
      _selectedType = type;
      _applyFilter();
    });
    _animationController.reset();
    _animationController.forward();
  }

  Future<void> _refreshRecommendations() async {
    setState(() => isLoading = true);
    _animationController.reset();
    _gaugeController.reset();
    await _loadRecommendedJobs();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFCE93D8) : Colors.purple.shade700;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: isDark ? 0.12 : 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            right: -80,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withValues(alpha: isDark ? 0.06 : 0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, cs, isDark, accent),
                _buildContent(theme, cs, isDark, accent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? cs.surfaceContainerHighest : Colors.grey.shade100,
              foregroundColor: cs.onSurface,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: accent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Para Ti',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Empleos recomendados con IA',
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _refreshRecommendations,
            icon: const Icon(Icons.refresh_rounded),
            style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? cs.surfaceContainerHighest : Colors.grey.shade100,
              foregroundColor: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // FILTER CHIPS
  // ═══════════════════════════════════════════════════════

  Widget _buildFilterChips(ColorScheme cs, bool isDark, Color accent) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _typeFilters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _typeFilters[index];
          final isSelected = _selectedType == filter['key'];
          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  filter['icon'] as IconData,
                  size: 16,
                  color:
                      isSelected
                          ? Colors.white
                          : cs.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 6),
                Text(
                  filter['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color:
                        isSelected
                            ? Colors.white
                            : cs.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            backgroundColor:
                isDark ? cs.surfaceContainerHighest : Colors.grey.shade100,
            selectedColor: accent,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            showCheckmark: false,
            onSelected: (_) => _onFilterChanged(filter['key'] as String),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MAIN CONTENT
  // ═══════════════════════════════════════════════════════

  Widget _buildContent(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    if (loggedUser == null) {
      return Expanded(
        child: _buildEmptyState(
          icon: Icons.login,
          title: 'Inicia sesión',
          subtitle: 'Para ver recomendaciones personalizadas',
          cs: cs,
        ),
      );
    }

    if (isLoading) {
      return Expanded(child: _buildShimmerLoading(cs, isDark));
    }

    if (recommendedJobs.isEmpty) {
      return Expanded(
        child: _buildEmptyStateWithAction(
          icon: Icons.search_off,
          title: 'No hay recomendaciones aún',
          subtitle:
              'Completa tu perfil con oficios y nivel para mejores resultados',
          actionText: 'Editar Perfil',
          onAction: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditProfileScreen()),
            ).then((_) => _refreshRecommendations());
          },
          cs: cs,
          accent: accent,
        ),
      );
    }

    return Expanded(
      child: Column(
        children: [
          // Filter chips
          _buildFilterChips(cs, isDark, accent),
          const SizedBox(height: 8),
          // Stats row
          _buildStatsRow(theme, cs, isDark, accent),
          const SizedBox(height: 8),
          // Job list
          Expanded(
            child:
                filteredJobs.isEmpty
                    ? _buildEmptyState(
                      icon: Icons.filter_list_off,
                      title: 'Sin resultados',
                      subtitle: 'No hay empleos de este tipo',
                      cs: cs,
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 4,
                      ),
                      itemCount: filteredJobs.length,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _buildHeroCard(
                            filteredJobs[0],
                            theme,
                            cs,
                            isDark,
                            accent,
                          );
                        }
                        return _buildJobCard(
                          filteredJobs[index],
                          index,
                          theme,
                          cs,
                          isDark,
                          accent,
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════

  Widget _buildStatsRow(
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border:
              isDark
                  ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.5))
                  : null,
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(
              icon: Icons.star,
              label: 'Recomendados',
              value: '${filteredJobs.length}',
              color: accent,
              cs: cs,
            ),
            Container(width: 1, height: 36, color: cs.outlineVariant),
            _buildStat(
              icon: Icons.trending_up,
              label: 'Mejor Match',
              value:
                  filteredJobs.isNotEmpty
                      ? '${filteredJobs.first.matchScore.toInt()}%'
                      : '--',
              color: cs.primary,
              cs: cs,
            ),
            Container(width: 1, height: 36, color: cs.outlineVariant),
            _buildStat(
              icon: Icons.smart_toy,
              label: 'Modelo',
              value: RecommendationService.isModelLoaded ? 'v2' : 'Reglas',
              color: Colors.teal,
              cs: cs,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ColorScheme cs,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════
  // HERO CARD (Top Match — primera tarjeta destacada)
  // ═══════════════════════════════════════════════════════

  Widget _buildHeroCard(
    Job job,
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    final scoreColor = _getScoreColor(job.matchScore);
    final matchedSkills = _getMatchedSkills(job);
    final missingSkills = _getMissingSkills(job);

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final value =
            Tween<double>(begin: 0.0, end: 1.0)
                .animate(
                  CurvedAnimation(
                    parent: _animationController,
                    curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
                  ),
                )
                .value;
        return Transform.translate(
          offset: Offset(0, 40 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors:
                isDark
                    ? [accent.withValues(alpha: 0.15), cs.surface]
                    : [accent.withValues(alpha: 0.08), Colors.white],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.3 : 0.2),
            width: 1.5,
          ),
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.12),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
              ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top label
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [accent, accent.withValues(alpha: 0.7)],
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.emoji_events, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'TOP MATCH — Mejor para ti',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Image
              if (job.imagePath.isNotEmpty &&
                  ImageService.isBase64(job.imagePath))
                Image.memory(
                  ImageService.base64ToImage(job.imagePath),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Gauge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                job.title,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.business, size: 16, color: accent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      job.company,
                                      style: TextStyle(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 16,
                                    color: cs.error,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      job.location,
                                      style: TextStyle(
                                        color: cs.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Circular Gauge
                        GestureDetector(
                          onTap:
                              () =>
                                  _showMatchDetails(context, job, loggedUser!),
                          child: _buildCircularGauge(
                            job.matchScore,
                            scoreColor,
                            56,
                          ),
                        ),
                      ],
                    ),

                    // Salary
                    if (job.salaryMin > 0 || job.salaryMax > 0) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '💰 S/. ${job.salaryMin} - S/. ${job.salaryMax}',
                          style: TextStyle(
                            color:
                                isDark
                                    ? Colors.greenAccent
                                    : Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],

                    // Skill chips
                    if (matchedSkills.isNotEmpty ||
                        missingSkills.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Habilidades',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          ...matchedSkills.map(
                            (s) => _buildSkillChip(s, true, isDark),
                          ),
                          ...missingSkills.map(
                            (s) => _buildSkillChip(s, false, isDark),
                          ),
                        ],
                      ),
                    ],

                    // AI explanation
                    if (loggedUser != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              isDark
                                  ? cs.surfaceContainerHighest
                                  : cs.surfaceContainerHighest.withValues(
                                    alpha: 0.5,
                                  ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 18,
                              color: accent,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                RecommendationService.getMatchExplanation(
                                  job,
                                  loggedUser!,
                                ),
                                style: TextStyle(
                                  color: cs.onSurface.withValues(alpha: 0.7),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed:
                                  () => _showMatchDetails(
                                    context,
                                    job,
                                    loggedUser!,
                                  ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Detalles',
                                style: TextStyle(fontSize: 12, color: accent),
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

  // ═══════════════════════════════════════════════════════
  // REGULAR JOB CARD
  // ═══════════════════════════════════════════════════════

  Widget _buildJobCard(
    Job job,
    int index,
    ThemeData theme,
    ColorScheme cs,
    bool isDark,
    Color accent,
  ) {
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(index * 0.08, 1.0, curve: Curves.easeOut),
      ),
    );

    final scoreColor = _getScoreColor(job.matchScore);
    final matchedSkills = _getMatchedSkills(job);
    final missingSkills = _getMissingSkills(job);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - animation.value)),
          child: Opacity(opacity: animation.value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border:
              isDark
                  ? Border.all(color: cs.outlineVariant.withValues(alpha: 0.3))
                  : null,
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
              ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image thumb
                    if (job.imagePath.isNotEmpty &&
                        ImageService.isBase64(job.imagePath))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          ImageService.base64ToImage(job.imagePath),
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        height: 60,
                        width: 60,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.work_outline,
                          color: accent,
                          size: 28,
                        ),
                      ),
                    const SizedBox(width: 14),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            job.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            job.company,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: cs.error.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  job.location,
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.5),
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Gauge
                    GestureDetector(
                      onTap: () => _showMatchDetails(context, job, loggedUser!),
                      child: _buildCircularGauge(
                        job.matchScore,
                        scoreColor,
                        44,
                      ),
                    ),
                  ],
                ),

                // Skill chips
                if (matchedSkills.isNotEmpty || missingSkills.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 28,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ...matchedSkills.map(
                          (s) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _buildSkillChip(s, true, isDark),
                          ),
                        ),
                        ...missingSkills
                            .take(3)
                            .map(
                              (s) => Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: _buildSkillChip(s, false, isDark),
                              ),
                            ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // CIRCULAR GAUGE
  // ═══════════════════════════════════════════════════════

  Widget _buildCircularGauge(double score, Color color, double size) {
    return AnimatedBuilder(
      animation: _gaugeController,
      builder: (context, _) {
        final animatedScore = score * _gaugeController.value;
        return SizedBox(
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
                  fontSize: size * 0.24,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════
  // SKILL CHIPS
  // ═══════════════════════════════════════════════════════

  Widget _buildSkillChip(String skill, bool isMatch, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color:
            isMatch
                ? (isDark
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.green.withValues(alpha: 0.1))
                : (isDark
                    ? Colors.grey.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              isMatch
                  ? Colors.green.withValues(alpha: 0.4)
                  : Colors.grey.withValues(alpha: 0.3),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMatch ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 12,
            color:
                isMatch
                    ? (isDark ? Colors.greenAccent : Colors.green.shade600)
                    : Colors.grey,
          ),
          const SizedBox(width: 4),
          Text(
            _capitalizeSkill(skill),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color:
                  isMatch
                      ? (isDark ? Colors.greenAccent : Colors.green.shade700)
                      : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // SHIMMER LOADING
  // ═══════════════════════════════════════════════════════

  Widget _buildShimmerLoading(ColorScheme cs, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: List.generate(4, (i) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          height: i == 0 ? 220 : 100,
          decoration: BoxDecoration(
            color:
                isDark
                    ? cs.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.onSurface.withValues(alpha: 0.2),
            ),
          ),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════

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

  String _capitalizeSkill(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 50) return Colors.orange;
    return Colors.red;
  }

  // ═══════════════════════════════════════════════════════
  // EMPTY STATES
  // ═══════════════════════════════════════════════════════

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required ColorScheme cs,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: cs.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyStateWithAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
    required ColorScheme cs,
    required Color accent,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: cs.onSurface.withValues(alpha: 0.15)),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.edit),
              label: Text(actionText),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  // MATCH DETAILS BOTTOM SHEET
  // ═══════════════════════════════════════════════════════

  void _showMatchDetails(BuildContext context, Job job, AppUser user) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFFCE93D8) : Colors.purple.shade700;

    final breakdown = RecommendationService.getMatchBreakdown(job, user);
    final details = breakdown['details'] as List<String>;
    final score = breakdown['score'] as double;
    final scoreColor = _getScoreColor(score);

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.cardColor,
      isScrollControlled: true,
      builder:
          (context) => Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Análisis de Compatibilidad',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    _buildCircularGauge(score, scoreColor, 52),
                  ],
                ),
                const SizedBox(height: 20),

                // Details
                if (details.isEmpty)
                  Text(
                    'Sin detalles específicos, pero parece buena oportunidad.',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ...details.map(
                  (detail) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: accent,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            detail,
                            style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Skills breakdown
                if (loggedUser != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Habilidades Requeridas',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ..._getMatchedSkills(
                        job,
                      ).map((s) => _buildSkillChip(s, true, isDark)),
                      ..._getMissingSkills(
                        job,
                      ).map((s) => _buildSkillChip(s, false, isDark)),
                    ],
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(backgroundColor: accent),
                    child: const Text('Entendido'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _gaugeController.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════
// CIRCULAR GAUGE PAINTER
// ═══════════════════════════════════════════════════════

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

    // Background arc
    final bgPaint =
        Paint()
          ..color = bgColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Score arc
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
