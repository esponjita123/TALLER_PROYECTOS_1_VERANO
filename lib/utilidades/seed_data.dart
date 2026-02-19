import 'package:cloud_firestore/cloud_firestore.dart';

/// Script de inserción de datos de prueba con los nuevos tipos y oficios
/// Llamar una sola vez: await SeedData.insertSampleJobs();
class SeedData {
  static Future<void> insertSampleJobs() async {
    final db = FirebaseFirestore.instance;
    final now = DateTime.now();

    final jobs = [
      // ── CONSTRUCCIÓN ──
      {
        'title': 'Maestro Albañil para Obra en El Tambo',
        'description':
            'Se necesita maestro albañil con experiencia en construcción de viviendas. Trabajo por contrato, incluye asentado de ladrillos, tarrajeo y acabados. Herramientas proporcionadas.',
        'company': 'Constructora Huanca SAC',
        'location': 'El Tambo, Huancayo',
        'phone': '964123456',
        'jobType': 'por-obra',
        'salaryMin': 2500.0,
        'salaryMax': 3500.0,
        'requirements': ['albañilería', 'pintura', 'carpintería'],
        'lat': -12.0565,
        'lng': -75.2235,
        'isTemporary': false,
      },
      {
        'title': 'Electricista Residencial',
        'description':
            'Buscamos electricista con conocimientos en instalaciones residenciales y comerciales. Debe saber leer planos eléctricos. Disponibilidad inmediata.',
        'company': 'Servicios Eléctricos Junín',
        'location': 'Huancayo, Junín',
        'phone': '964234567',
        'jobType': 'profesional',
        'salaryMin': 1800.0,
        'salaryMax': 2800.0,
        'requirements': ['electricidad', 'plomería'],
        'lat': -12.0650,
        'lng': -75.2050,
        'isTemporary': false,
      },
      {
        'title': 'Soldador para Taller de Metalurgia',
        'description':
            'Se requiere soldador con experiencia en soldadura eléctrica y autógena. Trabajo estable en taller de herrería y estructuras metálicas.',
        'company': 'Metálicas Wanka',
        'location': 'Chilca, Huancayo',
        'phone': '964345678',
        'jobType': 'profesional',
        'salaryMin': 2000.0,
        'salaryMax': 3000.0,
        'requirements': ['soldadura', 'metalurgia'],
        'lat': -12.0800,
        'lng': -75.2100,
        'isTemporary': false,
      },

      // ── TEXTIL Y CONFECCIÓN ──
      {
        'title': 'Costurera para Taller de Confecciones',
        'description':
            'Taller de confecciones busca costurera con experiencia en máquina recta e industrial. Producción de uniformes escolares y ropa deportiva. Horario de lunes a sábado.',
        'company': 'Confecciones Mantaro',
        'location': 'Huancayo Centro',
        'phone': '964456789',
        'jobType': 'profesional',
        'salaryMin': 1200.0,
        'salaryMax': 1800.0,
        'requirements': ['costura', 'sastrería', 'bordado'],
        'lat': -12.0700,
        'lng': -75.2090,
        'isTemporary': false,
      },
      {
        'title': 'Tejedora de Artesanías a Medio Tiempo',
        'description':
            'Buscamos tejedora que domine crochet y tejido a palito para producción de artesanías. Trabajo flexible desde casa, pago por pieza terminada.',
        'company': 'Artesanías del Valle',
        'location': 'San Jerónimo, Huancayo',
        'phone': '964567890',
        'jobType': 'medio-tiempo',
        'salaryMin': 800.0,
        'salaryMax': 1500.0,
        'requirements': ['tejido', 'bordado'],
        'lat': -12.0900,
        'lng': -75.2300,
        'isTemporary': false,
      },

      // ── ALIMENTOS ──
      {
        'title': 'Cocinero/a para Restaurante Turístico',
        'description':
            'Restaurante turístico busca cocinero/a con experiencia en cocina regional y criolla. Debe conocer platos típicos de Huancayo (pachamanca, trucha, papa a la huancaína).',
        'company': 'Restaurante Huancahuasi',
        'location': 'Huancayo Centro',
        'phone': '964678901',
        'jobType': 'profesional',
        'salaryMin': 1500.0,
        'salaryMax': 2200.0,
        'requirements': ['cocina', 'panadería'],
        'lat': -12.0680,
        'lng': -75.2105,
        'isTemporary': false,
      },
      {
        'title': 'Pastelero/a para Panadería',
        'description':
            'Panadería artesanal busca pastelero/a con experiencia en tortas, pasteles y postres. Conocimiento en decoración con fondant es un plus.',
        'company': 'Panadería La Espiga Dorada',
        'location': 'El Tambo, Huancayo',
        'phone': '964789012',
        'jobType': 'profesional',
        'salaryMin': 1300.0,
        'salaryMax': 1900.0,
        'requirements': ['pastelería', 'panadería', 'cocina'],
        'lat': -12.0550,
        'lng': -75.2210,
        'isTemporary': false,
      },
      {
        'title': 'Bartender para Evento Temporal',
        'description':
            'Se necesita bartender con experiencia en coctelería para evento corporativo de 3 días. Incluye montaje de barra y atención a invitados.',
        'company': 'Eventos Junín',
        'location': 'Huancayo, Junín',
        'phone': '964890123',
        'jobType': 'temporal',
        'salaryMin': 200.0,
        'salaryMax': 400.0,
        'requirements': ['bartender', 'cocina'],
        'lat': -12.0660,
        'lng': -75.2080,
        'isTemporary': true,
        'durationHours': 24,
      },

      // ── SERVICIOS ──
      {
        'title': 'Peluquera con Experiencia',
        'description':
            'Salón de belleza busca estilista con experiencia en corte, tinte y alisado. Clientela ya establecida. Comisión + sueldo base.',
        'company': 'Salón Glamour',
        'location': 'Real, Huancayo',
        'phone': '964901234',
        'jobType': 'profesional',
        'salaryMin': 1200.0,
        'salaryMax': 2500.0,
        'requirements': ['peluquería', 'barbería'],
        'lat': -12.0710,
        'lng': -75.2060,
        'isTemporary': false,
      },
      {
        'title': 'Jardinero para Mantenimiento Semanal',
        'description':
            'Se busca jardinero para mantenimiento de áreas verdes de condominio. Trabajo 3 días por semana: poda, riego, siembra. Herramientas disponibles.',
        'company': 'Condominio Los Álamos',
        'location': 'San Carlos, Huancayo',
        'phone': '964012345',
        'jobType': 'medio-tiempo',
        'salaryMin': 600.0,
        'salaryMax': 900.0,
        'requirements': ['jardinería', 'limpieza'],
        'lat': -12.0750,
        'lng': -75.2150,
        'isTemporary': false,
      },
      {
        'title': 'Conductor de Transporte Escolar',
        'description':
            'Se requiere conductor con licencia A2 para transporte escolar. Ruta fija Huancayo-El Tambo. Vehículo proporcionado. Horario mañana y tarde.',
        'company': 'Transportes Educativos SAC',
        'location': 'Huancayo - El Tambo',
        'phone': '964112233',
        'jobType': 'profesional',
        'salaryMin': 1400.0,
        'salaryMax': 1800.0,
        'requirements': ['conducción'],
        'lat': -12.0620,
        'lng': -75.2180,
        'isTemporary': false,
      },
      {
        'title': 'Mecánico Automotriz',
        'description':
            'Taller automotriz busca mecánico con experiencia en diagnóstico y reparación de motores. Conocimiento en inyección electrónica es un plus. Herramientas propias preferible.',
        'company': 'Taller Automotriz Central',
        'location': 'Chilca, Huancayo',
        'phone': '964223344',
        'jobType': 'profesional',
        'salaryMin': 1800.0,
        'salaryMax': 2800.0,
        'requirements': ['mecánica', 'electricidad'],
        'lat': -12.0830,
        'lng': -75.2050,
        'isTemporary': false,
      },

      // ── PROFESIONAL ──
      {
        'title': 'Asistente Contable Remoto',
        'description':
            'Estudio contable busca asistente para trabajo remoto. Manejo de Excel avanzado, declaraciones SUNAT, y registro de compras/ventas. Medio tiempo.',
        'company': 'Contadores Asociados Junín',
        'location': 'Remoto - Huancayo',
        'phone': '964334455',
        'jobType': 'remoto',
        'salaryMin': 1000.0,
        'salaryMax': 1500.0,
        'requirements': ['contabilidad', 'administración'],
        'lat': -12.0650,
        'lng': -75.2050,
        'isTemporary': false,
      },
      {
        'title': 'Vendedor/a para Tienda de Ropa',
        'description':
            'Tienda de ropa en Real Plaza busca vendedor/a con buena actitud y experiencia en atención al cliente. Comisión por ventas + sueldo base.',
        'company': 'Boutique Trendy',
        'location': 'Real Plaza, Huancayo',
        'phone': '964445566',
        'jobType': 'profesional',
        'salaryMin': 1100.0,
        'salaryMax': 1800.0,
        'requirements': ['ventas', 'marketing'],
        'lat': -12.0640,
        'lng': -75.2075,
        'isTemporary': false,
      },
      {
        'title': 'Cuidadora de Adulto Mayor',
        'description':
            'Familia busca persona responsable para cuidado de adulto mayor. Horario de lunes a viernes, 8am-5pm. Experiencia previa y referencias requeridas.',
        'company': 'Particular',
        'location': 'San Antonio, Huancayo',
        'phone': '964556677',
        'jobType': 'profesional',
        'salaryMin': 1200.0,
        'salaryMax': 1600.0,
        'requirements': ['cuidado_personas', 'limpieza', 'cocina'],
        'lat': -12.0720,
        'lng': -75.2200,
        'isTemporary': false,
      },
    ];

    print('🔄 Insertando ${jobs.length} empleos de prueba...');

    for (int i = 0; i < jobs.length; i++) {
      final job = jobs[i];
      job['postedDate'] =
          now
              .subtract(Duration(days: i)) // Diferentes fechas
              .toIso8601String();
      job['applicantEmails'] = <String>[];
      job['relevanceScore'] = 0.0;
      job['employerEmail'] = 'demo@wankatrabajo.com';
      job['imagePath'] = '';
      job['useCurrentLocation'] = false;
      if (job['isTemporary'] != true) {
        job['isTemporary'] = false;
      }

      await db.collection('wanka_jobs').add(job);
      print('  ✅ ${i + 1}. ${job['title']}');
    }

    print('🎉 ¡${jobs.length} empleos insertados exitosamente!');
  }
}
