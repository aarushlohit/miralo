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
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderUsername: json['senderUsername'] as String,
      receiverId: json['receiverId'] as String,
      receiverUsername: json['receiverUsername'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }
}
