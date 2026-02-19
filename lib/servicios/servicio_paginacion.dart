import 'package:cloud_firestore/cloud_firestore.dart';
import '../modelos/modelo_empleo.dart';

/// Servicio para manejar la paginación de empleos
class JobsPaginationService {
  static const int pageSize = 10;
  
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoading = false;
  
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  
  /// Resetea el estado de paginación
  void reset() {
    _lastDocument = null;
    _hasMore = true;
    _isLoading = false;
  }
  
  /// Carga la primera página de empleos
  Future<List<Job>> loadFirstPage({
    String? searchQuery,
    String? jobType,
    double? minSalary,
    double? maxSalary,
    String? location,
  }) async {
    reset();
    return _fetchJobs(
      searchQuery: searchQuery,
      jobType: jobType,
      minSalary: minSalary,
      maxSalary: maxSalary,
      location: location,
    );
  }
  
  /// Carga la siguiente página de empleos
  Future<List<Job>> loadNextPage({
    String? searchQuery,
    String? jobType,
    double? minSalary,
    double? maxSalary,
    String? location,
  }) async {
    if (!_hasMore || _isLoading) return [];
    return _fetchJobs(
      searchQuery: searchQuery,
      jobType: jobType,
      minSalary: minSalary,
      maxSalary: maxSalary,
      location: location,
    );
  }
  
  Future<List<Job>> _fetchJobs({
    String? searchQuery,
    String? jobType,
    double? minSalary,
    double? maxSalary,
    String? location,
  }) async {
    _isLoading = true;
    
    try {
      Query query = FirebaseFirestore.instance
          .collection('wanka_jobs')
          .orderBy('postedDate', descending: true)
          .limit(pageSize);
      
      // Aplicar filtros de Firestore cuando sea posible
      if (jobType != null && jobType != 'Todos') {
        query = query.where('jobType', isEqualTo: jobType.toLowerCase());
      }
      
      if (minSalary != null && minSalary > 0) {
        query = query.where('salaryMax', isGreaterThanOrEqualTo: minSalary);
      }
      
      if (location != null && location.isNotEmpty) {
        query = query.where('location', isGreaterThanOrEqualTo: location)
                     .where('location', isLessThanOrEqualTo: '$location\uf8ff');
      }
      
      // Paginación
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      
      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        _hasMore = false;
        _isLoading = false;
        return [];
      }
      
      _lastDocument = snapshot.docs.last;
      _hasMore = snapshot.docs.length == pageSize;
      
      List<Job> jobs = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Job.fromJson(data);
      }).toList();
      
      // Filtros que no se pueden hacer en Firestore (búsqueda por texto)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final queryLower = searchQuery.toLowerCase();
        jobs = jobs.where((job) {
          return job.title.toLowerCase().contains(queryLower) ||
                 job.company.toLowerCase().contains(queryLower) ||
                 job.description.toLowerCase().contains(queryLower);
        }).toList();
      }
      
      // Filtro adicional de salario máximo
      if (maxSalary != null && maxSalary > 0) {
        jobs = jobs.where((job) => job.salaryMin <= maxSalary).toList();
      }
      
      _isLoading = false;
      return jobs;
      
    } catch (e) {
      _isLoading = false;
      print('Error en paginación: $e');
      return [];
    }
  }
}
