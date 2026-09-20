class IntruderLogModel {
  final String id;
  final DateTime timestamp;
  final String? photoBase64;
  final String attemptType; // 'login', 'library', 'private_vault'
  final int failedAttempts;

  IntruderLogModel({
    required this.id,
    required this.timestamp,
    this.photoBase64,
    required this.attemptType,
    required this.failedAttempts,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'photoBase64': photoBase64,
      'attemptType': attemptType,
      'failedAttempts': failedAttempts,
    };
  }

  factory IntruderLogModel.fromJson(Map<String, dynamic> json) {
    return IntruderLogModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      photoBase64: json['photoBase64'] as String?,
      attemptType: json['attemptType'] as String? ?? 'login',
      failedAttempts: json['failedAttempts'] as int? ?? 1,
    );
  }
}
