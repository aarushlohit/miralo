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
  final bool isGroup;
  final List<String> memberIds;

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
    this.isGroup = false,
    this.memberIds = const [],
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
    bool? isGroup,
    List<String>? memberIds,
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
      isGroup: isGroup ?? this.isGroup,
      memberIds: memberIds ?? this.memberIds,
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
      'isGroup': isGroup,
      'memberIds': memberIds,
    };
  }

  factory PrivateContactModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['memberIds'];
    List<String> parsedMembers = [];
    if (rawMembers is List) {
      parsedMembers = rawMembers.map((e) => e.toString()).toList();
    }

    return PrivateContactModel(
      id: json['id']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? 'User',
      username: json['username']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
      isOnline: json['isOnline'] == true,
      lastSeenText: json['lastSeenText']?.toString() ?? 'recently',
      isMuted: json['isMuted'] == true,
      isPinned: json['isPinned'] == true,
      unreadCount: json['unreadCount'] is num
          ? (json['unreadCount'] as num).toInt()
          : (int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0),
      isGroup: json['isGroup'] == true,
      memberIds: parsedMembers,
    );
  }
}
