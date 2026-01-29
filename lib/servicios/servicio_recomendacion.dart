import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../modelos/modelo_empleo.dart';
import '../modelos/modelo_usuario.dart';
import '../utilidades/normalizador_datos.dart';

/// Servicio de recomendación de empleos e inteligencia de matching
class RecommendationService {
  static Interpreter? _interpreter;
  static Map<String, dynamic>? _encoders;

  /// Inicializa el motor de TFLite
  static Future<void> initialize() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/ml/modelo_recomendacion.tflite',
      );
      final encoderString = await rootBundle.loadString(
        'assets/ml/encoders.json',
      );
      _encoders = json.decode(encoderString);
      print('TFLite: Modelo cargado exitosamente');
    } catch (e) {
      print(
        'TFLite Error: No se pudo cargar el modelo. Usando sistema de reglas. $e',
      );
    }
  }

  /// Calcula el score de relevancia entre un empleo y un usuario (0.0 a 100.0)
  static double calculateRelevanceScore(Job job, AppUser user) {
    if (_interpreter != null && _encoders != null) {
      return _calculateMLScore(job, user);
    }

    // Sistema basado en reglas mejorado
    double score = 0.0;

    // 1. Skill Match Ratio (50% del score total) - Usando Normalizador
    final matchRatio = DataNormalizer.calculateMatchRatio(
      user.skills,
      job.requirements,
    );
    score += matchRatio * 50.0;

    // 2. Experience Level Match (20% del score total)
    score += _calculateExperienceMatch(job, user) * 0.20;

    // 3. Location History (15% del score total)
    score += _calculateLocationMatch(job, user) * 0.15;

    // 4. Freshness & Salary (15% del score total)
    score += _calculateFreshnessScore(job) * 0.08;
    score += _calculateSalaryScore(job) * 0.07;

    return score.clamp(0.0, 100.0);
  }

  /// Ordena una lista de empleos por relevancia para el usuario
  static List<Job> rankJobsByRelevance(List<Job> jobs, AppUser user) {
    for (var job in jobs) {
      job.matchScore = calculateRelevanceScore(job, user);
    }
    jobs.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return jobs;
  }

  /// Filtra solo los empleos altamente recomendados (score > 60)
  static List<Job> getRecommendedJobs(List<Job> jobs, AppUser user) {
    final rankedJobs = rankJobsByRelevance(jobs, user);
    return rankedJobs.where((job) => job.matchScore > 60).toList();
  }

  /// Ordena una lista de usuarios (postulantes) por idoneidad para un empleo
  static List<AppUser> rankApplicants(Job job, List<AppUser> applicants) {
    // Clasificar postulantes basándose en el score relativo al empleo
    applicants.sort((a, b) {
      final scoreA = calculateRelevanceScore(job, a);
      final scoreB = calculateRelevanceScore(job, b);
      return scoreB.compareTo(scoreA);
    });
    return applicants;
  }

  // ========== MÉTODOS PRIVADOS DE CÁLCULO ==========

  /// Calcula coincidencia de nivel de experiencia (retorna 0-100)
  static double _calculateExperienceMatch(Job job, AppUser user) {
    if (user.experience.isEmpty) return 50.0;

    final Map<String, int> levels = {
      'junior': 1,
      'mid': 2,
      'senior': 3,
      'lead': 4,
    };
    final userLevel = _extractLevel(user.experience, levels);
    final jobLevel = _extractLevel('${job.title} ${job.description}', levels);

    final diff = (userLevel - jobLevel).abs();
    if (diff == 0) return 100.0;
    if (diff == 1) return 70.0;
    return 30.0;
  }

  static int _extractLevel(String text, Map<String, int> levels) {
    final t = text.toLowerCase();
    if (t.contains('lead') || t.contains('principal')) return 4;
    if (t.contains('senior') || t.contains('sr')) return 3;
    if (t.contains('mid') || t.contains('semi')) return 2;
    if (t.contains('junior') || t.contains('jr') || t.contains('entry'))
      return 1;
    return 2; // Mid por defecto
  }

  static double _calculateLocationMatch(Job job, AppUser user) {
    if (user.searchHistory.isEmpty) return 50.0;
    final loc = DataNormalizer.normalize(job.location);
    for (var term in user.searchHistory) {
      if (loc.contains(DataNormalizer.normalize(term))) return 100.0;
    }
    return 20.0;
  }

  static double _calculateFreshnessScore(Job job) {
    final days = DateTime.now().difference(job.postedDate).inDays;
    if (days <= 3) return 100.0;
    if (days <= 7) return 80.0;
    if (days <= 14) return 60.0;
    return 30.0;
  }

  static double _calculateSalaryScore(Job job) {
    return (job.salaryMin > 0 || job.salaryMax > 0) ? 100.0 : 50.0;
  }

  /// Genera explicación textual del match para la UI
  static String getMatchExplanation(Job job, AppUser user) {
    final score = calculateRelevanceScore(job, user);
    if (score > 85) return '🔥 Match Perfecto para tu perfil';
    if (score > 70) return '✨ Gran coincidencia de habilidades';
    if (score > 50) return '👍 Buen match con tu experiencia';
    return 'Explora este empleo';
  }

  // ========== MÉTODOS DE INFERENCIA ML EXPANDIDA ==========

  static double _calculateMLScore(Job job, AppUser user) {
    try {
      // Inputs expandidos (8-10 features en el futuro, por ahora adaptamos el vector)
      // Aseguramos que el input shape [1, 4] coincida con el modelo actual,
      // pero mejoramos la calidad de lo que enviamos usando el normalizador.

      final uSkillEnc = _encodeValue(
        user.skills.isNotEmpty
            ? DataNormalizer.normalize(user.skills.first)
            : 'flutter',
        'skills',
      );
      final jSkillEnc = _encodeValue(
        job.requirements.isNotEmpty
            ? DataNormalizer.normalize(job.requirements.first)
            : 'flutter',
        'skills',
      );

      final uLevelEnc = _encodeValue(user.experience.toLowerCase(), 'levels');
      final jLevelEnc = _encodeValue(_extractJobLevel(job), 'levels');

      var input = [
        [
          uSkillEnc.toDouble(),
          uLevelEnc.toDouble(),
          jSkillEnc.toDouble(),
          jLevelEnc.toDouble(),
        ],
      ];

      var output = List.filled(1, List.filled(1, 0.0)).reshape([1, 1]);
      _interpreter!.run(input, output);

      return (output[0][0] * 100).clamp(0.0, 100.0);
    } catch (e) {
      return 50.0;
    }
  }

  static int _encodeValue(String value, String type) {
    if (_encoders == null) return 0;
    final list = _encoders![type] as List;
    final index = list.indexOf(value.toLowerCase());
    return index != -1 ? index : 0;
  }

  static String _extractJobLevel(Job job) {
    final text = '${job.title} ${job.description}'.toLowerCase();
    if (text.contains('lead')) return 'lead';
    if (text.contains('senior')) return 'senior';
    if (text.contains('junior')) return 'junior';
    return 'mid';
  }
}
