import '../modelos/modelo_empleo.dart';
import '../modelos/modelo_usuario.dart';

/// Servicio de recomendación de empleos usando algoritmo basado en reglas
class RecommendationService {
  /// Calcula el score de relevancia entre un empleo y un usuario
  /// Retorna un valor entre 0 y 100
  static double calculateRelevanceScore(Job job, AppUser user) {
    double score = 0.0;

    // Factor 1: Skills Match (40% del score total)
    score += _calculateSkillsMatch(job, user) * 0.4;

    // Factor 2: Experience Level (25% del score total)
    score += _calculateExperienceMatch(job, user) * 0.25;

    // Factor 3: Location History (15% del score total)
    score += _calculateLocationMatch(job, user) * 0.15;

    // Factor 4: Job Freshness (10% del score total)
    score += _calculateFreshnessScore(job) * 0.10;

    // Factor 5: Salary Range (10% del score total)
    score += _calculateSalaryScore(job) * 0.10;

    return score.clamp(0.0, 100.0);
  }

  /// Ordena una lista de empleos por relevancia para el usuario
  static List<Job> rankJobsByRelevance(List<Job> jobs, AppUser user) {
    // Calcular y asignar matchScore a cada empleo
    for (var job in jobs) {
      job.matchScore = calculateRelevanceScore(job, user);
    }

    // Ordenar por matchScore descendente
    jobs.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return jobs;
  }

  /// Filtra solo los empleos altamente recomendados (score > 60)
  static List<Job> getRecommendedJobs(List<Job> jobs, AppUser user) {
    final rankedJobs = rankJobsByRelevance(jobs, user);
    return rankedJobs.where((job) => job.matchScore > 60).toList();
  }

  // ========== MÉTODOS PRIVADOS DE CÁLCULO ==========

  /// Calcula coincidencia de skills (retorna 0-100)
  static double _calculateSkillsMatch(Job job, AppUser user) {
    if (job.requirements.isEmpty || user.skills.isEmpty) {
      return 30.0; // Score neutral si no hay datos
    }

    int matches = 0;
    int totalRequirements = job.requirements.length;

    for (var requirement in job.requirements) {
      // Buscar coincidencias flexibles (case insensitive, substring)
      final reqLower = requirement.toLowerCase();

      for (var skill in user.skills) {
        final skillLower = skill.toLowerCase();

        // Match exacto o parcial
        if (skillLower.contains(reqLower) || reqLower.contains(skillLower)) {
          matches++;
          break; // Solo contar una vez por requirement
        }
      }
    }

    // Calcular porcentaje de requirements cubiertos
    double matchPercentage = (matches / totalRequirements) * 100;

    // Bonus: si el usuario tiene más skills que los requeridos
    if (user.skills.length > totalRequirements) {
      matchPercentage += 5.0;
    }

    return matchPercentage.clamp(0.0, 100.0);
  }

  /// Calcula coincidencia de nivel de experiencia (retorna 0-100)
  static double _calculateExperienceMatch(Job job, AppUser user) {
    if (user.experience.isEmpty) {
      return 50.0; // Score neutral
    }

    // Mapeo de niveles de experiencia
    final Map<String, int> experienceLevels = {
      'junior': 1,
      'mid': 2,
      'senior': 3,
      'lead': 4,
    };

    // Extraer nivel del usuario
    final userLevel = _extractExperienceLevel(
      user.experience,
      experienceLevels,
    );

    // Buscar nivel requerido en job.description o job.title
    final jobText = '${job.title} ${job.description}'.toLowerCase();
    int jobLevel = 2; // Default: mid-level

    if (jobText.contains('junior') || jobText.contains('entry')) {
      jobLevel = 1;
    } else if (jobText.contains('senior') || jobText.contains('sr.')) {
      jobLevel = 3;
    } else if (jobText.contains('lead') || jobText.contains('principal')) {
      jobLevel = 4;
    }

    // Calcular diferencia
    final levelDifference = (userLevel - jobLevel).abs();

    // Score basado en diferencia (0 = perfecto, 1 = bueno, 2+ = malo)
    if (levelDifference == 0) {
      return 100.0; // Match perfecto
    } else if (levelDifference == 1) {
      return 70.0; // Aceptable
    } else {
      return 30.0; // Mismatch significativo
    }
  }

