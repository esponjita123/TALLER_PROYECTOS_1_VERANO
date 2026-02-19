/// Modelo para mensajes de chat
class ChatMessage {
  String? id;
  String jobId;
  String senderEmail;
  String senderName;
  String receiverEmail;
  String content;
  DateTime timestamp;
  bool isRead;
  String? attachmentUrl;

  ChatMessage({
    this.id,
    required this.jobId,
    required this.senderEmail,
    required this.senderName,
    required this.receiverEmail,
    required this.content,
    DateTime? timestamp,
    this.isRead = false,
    this.attachmentUrl,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'senderEmail': senderEmail,
      'senderName': senderName,
      'receiverEmail': receiverEmail,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'attachmentUrl': attachmentUrl,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      jobId: json['jobId'] ?? '',
      senderEmail: json['senderEmail'] ?? '',
      senderName: json['senderName'] ?? '',
      receiverEmail: json['receiverEmail'] ?? '',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      attachmentUrl: json['attachmentUrl'],
    );
  }
}

/// Modelo para una conversación/chat
class ChatConversation {
  String? id;
  String jobId;
  String jobTitle;
  String employerEmail;
  String employerName;
  String applicantEmail;
  String applicantName;
  String lastMessage;
  DateTime lastMessageTime;
  int unreadCount;
  String? employerImage;
  String? applicantImage;

  ChatConversation({
    this.id,
    required this.jobId,
    required this.jobTitle,
    required this.employerEmail,
    required this.employerName,
    required this.applicantEmail,
    required this.applicantName,
    this.lastMessage = '',
    DateTime? lastMessageTime,
    this.unreadCount = 0,
    this.employerImage,
    this.applicantImage,
  }) : lastMessageTime = lastMessageTime ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'jobId': jobId,
      'jobTitle': jobTitle,
      'employerEmail': employerEmail,
      'employerName': employerName,
      'applicantEmail': applicantEmail,
      'applicantName': applicantName,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'employerImage': employerImage,
      'applicantImage': applicantImage,
    };
  }

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      jobId: json['jobId'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      employerEmail: json['employerEmail'] ?? '',
      employerName: json['employerName'] ?? '',
      applicantEmail: json['applicantEmail'] ?? '',
      applicantName: json['applicantName'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? DateTime.parse(json['lastMessageTime'])
          : DateTime.now(),
      unreadCount: json['unreadCount'] ?? 0,
      employerImage: json['employerImage'],
      applicantImage: json['applicantImage'],
    );
  }

  /// Obtiene el nombre del otro participante
  String getOtherParticipantName(String currentUserEmail) {
    return currentUserEmail == employerEmail ? applicantName : employerName;
  }

  /// Obtiene el email del otro participante
  String getOtherParticipantEmail(String currentUserEmail) {
    return currentUserEmail == employerEmail ? applicantEmail : employerEmail;
  }
}
