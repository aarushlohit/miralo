class AiMessageModel {
  final String id;
  final String role; // 'user' or 'assistant'
  final String text;
  final DateTime timestamp;
  final bool? liked; // true = thumbs up, false = thumbs down, null = neutral

  AiMessageModel({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.liked,
  });

  AiMessageModel copyWith({
    String? id,
    String? role,
    String? text,
    DateTime? timestamp,
    bool? liked,
    bool clearLiked = false,
  }) {
    return AiMessageModel(
      id: id ?? this.id,
      role: role ?? this.role,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      liked: clearLiked ? null : (liked ?? this.liked),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'liked': liked,
    };
  }

  factory AiMessageModel.fromJson(Map<String, dynamic> json) {
    return AiMessageModel(
      id: json['id'] as String,
      role: json['role'] as String,
      text: json['text'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      liked: json['liked'] as bool?,
    );
  }
}

class AiChatModel {
  final String id;
  final String title;
  final List<AiMessageModel> messages;
  final bool isPinned;
  final DateTime createdAt;
  final DateTime updatedAt;

  AiChatModel({
    required this.id,
    required this.title,
    required this.messages,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  AiChatModel copyWith({
    String? id,
    String? title,
    List<AiMessageModel>? messages,
    bool? isPinned,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AiChatModel(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages.map((m) => m.toJson()).toList(),
      'isPinned': isPinned,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AiChatModel.fromJson(Map<String, dynamic> json) {
    return AiChatModel(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((m) => AiMessageModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      isPinned: json['isPinned'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
