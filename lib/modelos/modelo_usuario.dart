class AppUser {
  String name;
  String email;
  String password;
  String role; // postulante o empresa
  String phone;
  String bio;
  List<String> skills;
  String experience; // Para postulantes: Junior, Mid, Senior
  String profileImagePath;
  List<String> searchHistory;

  AppUser({
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
    this.phone = '',
    this.bio = '',
    List<String>? skills,
    this.experience = '',
    this.profileImagePath = '',
    List<String>? searchHistory,
  }) : skills = skills ?? [],
       searchHistory = searchHistory ?? [];

  // Serialización para persistencia
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
      'bio': bio,
      'skills': skills,
      'experience': experience,
      'profileImagePath': profileImagePath,
      'searchHistory': searchHistory,
    };
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
      phone: json['phone'] ?? '',
      bio: json['bio'] ?? '',
      skills: List<String>.from(json['skills'] ?? []),
      experience: json['experience'] ?? '',
      profileImagePath: json['profileImagePath'] ?? '',
      searchHistory: List<String>.from(json['searchHistory'] ?? []),
    );
  }
}
