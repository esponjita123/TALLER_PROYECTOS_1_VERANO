/// Utilidad para normalizar y estandarizar datos de texto (especialmente skills/oficios)
class DataNormalizer {
  /// Lista de sinónimos para agrupar oficios y habilidades
  static const Map<String, List<String>> _synonyms = {
    // ── Construcción y mantenimiento ──
    'albañilería': ['albañil', 'construcción', 'obra civil', 'mampostería'],
    'carpintería': ['carpintero', 'madera', 'muebles de madera'],
    'ebanistería': ['ebanista', 'mueblería', 'restauración de muebles'],
    'pintura': ['pintor', 'pintado', 'acabados', 'pintura de casas'],
    'electricidad': ['electricista', 'instalaciones eléctricas', 'cableado'],
    'plomería': [
      'plomero',
      'gasfitero',
      'gasfitería',
      'instalaciones sanitarias',
    ],
    'soldadura': [
      'soldador',
      'soldar',
      'soldadura eléctrica',
      'soldadura autógena',
    ],
    'metalurgia': [
      'metalúrgico',
      'herrería',
      'herrero',
      'forja',
      'cerrajería',
      'cerrajero',
    ],
    'vidriería': ['vidriero', 'cristalería', 'instalación de vidrios'],

    // ── Textil y confección ──
    'costura': [
      'costurera',
      'costurero',
      'confección',
      'modista',
      'modistería',
    ],
    'sastrería': ['sastre', 'trajes', 'ropa a medida'],
    'bordado': ['bordador', 'bordadora', 'bordados', 'bordado a mano'],
    'tejido': ['tejedora', 'tejedor', 'crochet', 'punto', 'tejido a palito'],

    // ── Alimentos ──
    'cocina': ['cocinero', 'cocinera', 'chef', 'gastronomía', 'culinaria'],
    'panadería': ['panadero', 'panadera', 'pan', 'horneado'],
    'pastelería': [
      'pastelero',
      'pastelera',
      'repostería',
      'repostero',
      'tortas',
    ],
    'bartender': ['barman', 'barista', 'bartending', 'mixología', 'café'],

    // ── Servicios ──
    'limpieza': ['limpiador', 'mantenimiento', 'aseo', 'servicio de limpieza'],
    'jardinería': ['jardinero', 'jardinera', 'paisajismo', 'podado', 'césped'],
    'peluquería': [
      'peluquero',
      'peluquera',
      'estilista',
      'corte de cabello',
      'salón de belleza',
    ],
    'barbería': ['barbero', 'barbera', 'barber shop'],
    'conducción': ['conductor', 'chofer', 'manejo', 'transporte', 'taxi'],
    'mecánica': [
      'mecánico',
      'reparación de vehículos',
      'automotriz',
      'taller mecánico',
    ],
    'cuidado_personas': [
      'niñera',
      'cuidador',
      'cuidadora',
      'enfermería',
      'cuidado de niños',
      'cuidado de adultos mayores',
      'asistente del hogar',
    ],

    // ── Profesional / tech ──
    'contabilidad': ['contador', 'contadora', 'finanzas', 'tributación'],
    'ventas': [
      'vendedor',
      'vendedora',
      'comercio',
      'atención al cliente',
      'retail',
    ],
    'administración': [
      'administrador',
      'administradora',
      'gestión',
      'oficina',
      'secretaria',
    ],
    'diseño': [
      'diseñador',
      'diseñadora',
      'diseño gráfico',
      'photoshop',
      'canva',
    ],
    'programación': [
      'programador',
      'desarrollador',
      'developer',
      'software',
      'flutter',
      'dart',
      'react',
      'python',
      'java',
      'javascript',
      'node',
      'web',
      'app',
      'móvil',
      'frontend',
      'backend',
    ],
    'marketing': [
      'publicidad',
      'redes sociales',
      'community manager',
      'seo',
      'social media',
    ],

    // ── Legacy tech (compatibilidad) ──
    'firebase': ['google firebase', 'fb', 'firestore'],
    'sql': ['mysql', 'postgresql', 'sql server', 'sqlite', 'base de datos'],
    'aws': ['amazon web services', 'amazon aws', 'nube', 'cloud'],
    'ai': [
      'artificial intelligence',
      'ia',
      'ml',
      'machine learning',
      'inteligencia artificial',
    ],
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
  /// Incluye coincidencias parciales por grupo de oficios
  static double calculateMatchRatio(
    List<String> userSkills,
    List<String> requiredSkills,
  ) {
    if (requiredSkills.isEmpty) return 1.0;
    if (userSkills.isEmpty) return 0.0;

    final nUser = normalizeList(userSkills);
    final nReq = normalizeList(requiredSkills);

    double totalScore = 0.0;
    for (var req in nReq) {
      // Match exacto
      if (nUser.any((u) => u.contains(req) || req.contains(u))) {
        totalScore += 1.0;
        continue;
      }

      // Match parcial por grupo
      double bestPartial = 0.0;
      for (var u in nUser) {
        if (_areInSameGroup(u, req)) {
          bestPartial = bestPartial < 0.4 ? 0.4 : bestPartial;
        }
      }
      totalScore += bestPartial;
    }

    return (totalScore / nReq.length).clamp(0.0, 1.0);
  }

  /// Grupos de oficios relacionados para matching parcial
  static const Map<String, List<String>> _skillGroups = {
    'construcción': [
      'albañilería',
      'carpintería',
      'ebanistería',
      'pintura',
      'electricidad',
      'plomería',
      'soldadura',
      'metalurgia',
      'vidriería',
    ],
    'textil': ['costura', 'sastrería', 'bordado', 'tejido'],
    'alimentos': ['cocina', 'panadería', 'pastelería', 'bartender'],
    'belleza': ['peluquería', 'barbería'],
    'profesional': [
      'contabilidad',
      'ventas',
      'administración',
      'diseño',
      'programación',
      'marketing',
    ],
    'servicios': [
      'limpieza',
      'jardinería',
      'conducción',
      'mecánica',
      'cuidado_personas',
    ],
  };

  /// Verifica si dos skills están en el mismo grupo
  static bool _areInSameGroup(String s1, String s2) {
    for (var group in _skillGroups.values) {
      if (group.contains(s1) && group.contains(s2)) {
        return true;
      }
    }
    return false;
  }
}
