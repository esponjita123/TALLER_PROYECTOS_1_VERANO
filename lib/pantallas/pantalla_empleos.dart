import 'dart:ui';
import 'package:flutter/material.dart';
import '../datos/globales.dart';
import '../modelos/modelo_empleo.dart';
import '../servicios/servicio_imagen.dart';
import '../servicios/servicio_recomendacion.dart';
import '../servicios/servicio_paginacion.dart';
import '../widgets/skeletons.dart';
import 'pantalla_detalle_empleo.dart';
import 'pantalla_filtros_avanzados.dart';

class JobsScreen extends StatefulWidget {
  const JobsScreen({super.key});

  @override
  State<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends State<JobsScreen> with TickerProviderStateMixin {
  final JobsPaginationService _paginationService = JobsPaginationService();
  List<Job> jobs = [];
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  String searchQuery = "";

  // Filtros avanzados
  String? selectedJobType;
  double? minSalary;
  double? maxSalary;
  String? selectedLocation;
  bool showRemoteOnly = false;

  late AnimationController _listAnimationController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _loadFirstPage();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreJobs();
    }
  }

  Future<void> _loadFirstPage() async {
    setState(() => isLoading = true);

    final result = await _paginationService.loadFirstPage(
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      jobType: selectedJobType,
      minSalary: minSalary,
      maxSalary: maxSalary,
      location: selectedLocation,
    );

    if (mounted) {
      setState(() {
        jobs = result;
        hasMore = _paginationService.hasMore;
        isLoading = false;
      });

      if (loggedUser != null && jobs.isNotEmpty) {
        jobs = RecommendationService.rankJobsByRelevance(jobs, loggedUser!);
      }

      _listAnimationController.reset();
      _listAnimationController.forward();
    }
  }

  Future<void> _loadMoreJobs() async {
    if (isLoadingMore || !hasMore) return;

    setState(() => isLoadingMore = true);

    final result = await _paginationService.loadNextPage(
      searchQuery: searchQuery.isEmpty ? null : searchQuery,
      jobType: selectedJobType,
      minSalary: minSalary,
      maxSalary: maxSalary,
      location: selectedLocation,
    );

    if (mounted) {
      setState(() {
        if (loggedUser != null && result.isNotEmpty) {
          final rankedNewJobs = RecommendationService.rankJobsByRelevance(
            result,
            loggedUser!,
          );
          jobs.addAll(rankedNewJobs);
        } else {
          jobs.addAll(result);
        }
        hasMore = _paginationService.hasMore;
        isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    searchQuery = value;
    _debounceLoad();
  }

  void _debounceLoad() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadFirstPage();
    });
  }

  Future<void> _showAdvancedFilters() async {
    final result = await Navigator.push<FilterResult>(
      context,
      MaterialPageRoute(
        builder:
            (_) => AdvancedFiltersScreen(
              initialJobType: selectedJobType,
              initialMinSalary: minSalary,
              initialMaxSalary: maxSalary,
              initialLocation: selectedLocation,
              initialRemoteOnly: showRemoteOnly,
            ),
      ),
    );

    if (result != null) {
      setState(() {
        selectedJobType = result.jobType;
        minSalary = result.minSalary;
        maxSalary = result.maxSalary;
        selectedLocation = result.location;
        showRemoteOnly = result.remoteOnly;
      });
      _loadFirstPage();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedJobType = null;
      minSalary = null;
      maxSalary = null;
      selectedLocation = null;
      showRemoteOnly = false;
      searchQuery = '';
    });
    _loadFirstPage();
  }

  bool get hasActiveFilters {
    return selectedJobType != null ||
        minSalary != null ||
        maxSalary != null ||
        selectedLocation != null ||
        showRemoteOnly ||
        searchQuery.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
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
                  colors: [
                    cs.primary.withOpacity(isDark ? 0.08 : 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.secondary.withOpacity(isDark ? 0.05 : 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildModernHeader(theme, cs, isDark),
                _buildFilterChips(theme, cs, isDark),
                Expanded(
                  child:
                      isLoading
                          ? const JobsListSkeleton()
                          : jobs.isEmpty
                          ? _buildEmptyState(theme, cs)
                          : _buildJobsList(theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernHeader(ThemeData theme, ColorScheme cs, bool isDark) {
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
                  backgroundColor:
                      isDark
                          ? cs.surfaceContainerHighest
                          : Colors.grey.shade100,
                  foregroundColor: cs.onSurface,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Empleos',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (hasActiveFilters)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 16,
                        color: cs.onPrimaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Activos',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Search bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? cs.surfaceContainerHighest
                      : Colors.grey.shade100.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? cs.outlineVariant : Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: cs.primary.withOpacity(0.7)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: _onSearchChanged,
                    style: TextStyle(color: cs.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Buscar cargo, empresa o palabra clave...',
                      hintStyle: TextStyle(
                        color: cs.onSurface.withOpacity(0.4),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _showAdvancedFilters,
                  icon: Icon(
                    Icons.tune_rounded,
                    color: cs.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme, ColorScheme cs, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.clear,
                      size: 16,
                      color: isDark ? Colors.red.shade300 : Colors.red.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Limpiar',
                      style: TextStyle(
                        color:
                            isDark ? Colors.red.shade300 : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                onPressed: _clearFilters,
                backgroundColor:
                    isDark ? Colors.red.withOpacity(0.15) : Colors.red.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide.none,
                ),
              ),
            ),
          if (selectedJobType != null)
            _buildFilterChip(
              selectedJobType!,
              cs,
              isDark,
              () => setState(() {
                selectedJobType = null;
                _loadFirstPage();
              }),
            ),
          if (minSalary != null || maxSalary != null)
            _buildFilterChip(
              'S/${minSalary?.toInt() ?? 0} - S/${maxSalary?.toInt() ?? '∞'}',
              cs,
              isDark,
              () => setState(() {
                minSalary = null;
                maxSalary = null;
                _loadFirstPage();
              }),
            ),
          if (selectedLocation != null)
            _buildFilterChip(
              selectedLocation!,
              cs,
              isDark,
              () => setState(() {
                selectedLocation = null;
                _loadFirstPage();
              }),
            ),
          if (showRemoteOnly)
            _buildFilterChip(
              'Remoto',
              cs,
              isDark,
              () => setState(() {
                showRemoteOnly = false;
                _loadFirstPage();
              }),
            ),
          if (!hasActiveFilters)
            FilterChip(
              label: Text(
                'Todos los empleos',
                style: TextStyle(
                  color: isDark ? cs.onPrimary : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: true,
              onSelected: (_) {},
              selectedColor: cs.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide.none,
              showCheckmark: false,
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    ColorScheme cs,
    bool isDark,
    VoidCallback onRemove,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(color: cs.onPrimaryContainer, fontSize: 13),
        ),
        deleteIcon: Icon(Icons.close, size: 16, color: cs.onPrimaryContainer),
        onDeleted: onRemove,
        backgroundColor: cs.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide.none,
      ),
    );
  }

  Widget _buildJobsList(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      color: theme.colorScheme.primary,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: jobs.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == jobs.length) {
            return _buildLoadingIndicator(theme);
          }
          return _buildJobCard(jobs[index], index, theme);
        },
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Column(
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cargando más empleos...',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme cs) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 80,
            color: cs.onSurface.withOpacity(0.15),
          ),
          const SizedBox(height: 20),
          Text(
            'No encontramos resultados',
            style: TextStyle(
              fontSize: 18,
              color: cs.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta ajustar los filtros o términos de búsqueda',
            style: TextStyle(
              fontSize: 14,
              color: cs.onSurface.withOpacity(0.4),
            ),
          ),
          if (hasActiveFilters) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar filtros'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildJobCard(Job job, int index, ThemeData theme) {
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMyJob = job.employerEmail == loggedUser?.email;
    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _listAnimationController,
        curve: Interval((index % 10) * 0.05, 1.0, curve: Curves.easeOutCubic),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border:
              isDark
                  ? Border.all(color: cs.outlineVariant.withOpacity(0.5))
                  : null,
          boxShadow:
              isDark
                  ? null
                  : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
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
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child:
                              job.imagePath.isNotEmpty &&
                                      ImageService.isBase64(job.imagePath)
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.memory(
                                      ImageService.base64ToImage(job.imagePath),
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                  : Icon(
                                    Icons.business_rounded,
                                    color: cs.primary.withOpacity(0.6),
                                  ),
                        ),
                        const SizedBox(width: 14),
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
                              const SizedBox(height: 3),
                              Text(
                                job.company,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface.withOpacity(0.5),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isMyJob)
                          _buildMyJobBadge(isDark)
                        else if (job.matchScore > 75)
                          _buildMatchBadge(job.matchScore),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _infoChip(
                          Icons.location_on_outlined,
                          job.location,
                          isDark
                              ? const Color(0xFFEF9A9A)
                              : Colors.red.shade400,
                          isDark,
                        ),
                        if (job.salaryMax > 0)
                          _infoChip(
                            Icons.payments_outlined,
                            'S/ ${job.salaryMin.toInt()} - ${job.salaryMax.toInt()}',
                            isDark
                                ? const Color(0xFFA5D6A7)
                                : Colors.green.shade500,
                            isDark,
                          ),
                        _infoChip(
                          Icons.work_outline,
                          job.jobType,
                          isDark
                              ? const Color(0xFF90CAF9)
                              : Colors.blue.shade500,
                          isDark,
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

  Widget _infoChip(IconData icon, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.08),
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
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyJobBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'TUYO',
        style: TextStyle(
          color: isDark ? const Color(0xFF81C784) : Colors.green.shade700,
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
    _scrollController.dispose();
    super.dispose();
  }
}

class FilterResult {
  final String? jobType;
  final double? minSalary;
  final double? maxSalary;
  final String? location;
  final bool remoteOnly;

  FilterResult({
    this.jobType,
    this.minSalary,
    this.maxSalary,
    this.location,
    this.remoteOnly = false,
  });
}
