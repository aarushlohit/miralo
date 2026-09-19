class PrivateContactModel {
  final String id;
  final String displayName;
  final String username;
  final String? avatarUrl;
  final bool isOnline;
  final String lastSeenText;
  final bool isMuted;
  final bool isPinned;
  final int unreadCount;

  PrivateContactModel({
    required this.id,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenText = 'recently',
    this.isMuted = false,
    this.isPinned = false,
    this.unreadCount = 0,
  });

  PrivateContactModel copyWith({
    String? id,
    String? displayName,
    String? username,
    String? avatarUrl,
    bool? isOnline,
    String? lastSeenText,
    bool? isMuted,
    bool? isPinned,
    int? unreadCount,
  }) {
    return PrivateContactModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      lastSeenText: lastSeenText ?? this.lastSeenText,
      isMuted: isMuted ?? this.isMuted,
      isPinned: isPinned ?? this.isPinned,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'username': username,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'lastSeenText': lastSeenText,
      'isMuted': isMuted,
      'isPinned': isPinned,
      'unreadCount': unreadCount,
    };
  }

  factory PrivateContactModel.fromJson(Map<String, dynamic> json) {
    return PrivateContactModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      lastSeenText: json['lastSeenText'] as String? ?? 'recently',
      isMuted: json['isMuted'] as bool? ?? false,
      isPinned: json['isPinned'] as bool? ?? false,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
