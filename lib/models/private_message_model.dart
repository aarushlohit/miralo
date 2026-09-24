class PrivateMessageModel {
  final String id;
  final String chatId;
  final String senderId; // 'me' or contact's id
  final String? senderName;
  final String type; // 'text', 'image', 'gif', 'file'
  final String text;
  final String? mediaUrl;
  final String? fileName;
  final String? fileSize;
  final Map<String, int> reactions; // emoji -> count
  final String? imageBase64;
  final DateTime createdAt;
  final String status; // 'sent', 'delivered', 'seen'
  final String? replyToText;
  final bool isFavorite;
  final bool isPinned;
  final DateTime? pinnedAt;
  final bool isStarred;
  final bool isEdited;

  PrivateMessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    this.type = 'text',
    required this.text,
    this.mediaUrl,
    this.imageBase64,
    this.fileName,
    this.fileSize,
    Map<String, int>? reactions,
    required this.createdAt,
    this.status = 'sent',
    this.replyToText,
    this.isFavorite = false,
    this.isPinned = false,
    this.pinnedAt,
    this.isStarred = false,
    this.isEdited = false,
  }) : reactions = reactions ?? {};

  bool get isMe => senderId == 'me';
  DateTime get timestamp => createdAt;
  String? get imageUrl => mediaUrl;
  bool get isGif =>
      type == 'gif' ||
      fileSize == 'GIF' ||
      fileName?.toLowerCase().endsWith('.gif') == true ||
      mediaUrl?.toLowerCase().contains('.gif') == true ||
      mediaUrl?.toLowerCase().contains('giphy.com') == true;

  PrivateMessageModel copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? type,
    String? text,
    String? mediaUrl,
    String? imageBase64,
    String? fileName,
    String? fileSize,
    Map<String, int>? reactions,
    DateTime? createdAt,
    String? status,
    String? replyToText,
    bool? isFavorite,
    bool? isPinned,
    DateTime? pinnedAt,
    bool? isStarred,
    bool? isEdited,
  }) {
    return PrivateMessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      text: text ?? this.text,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      imageBase64: imageBase64 ?? this.imageBase64,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      reactions: reactions ?? Map<String, int>.from(this.reactions),
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      replyToText: replyToText ?? this.replyToText,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      pinnedAt: pinnedAt ?? this.pinnedAt,
      isStarred: isStarred ?? this.isStarred,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      if (senderName != null) 'senderName': senderName,
      'type': type,
      'text': text,
      'mediaUrl': mediaUrl,
      'imageBase64': imageBase64,
      'fileName': fileName,
      'fileSize': fileSize,
      'reactions': reactions,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'replyToText': replyToText,
      'isFavorite': isFavorite,
      'isPinned': isPinned,
      if (pinnedAt != null) 'pinnedAt': pinnedAt!.toIso8601String(),
      'isStarred': isStarred,
      'isEdited': isEdited,
    };
  }

  factory PrivateMessageModel.fromJson(Map<String, dynamic> json) {
    return PrivateMessageModel(
      id: json['id']?.toString() ?? 'pmsg_${DateTime.now().millisecondsSinceEpoch}',
      chatId: json['chatId']?.toString() ?? '',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString(),
      type: json['type']?.toString() ?? 'text',
      text: json['text']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString(),
      imageBase64: json['imageBase64']?.toString(),
      fileName: json['fileName']?.toString(),
      fileSize: json['fileSize']?.toString(),
      reactions: (json['reactions'] is Map)
          ? (json['reactions'] as Map).map(
              (k, v) => MapEntry(
                k.toString(),
                v is num ? v.toInt() : (int.tryParse(v.toString()) ?? 1),
              ),
            )
          : {},
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
      status: json['status']?.toString() ?? 'sent',
      replyToText: json['replyToText']?.toString(),
      isFavorite: json['isFavorite'] == true,
      isPinned: json['isPinned'] == true,
      pinnedAt: json['pinnedAt'] != null
          ? DateTime.tryParse(json['pinnedAt'].toString())
          : null,
      isStarred: json['isStarred'] == true,
      isEdited: json['isEdited'] == true,
    );
  }
}
