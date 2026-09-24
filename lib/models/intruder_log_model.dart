class IntruderLogModel {
  final String id;
  final DateTime timestamp;
  final String? photoBase64;
  final String attemptType; // 'login', 'library', 'private_vault'
  final int failedAttempts;
  final String? userId; // Which account's session this belongs to
  final String? targetUsername; // Target account username attempted

  IntruderLogModel({
    required this.id,
    required this.timestamp,
    this.photoBase64,
    required this.attemptType,
    required this.failedAttempts,
    this.userId,
    this.targetUsername,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'photoBase64': photoBase64,
      'attemptType': attemptType,
      'failedAttempts': failedAttempts,
      'userId': userId,
      'targetUsername': targetUsername,
    };
  }

  factory IntruderLogModel.fromJson(Map<String, dynamic> json) {
    return IntruderLogModel(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      photoBase64: json['photoBase64'] as String?,
      attemptType: json['attemptType'] as String? ?? 'login',
      failedAttempts: json['failedAttempts'] as int? ?? 1,
      userId: json['userId'] as String?,
      targetUsername: json['targetUsername'] as String?,
    );
  }
}
