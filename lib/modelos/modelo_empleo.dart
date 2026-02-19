class Job {
  String? id; // Firestore Document ID
  String title;
  String description;
  String company;
  String location;
  String phone;
  String imagePath; // ruta local de la imagen
  String jobType; // profesional, temporal, medio-tiempo, por-obra, remoto
  double salaryMin;
  double salaryMax;
  List<String> requirements;
  DateTime postedDate;
  List<String> applicantEmails; // Emails de postulantes que aplicaron
  double relevanceScore; // Para ordenamiento por relevancia
  String employerEmail; // Email del empleador que publicó
  double matchScore; // Score de match calculado dinámicamente (no se persiste)

  // Campos para geolocalización
  double? lat;
  double? lng;

  // Campos para empleos temporales/gigs
  bool isTemporary; // Es trabajo temporal/gig
  int? durationHours; // Duración en horas (para trabajos temporales)
  DateTime? startDate; // Fecha de inicio
  DateTime? endDate; // Fecha de fin
  bool useCurrentLocation; // Usar ubicación GPS actual

  Job({
    this.id,
    required this.title,
    required this.description,
    required this.company,
    required this.location,
    required this.phone,
    this.imagePath = '',
    this.jobType = 'full-time',
    this.salaryMin = 0,
    this.salaryMax = 0,
    List<String>? requirements,
    DateTime? postedDate,
    List<String>? applicantEmails,
    this.relevanceScore = 0,
    this.employerEmail = '',
    this.matchScore = 0.0,
    this.lat,
    this.lng,
    this.isTemporary = false,
    this.durationHours,
    this.startDate,
    this.endDate,
    this.useCurrentLocation = false,
  }) : requirements = requirements ?? [],
       postedDate = postedDate ?? DateTime.now(),
       applicantEmails = applicantEmails ?? [];

  // Serialización para persistencia
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'company': company,
      'location': location,
      'phone': phone,
      'imagePath': imagePath,
      'jobType': jobType,
      'salaryMin': salaryMin,
      'salaryMax': salaryMax,
      'requirements': requirements,
      'postedDate': postedDate.toIso8601String(),
      'applicantEmails': applicantEmails,
      'relevanceScore': relevanceScore,
      'employerEmail': employerEmail,
      'lat': lat,
      'lng': lng,
      'isTemporary': isTemporary,
      'durationHours': durationHours,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'useCurrentLocation': useCurrentLocation,
    };
  }

  factory Job.fromJson(Map<String, dynamic> json) {
    return Job(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      company: json['company'] ?? '',
      location: json['location'] ?? '',
      phone: json['phone'] ?? '',
      imagePath: json['imagePath'] ?? '',
      jobType: json['jobType'] ?? 'full-time',
      salaryMin: (json['salaryMin'] ?? 0).toDouble(),
      salaryMax: (json['salaryMax'] ?? 0).toDouble(),
      requirements: List<String>.from(json['requirements'] ?? []),
      postedDate:
          json['postedDate'] != null
              ? DateTime.parse(json['postedDate'])
              : DateTime.now(),
      applicantEmails: List<String>.from(json['applicantEmails'] ?? []),
      relevanceScore: (json['relevanceScore'] ?? 0).toDouble(),
      employerEmail: json['employerEmail'] ?? '',
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      isTemporary: json['isTemporary'] ?? false,
      durationHours: json['durationHours'],
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      useCurrentLocation: json['useCurrentLocation'] ?? false,
    );
  }
}
