class Application {
  String jobTitle;
  String companyName;
  String applicantEmail;
  String applicantName;
  String employerEmail;
  DateTime applicationDate;
  String status; // pending, reviewed, accepted, rejected
  String message; // Cover letter o mensaje al empleador

  Application({
    required this.jobTitle,
    required this.companyName,
    required this.applicantEmail,
    required this.applicantName,
    required this.employerEmail,
    DateTime? applicationDate,
    this.status = 'pending',
    this.message = '',
  }) : applicationDate = applicationDate ?? DateTime.now();

  // Serialización para persistencia
  Map<String, dynamic> toJson() {
    return {
      'jobTitle': jobTitle,
      'companyName': companyName,
      'applicantEmail': applicantEmail,
      'applicantName': applicantName,
      'employerEmail': employerEmail,
      'applicationDate': applicationDate.toIso8601String(),
      'status': status,
      'message': message,
    };
  }

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      jobTitle: json['jobTitle'] ?? '',
      companyName: json['companyName'] ?? '',
      applicantEmail: json['applicantEmail'] ?? '',
      applicantName: json['applicantName'] ?? '',
      employerEmail: json['employerEmail'] ?? '',
      applicationDate:
          json['applicationDate'] != null
              ? DateTime.parse(json['applicationDate'])
              : DateTime.now(),
      status: json['status'] ?? 'pending',
      message: json['message'] ?? '',
    );
  }
}
