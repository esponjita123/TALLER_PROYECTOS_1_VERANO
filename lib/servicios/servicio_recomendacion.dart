import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../modelos/modelo_empleo.dart';
import '../modelos/modelo_usuario.dart';
import '../utilidades/normalizador_datos.dart';

class RecommendationService {
  static Interpreter? _interpreter;
  static Map<String, dynamic>? _encoders;
  static bool isModelLoaded = false;
  static int _modelInputSize = 4; // 4 default, 6 for v2

  // Initialize TFLite model and load encoders
  static Future<void> initialize() async {
    try {
      // Load interpreter
      // En Android usamos la CPU por compatibilidad y estabilidad
      // final options = InterpreterOptions();
      // options.addDelegate(GpuDelegateV2());

      _interpreter = await Interpreter.fromAsset(
        'assets/ml/modelo_recomendacion.tflite',
      );

      // Load encoders
      final jsonString = await rootBundle.loadString('assets/ml/encoders.json');
      _encoders = json.decode(jsonString);

      // Detect model version
      if (_encoders!.containsKey('types')) {
        _modelInputSize = 6;
        print('✅ TFLite: Modelo v2 cargado (6 features, oficios)');
      } else {
        _modelInputSize = 4;
        print('✅ TFLite: Modelo v1 cargado (4 features, legacy)');
      }

      isModelLoaded = true;
    } catch (e) {
      print('❌ Error inicializando modelo recomendaciones: $e');
      isModelLoaded = false;
    }
  }

  // Calculate match score between a job and a user
  static double calculateRelevanceScore(Job job, AppUser user) {
    if (user.skills.isEmpty) {
      return 0.0; // Sin skills del usuario no hay match
    }

    if (job.requirements.isEmpty) {
      return 0.0; // Si el empleo no pide nada, no es un "match" específico (o es genérico)
    }

    // 1. Rule-based score (Base logic)
    Map<String, double> rules = _calculateRuleBasedScore(job, user);
    double ruleScore = rules['total']!;

    // Si no hay ninguna coincidencia de habilidades, el score no debería ser alto
    // independientemente de otros factores (ubicación, salario, mood).
    // Penalizamos fuertemente si skillMatchRatio es muy bajo.
    if (rules['skillMatchRatio']! < 0.1) {
      // Si coincide menos del 10% de skills, el score máximo posible es bajo (ej. 30%)
      return (ruleScore * 0.3).clamp(0.0, 30.0);
    }

    // 2. ML Score (AI logic)
    double mlScore = 0.0;
    if (isModelLoaded) {
      mlScore = _calculateMLScore(job, user);
    } else {
      // Fallback si no hay modelo: confiamos 100% en reglas
      return ruleScore;
    }

    // 3. Hybrid Weighted Score
    // Damos más peso al ML si existe y hay coincidencia de skills
    final mlWeight = _modelInputSize == 6 ? 0.60 : 0.50; // 60% ML, 40% Reglas

    double finalScore = ((mlScore * mlWeight) + (ruleScore * (1 - mlWeight)));

    return finalScore.clamp(0.0, 100.0);
  }

  // --- Rule Based Logic ---

  static Map<String, double> _calculateRuleBasedScore(Job job, AppUser user) {
    double score = 0.0;

    // 1. Skill Match (40%)
    double skillMatchRatio = DataNormalizer.calculateMatchRatio(
      user.skills,
      job.requirements,
    );
    score += skillMatchRatio * 40;

    // 2. Experience Level (20%)
    // Simple heuristic: if user level matches job requirement implicit level
    // (This is rudimentary, V2 model handles this better)
    score += 15; // Base score for experience existing

    // 3. Location Match (20%) - Bonus if same location
    bool locationMatch = false;
    if (job.location.toLowerCase().contains(user.location.toLowerCase()) ||
        user.location.toLowerCase().contains(job.location.toLowerCase())) {
      score += 20;
      locationMatch = true;
    }

    // 4. Job Freshness (10%)
    final daysOld = DateTime.now().difference(job.postedDate).inDays;
    if (daysOld < 3)
      score += 10;
    else if (daysOld < 7)
      score += 5;

    // 5. Job Type Preference (10%)
    // Si el usuario tiene preferencia por este tipo de trabajo (implícito)
    // Por ahora asumimos neutralidad -> +5
    score += 5;

    return {
      'total': score.clamp(0.0, 100.0),
      'skillMatchRatio': skillMatchRatio,
      'locationMatch': locationMatch ? 1.0 : 0.0,
    };
  }

  // --- ML Score Logic ---