  /// Extrae nivel numérico de experiencia
  static int _extractExperienceLevel(
    String experience,
    Map<String, int> levels,
  ) {
    final expLower = experience.toLowerCase();

    for (var entry in levels.entries) {
      if (expLower.contains(entry.key)) {
        return entry.value;
      }
    }

    return 2; // Default: mid-level
  }

  /// Calcula relevancia por ubicación (retorna 0-100)
  static double _calculateLocationMatch(Job job, AppUser user) {
    if (user.searchHistory.isEmpty) {
      return 50.0; // Score neutral
    }

    final jobLocation = job.location.toLowerCase();

    // Buscar en historial de búsquedas
    for (var searchTerm in user.searchHistory) {
      final searchLower = searchTerm.toLowerCase();

      // Match parcial o completo
      if (jobLocation.contains(searchLower) ||
          searchLower.contains(jobLocation)) {
        return 100.0; // Usuario ha buscado esta ubicación antes
      }
    }

    // No hay match directo
    return 20.0;
  }

  /// Calcula score basado en antigüedad del empleo (retorna 0-100)
  static double _calculateFreshnessScore(Job job) {
    final daysOld = DateTime.now().difference(job.postedDate).inDays;

    if (daysOld <= 3) {
      return 100.0; // Muy reciente
    } else if (daysOld <= 7) {
      return 80.0; // Reciente
    } else if (daysOld <= 14) {
      return 60.0; // Moderado
    } else if (daysOld <= 30) {
      return 40.0; // Antiguo
    } else {
      return 20.0; // Muy antiguo
    }
  }

  /// Calcula score basado en rango salarial (retorna 0-100)
  static double _calculateSalaryScore(Job job) {
    // Si no hay datos de salario, retornar neutral
    if (job.salaryMin == 0 && job.salaryMax == 0) {
      return 50.0;
    }

    // Premiar empleos con salarios definidos
    if (job.salaryMin > 0 && job.salaryMax > 0) {
      return 100.0; // Transparencia salarial es valiosa
    }

    return 70.0; // Salario parcialmente definido
  }

  /// Genera explicación textual del match
  static String getMatchExplanation(Job job, AppUser user) {
    final skillsScore = _calculateSkillsMatch(job, user);
    final expScore = _calculateExperienceMatch(job, user);
    final locationScore = _calculateLocationMatch(job, user);

    List<String> reasons = [];

    if (skillsScore > 70) {
      final matchedSkills = _getMatchedSkills(job, user);
      reasons.add('Tus skills coinciden: ${matchedSkills.join(", ")}');
    }

    if (expScore > 70) {
      reasons.add('Nivel de experiencia adecuado');
    }

    if (locationScore > 70) {
      reasons.add('Ubicación de tu interés');
    }

    if (job.postedDate.difference(DateTime.now()).inDays.abs() <= 3) {
      reasons.add('Publicado recientemente');
    }

    if (reasons.isEmpty) {
      return 'Este empleo podría interesarte';
    }

    return reasons.join(' • ');
  }

  /// Obtiene lista de skills que coinciden
  static List<String> _getMatchedSkills(Job job, AppUser user) {
    List<String> matched = [];

    for (var requirement in job.requirements) {
      final reqLower = requirement.toLowerCase();

      for (var skill in user.skills) {
        final skillLower = skill.toLowerCase();

        if (skillLower.contains(reqLower) || reqLower.contains(skillLower)) {
          matched.add(skill);
          break;
        }
      }
    }

    return matched.take(3).toList(); // Máximo 3 skills
  }
}
