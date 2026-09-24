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
  final String? ownerId;
  final List<String> adminIds;
  final String? groupBio;
  final Map<String, String> memberRoles; // userId -> role tag (e.g. 'Moderator', 'VIP')
  final String settingsPermission; // 'everyone', 'admins', 'roles'
  final String? phoneNumber;
  final String? note;
  final bool isPendingInvitation;

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
    this.ownerId,
    this.adminIds = const [],
    this.groupBio,
    Map<String, String>? memberRoles,
    this.settingsPermission = 'everyone',
    this.phoneNumber,
    this.note,
    this.isPendingInvitation = false,
  }) : memberRoles = memberRoles ?? const {};

  bool isOwner(String? userId) => userId != null && ownerId == userId;

  bool isAdmin(String? userId) {
    if (userId == null) return false;
    return isOwner(userId) || adminIds.contains(userId);
  }

  bool canEditSettings(String? userId) {
    if (userId == null) return false;
    if (isOwner(userId)) return true;
    if (settingsPermission == 'everyone') return true;
    if (settingsPermission == 'admins') return isAdmin(userId);
    if (settingsPermission == 'roles') {
      return isAdmin(userId) || memberRoles.containsKey(userId);
    }
    return isAdmin(userId);
  }

  String getRoleFor(String? userId) {
    if (userId == null) return 'Member';
    if (isOwner(userId)) return 'Owner';
    if (adminIds.contains(userId)) return 'Admin';
    if (memberRoles.containsKey(userId)) return memberRoles[userId]!;
    return 'Member';
  }

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
    String? ownerId,
    List<String>? adminIds,
    String? groupBio,
    Map<String, String>? memberRoles,
    String? settingsPermission,
    String? phoneNumber,
    String? note,
    bool? isPendingInvitation,
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
      ownerId: ownerId ?? this.ownerId,
      adminIds: adminIds ?? this.adminIds,
      groupBio: groupBio ?? this.groupBio,
      memberRoles: memberRoles ?? this.memberRoles,
      settingsPermission: settingsPermission ?? this.settingsPermission,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      note: note ?? this.note,
      isPendingInvitation: isPendingInvitation ?? this.isPendingInvitation,
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
      if (ownerId != null) 'ownerId': ownerId,
      'adminIds': adminIds,
      if (groupBio != null) 'groupBio': groupBio,
      'memberRoles': memberRoles,
      'settingsPermission': settingsPermission,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (note != null) 'note': note,
      'isPendingInvitation': isPendingInvitation,
    };
  }

  factory PrivateContactModel.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['memberIds'];
    List<String> parsedMembers = [];
    if (rawMembers is List) {
      parsedMembers = rawMembers.map((e) => e.toString()).toList();
    }

    final rawAdmins = json['adminIds'];
    List<String> parsedAdmins = [];
    if (rawAdmins is List) {
      parsedAdmins = rawAdmins.map((e) => e.toString()).toList();
    }

    final rawRoles = json['memberRoles'];
    Map<String, String> parsedRoles = {};
    if (rawRoles is Map) {
      parsedRoles = rawRoles.map((k, v) => MapEntry(k.toString(), v.toString()));
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
      ownerId: json['ownerId']?.toString(),
      adminIds: parsedAdmins,
      groupBio: json['groupBio']?.toString(),
      memberRoles: parsedRoles,
      settingsPermission: json['settingsPermission']?.toString() ?? 'everyone',
      phoneNumber: json['phoneNumber']?.toString(),
      note: json['note']?.toString(),
      isPendingInvitation: json['isPendingInvitation'] == true,
    );
  }
}
