/// Utilidad para normalizar y estandarizar datos de texto (especialmente skills)
class DataNormalizer {
  /// Lista de sinónimos comunes para agrupar tecnologías
  static const Map<String, List<String>> _synonyms = {
    'flutter': ['flutter sdk', 'flutter framework', 'fluter'],
    'dart': ['dart lang', 'dartish'],
    'firebase': ['google firebase', 'fb', 'firestore'],
    'javascript': ['js', 'es6', 'ecmascript'],
    'typescript': ['ts'],
    'node': ['nodejs', 'node.js', 'node js'],
    'react': ['reactjs', 'react.js', 'react native'],
    'python': ['py', 'python3', 'python 3'],
    'sql': ['mysql', 'postgresql', 'sql server', 'sqlite'],
    'aws': ['amazon web services', 'amazon aws'],
    'ai': ['artificial intelligence', 'ia', 'ml', 'machine learning'],
  };

  /// Normaliza una cadena de texto (lowercase, trim, remoción de caracteres especiales)
  static String normalize(String text) {
    if (text.isEmpty) return '';

    // Lowercase y limpieza básica
    String normalized = text.toLowerCase().trim();

    // Remover caracteres especiales comunes que no aportan valor
    normalized = normalized.replaceAll(RegExp(r'[^\w\s\.]'), '');

    // Buscar en el mapa de sinónimos
    for (var entry in _synonyms.entries) {
      if (entry.key == normalized) return entry.key;

      if (entry.value.contains(normalized)) {
        return entry.key;
      }

      // Búsqueda inversa parcial (si el texto contiene el sinónimo)
      for (var synonym in entry.value) {
        if (normalized.contains(synonym)) {
          return entry.key;
        }
      }
    }

    return normalized;
  }

  /// Normaliza una lista de habilidades
  static List<String> normalizeList(List<String> list) {
    return list
        .map((item) => normalize(item))
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();
  }

  /// Calcula el ratio de coincidencia entre dos listas de skills (0.0 a 1.0)
  static double calculateMatchRatio(
    List<String> userSkills,
    List<String> requiredSkills,
  ) {
    if (requiredSkills.isEmpty) return 1.0;
    if (userSkills.isEmpty) return 0.0;

    final nUser = normalizeList(userSkills);
    final nReq = normalizeList(requiredSkills);

    int matches = 0;
    for (var req in nReq) {
      if (nUser.any((u) => u.contains(req) || req.contains(u))) {
        matches++;
      }
    }

    return (matches / nReq.length).clamp(0.0, 1.0);
  }
}
