class LibraryFolderModel {
  final String id;
  final String name;
  final int itemCount;
  final DateTime createdAt;

  LibraryFolderModel({
    required this.id,
    required this.name,
    required this.itemCount,
    required this.createdAt,
  });

  LibraryFolderModel copyWith({
    String? id,
    String? name,
    int? itemCount,
    DateTime? createdAt,
  }) {
    return LibraryFolderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      itemCount: itemCount ?? this.itemCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'itemCount': itemCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LibraryFolderModel.fromJson(Map<String, dynamic> json) {
    return LibraryFolderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      itemCount: json['itemCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class LibraryItemModel {
  final String id;
  final String name;
  final String type; // 'image', 'video', 'document', 'file', 'zip'
  final String mimeType;
  final String size;
  final String? folderId;
  final String? thumbnailUrl;
  final String? cloudUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isEncrypted;
  final String source; // 'upload', 'private_chat', 'saved'

  bool get isSavedToCloud =>
      (cloudUrl != null && cloudUrl!.isNotEmpty) ||
      (thumbnailUrl != null &&
          (thumbnailUrl!.startsWith('http://') ||
              thumbnailUrl!.startsWith('https://')));

  LibraryItemModel({
    required this.id,
    required this.name,
    required this.type,
    required this.mimeType,
    required this.size,
    this.folderId,
    this.thumbnailUrl,
    this.cloudUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isEncrypted = true,
    this.source = 'upload',
  });

  LibraryItemModel copyWith({
    String? id,
    String? name,
    String? type,
    String? mimeType,
    String? size,
    String? folderId,
    bool clearFolderId = false,
    String? thumbnailUrl,
    String? cloudUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isEncrypted,
    String? source,
  }) {
    return LibraryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      cloudUrl: cloudUrl ?? this.cloudUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'mimeType': mimeType,
      'size': size,
      'folderId': folderId,
      'thumbnailUrl': thumbnailUrl,
      'cloudUrl': cloudUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isEncrypted': isEncrypted,
      'source': source,
    };
  }

  factory LibraryItemModel.fromJson(Map<String, dynamic> json) {
    return LibraryItemModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      mimeType: json['mimeType'] as String,
      size: json['size'] as String,
      folderId: json['folderId'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      cloudUrl: json['cloudUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isEncrypted: json['isEncrypted'] as bool? ?? true,
      source: json['source'] as String? ?? 'upload',
    );
  }
}
