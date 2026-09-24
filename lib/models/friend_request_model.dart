class FriendRequestModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderUsername;
  final String receiverId;
  final String receiverUsername;
  final String status; // 'pending', 'accepted', 'rejected'
  final DateTime createdAt;

  FriendRequestModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderUsername,
    required this.receiverId,
    required this.receiverUsername,
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'senderUsername': senderUsername,
      'receiverId': receiverId,
      'receiverUsername': receiverUsername,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory FriendRequestModel.fromJson(Map<String, dynamic> json) {
    return FriendRequestModel(
      id: json['id']?.toString() ?? 'req_${DateTime.now().millisecondsSinceEpoch}',
      senderId: json['senderId']?.toString() ?? '',
      senderName: json['senderName']?.toString() ?? 'User',
      senderUsername: json['senderUsername']?.toString() ?? '',
      receiverId: json['receiverId']?.toString() ?? '',
      receiverUsername: json['receiverUsername']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt'] != null
          ? (DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }
}