  static double _calculateMLScore(Job job, AppUser user) {
    if (_encoders == null || _interpreter == null) return 50.0;

    try {
      // Prepare input vector
      // Features: [Skill_Encoded, Job_Type_Encoded, Level_Encoded, Location_Match, ... ]

      // Tomamos la primera skill del usuario (principal) o 'unknown'
      String userSkill =
          user.skills.isNotEmpty
              ? DataNormalizer.normalize(user.skills.first)
              : 'unknown';

      // Tomamos el tipo de trabajo
      String jobType =
          job.jobType.isNotEmpty
              ? DataNormalizer.normalize(job.jobType)
              : 'full-time';

      // Codificamos
      int skillEncoded = _encodeValue('skills', userSkill);
      int typeEncoded = _encodeValue('types', jobType);

      // Debug prints para entender por qué da valores estáticos
      // print('ML Input: Skill="$userSkill"($skillEncoded), Type="$jobType"($typeEncoded)');

      // Construimos el input tensor según la versión del modelo
      List<double> input;

      if (_modelInputSize == 6) {
        // Modelo V2: [skill, type, level, location_match, remote, salary]
        // Mapeo dummy para level (asumimos intermedio=1), location=1 si coincide
        double locationMatch =
            job.location.toLowerCase().contains('huancayo') ? 1.0 : 0.0;

        input = [
          skillEncoded.toDouble(),
          typeEncoded.toDouble(),
          1.0, // Level (dummy intermedio)
          locationMatch,
          job.jobType == 'remoto' ? 1.0 : 0.0,
          0.5, // Salary normalized (dummy)
        ];
      } else {
        // Modelo V1 Legacy
        input = [
          skillEncoded.toDouble(),
          _encodeValue('titulos', job.title).toDouble(),
          1.0,
          1.0,
        ];
      }

      // Output buffer: [1, 1] -> probabilidad 0..1
      var output = List<double>.filled(1, 0).reshape([1, 1]);

      // Run inference
      _interpreter!.run(input.reshape([1, _modelInputSize]), output);

      // Retornar probabilidad * 100
      return (output[0][0] as double) * 100.0;
    } catch (e) {
      print('⚠️ Error inferencia ML: $e');
      return 50.0; // Fallback neutral
    }
  }

  static int _encodeValue(String category, String value) {
    if (_encoders == null || !_encoders!.containsKey(category)) return 0;

    final map = _encoders![category] as Map<String, dynamic>;
    if (map.containsKey(value)) {
      return map[value] as int;
    }

    // Si no encuentra el valor exacto, intentamos buscar por palabras clave
    // Ej: "maestro albañil" -> buscar "albañil"
    for (var key in map.keys) {
      if (value.contains(key) || key.contains(value)) {
        return map[key] as int;
      }
    }

    return 0; // Unknown/Other
  }

  // --- Helpers ---

  static List<Job> getRecommendedJobs(List<Job> allJobs, AppUser user) {
    if (user.skills.isEmpty) return [];

    // Calcular score para cada empleo y guardarlo temporalmente
    for (var job in allJobs) {
      job.matchScore = calculateRelevanceScore(job, user);
    }

    // Filtrar empleos con match > 0 (o un umbral mínimo, ej 30%)
    final recommended = allJobs.where((j) => j.matchScore >= 30.0).toList();

    // Ordenar descendente
    recommended.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return recommended;
  }

  // Fallback ranking (simple rules)
  static List<Job> rankJobsByRelevance(List<Job> allJobs, AppUser user) {
    // Si no hay modelo o falló, usamos solo reglas pero con la misma penalización
    for (var job in allJobs) {
      job.matchScore = calculateRelevanceScore(job, user);
    }
    allJobs.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return allJobs;
  }

  static double calculateApplicantMatch(Job job, AppUser applicant) {
    return calculateRelevanceScore(job, applicant);
  }

  static Map<String, dynamic> getMatchBreakdown(Job job, AppUser user) {
    // Retorna detalles para la UI ("Por qué este empleo")
    List<String> details = [];

    // Skill match
    double skillRatio = DataNormalizer.calculateMatchRatio(
      user.skills,
      job.requirements,
    );
    if (skillRatio >= 0.8)
      details.add('Tus habilidades coinciden perfectamente.');
    else if (skillRatio >= 0.5)
      details.add('Tienes varias habilidades requeridas.');
    else if (skillRatio > 0)
      details.add('Tienes algunas habilidades útiles.');

    // Location
    if (job.location.toLowerCase().contains(user.location.toLowerCase())) {
      details.add('El empleo está en tu zona (${user.location}).');
    }

    // Type
    details.add('Es un trabajo tipo ${_getJobTypeLabel(job.jobType)}.');

    return {'score': job.matchScore, 'details': details};
  }

  static String getMatchExplanation(Job job, AppUser user) {
    double skillRatio = DataNormalizer.calculateMatchRatio(
      user.skills,
      job.requirements,
    );
    if (skillRatio >= 0.8) return 'Coincidencia perfecta de habilidades';
    if (skillRatio >= 0.5) return 'Varias habilidades coinciden';
    if (skillRatio > 0.1) return 'Algunas habilidades coinciden';

    if (job.location.toLowerCase().contains(user.location.toLowerCase()) &&
        user.location.isNotEmpty) {
      return 'Cerca de tu ubicación';
    }

    return 'Recomendado por IA';
  }

  static String _getJobTypeLabel(String type) {
    switch (type) {
      case 'profesional':
        return 'Profesional';
      case 'temporal':
        return 'Temporal / Eventual';
      case 'medio-tiempo':
        return 'Medio Tiempo';
      case 'por-obra':
        return 'Por Obra / Proyecto';
      case 'remoto':
        return 'Remoto';
      default:
        return 'Tiempo Completo';
    }
  }
}
