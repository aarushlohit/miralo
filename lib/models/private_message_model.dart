class PrivateMessageModel {
  final String id;
  final String chatId;
  final String senderId; // 'me' or contact's id
  final String type; // 'text', 'image', 'gif', 'file'
  final String text;
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final Map<String, int> reactions; // emoji -> count
  final DateTime createdAt;
  final String status; // 'sent', 'delivered', 'read'
  final String? replyToText;

  PrivateMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.type = 'text',
    required this.text,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    Map<String, int>? reactions,
    required this.createdAt,
    this.status = 'read',
    this.replyToText,
  }) : reactions = reactions ?? {};

  bool get isMe => senderId == 'me';
  DateTime get timestamp => createdAt;
  String? get imageUrl => mediaUrl;

  PrivateMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? type,
    String? text,
    String? mediaUrl,
    String? fileName,
    String? fileSize,
    Map<String, int>? reactions,
    DateTime? createdAt,
    String? status,
    String? replyToText,
  }) {
    return PrivateMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      reactions: reactions ?? Map<String, int>.from(this.reactions),
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      replyToText: replyToText ?? this.replyToText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
      'fileSize': fileSize,
      'reactions': reactions,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'replyToText': replyToText,
    };
  }

  factory PrivateMessageModel.fromJson(Map<String, dynamic> json) {
    return PrivateMessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      type: json['type'] as String? ?? 'text',
      text: json['text'] as String? ?? '',
      mediaUrl: json['mediaUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as String?,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v as int),
          ) ??
          {},
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'read',
      replyToText: json['replyToText'] as String?,
    );
  }
}
