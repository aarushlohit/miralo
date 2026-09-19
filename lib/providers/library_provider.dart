import 'package:flutter/material.dart';
import '../models/library_item_model.dart';

class LibraryProvider extends ChangeNotifier {
  final List<LibraryFolderModel> _folders = [];
  final List<LibraryItemModel> _items = [];
  String? _selectedFolderId;
  String _currentTab = 'All'; // 'All', 'Images', 'Files', 'Videos'
  String _searchQuery = '';

  List<LibraryFolderModel> get folders => _folders;
  List<LibraryItemModel> get items => _items;
  String? get selectedFolderId => _selectedFolderId;
  String get currentTab => _currentTab;
  String get searchQuery => _searchQuery;

  LibraryFolderModel? get currentFolder {
    if (_selectedFolderId == null) return null;
    try {
      return _folders.firstWhere((f) => f.id == _selectedFolderId);
    } catch (_) {
      return null;
    }
  }

  List<LibraryItemModel> get filteredItems {
    var result = List<LibraryItemModel>.from(_items);

    if (_selectedFolderId != null) {
      result = result.where((i) => i.folderId == _selectedFolderId).toList();
    }

    if (_currentTab == 'Images') {
      result = result.where((i) => i.type == 'image').toList();
    } else if (_currentTab == 'Files') {
      result = result.where((i) => i.type == 'document' || i.type == 'file' || i.type == 'zip').toList();
    } else if (_currentTab == 'Videos') {
      result = result.where((i) => i.type == 'video').toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      result = result.where((i) => i.name.toLowerCase().contains(q)).toList();
    }

    return result;
  }

  LibraryProvider() {
    _seedLibrary();
  }

  void _seedLibrary() {
    final docsFolder = LibraryFolderModel(
      id: 'folder_docs',
      name: 'Documents',
      itemCount: 12,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    );

    final memoriesFolder = LibraryFolderModel(
      id: 'folder_memories',
      name: 'Memories',
      itemCount: 8,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    );

    final importantFolder = LibraryFolderModel(
      id: 'folder_important',
      name: 'Important',
      itemCount: 6,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );

    final imagesFolder = LibraryFolderModel(
      id: 'folder_images',
      name: 'Images',
      itemCount: 24,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
    );

    final videosFolder = LibraryFolderModel(
      id: 'folder_videos',
      name: 'Videos',
      itemCount: 17,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    );

    _folders.addAll([docsFolder, memoriesFolder, importantFolder, imagesFolder, videosFolder]);

    _items.addAll([
      LibraryItemModel(
        id: 'item_1',
        name: 'photo.jpg',
        type: 'image',
        mimeType: 'image/jpeg',
        size: '2.4 MB',
        folderId: 'folder_images',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      LibraryItemModel(
        id: 'item_2',
        name: 'video.mp4',
        type: 'video',
        mimeType: 'video/mp4',
        size: '18.6 MB',
        folderId: 'folder_videos',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      ),
      LibraryItemModel(
        id: 'item_3',
        name: 'notes.pdf',
        type: 'document',
        mimeType: 'application/pdf',
        size: '1.2 MB',
        folderId: 'folder_docs',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      LibraryItemModel(
        id: 'item_4',
        name: 'Project_Specification.docx',
        type: 'document',
        mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        size: '480 KB',
        folderId: 'folder_important',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      ),
      LibraryItemModel(
        id: 'item_5',
        name: 'Architecture_Diagram.png',
        type: 'image',
        mimeType: 'image/png',
        size: '3.1 MB',
        folderId: 'folder_images',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      LibraryItemModel(
        id: 'item_6',
        name: 'Private_Backup.zip',
        type: 'zip',
        mimeType: 'application/zip',
        size: '14.2 MB',
        folderId: 'folder_important',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ),
    ]);
  }

  void setCurrentTab(String tab) {
    _currentTab = tab;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void openFolder(String? folderId) {
    _selectedFolderId = folderId;
    notifyListeners();
  }

  void createFolder(String name) {
    if (name.trim().isEmpty) return;
    final newFolder = LibraryFolderModel(
      id: 'folder_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      itemCount: 0,
      createdAt: DateTime.now(),
    );
    _folders.add(newFolder);
    notifyListeners();
  }

  void uploadItem({
    required String name,
    required String type,
    required String size,
    String? mediaUrl,
    String? folderId,
  }) {
    final newItem = LibraryItemModel(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      type: type,
      mimeType: type == 'image'
          ? 'image/jpeg'
          : type == 'video'
              ? 'video/mp4'
              : 'application/octet-stream',
      size: size,
      thumbnailUrl: mediaUrl,
      folderId: folderId ?? _selectedFolderId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      source: 'upload',
    );
    _items.insert(0, newItem);

    // Increment item count if uploaded inside a folder
    final targetFolderId = folderId ?? _selectedFolderId;
    if (targetFolderId != null) {
      final fIndex = _folders.indexWhere((f) => f.id == targetFolderId);
      if (fIndex != -1) {
        _folders[fIndex] = _folders[fIndex].copyWith(itemCount: _folders[fIndex].itemCount + 1);
      }
    }
    notifyListeners();
  }

  void deleteItem(String itemId) {
    final item = _items.firstWhere((i) => i.id == itemId, orElse: () => _items.first);
    if (item.folderId != null) {
      final fIndex = _folders.indexWhere((f) => f.id == item.folderId);
      if (fIndex != -1 && _folders[fIndex].itemCount > 0) {
        _folders[fIndex] = _folders[fIndex].copyWith(itemCount: _folders[fIndex].itemCount - 1);
      }
    }
    _items.removeWhere((i) => i.id == itemId);
    notifyListeners();
  }

  void renameItem(String itemId, String newName) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && newName.trim().isNotEmpty) {
      _items[index] = _items[index].copyWith(name: newName.trim(), updatedAt: DateTime.now());
      notifyListeners();
    }
  }

  void deleteFolder(String folderId) {
    _items.removeWhere((i) => i.folderId == folderId);
    _folders.removeWhere((f) => f.id == folderId);
    if (_selectedFolderId == folderId) {
      _selectedFolderId = null;
    }
    notifyListeners();
  }

  void emergencyWipeLibrary() {
    _items.clear();
    _folders.clear();
    _selectedFolderId = null;
    notifyListeners();
  }
}
