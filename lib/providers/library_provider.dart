import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/library_item_model.dart';

class LibraryProvider extends ChangeNotifier {
  final List<LibraryFolderModel> _folders = [];
  final List<LibraryItemModel> _items = [];
  String? _selectedFolderId;
  String _currentTab = 'All'; // 'All', 'Images', 'Files', 'Videos'
  String _searchQuery = '';
  String? _currentUserId;
  StreamSubscription<DatabaseEvent>? _librarySubscription;

  List<LibraryFolderModel> get folders => _folders;
  List<LibraryItemModel> get items => _items;
  String? get selectedFolderId => _selectedFolderId;
  String get currentTab => _currentTab;
  String get searchQuery => _searchQuery;
  String? get currentUserId => _currentUserId;

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
    _initDefaultFolders();
  }

  void _initDefaultFolders() {
    _folders.clear();
    _folders.addAll([
      LibraryFolderModel(id: 'folder_images', name: 'Images', itemCount: 0, createdAt: DateTime.now()),
      LibraryFolderModel(id: 'folder_videos', name: 'Videos', itemCount: 0, createdAt: DateTime.now()),
      LibraryFolderModel(id: 'folder_docs', name: 'Documents', itemCount: 0, createdAt: DateTime.now()),
      LibraryFolderModel(id: 'folder_important', name: 'Important', itemCount: 0, createdAt: DateTime.now()),
      LibraryFolderModel(id: 'folder_memories', name: 'Memories', itemCount: 0, createdAt: DateTime.now()),
    ]);
  }

  String _getItemsKey(String uid) => 'miralo_library_items_$uid';
  String _getFoldersKey(String uid) => 'miralo_library_folders_$uid';

  /// Initializes session for the specific user. Strictly isolates data between accounts.
  Future<void> initUserSession(String userId) async {
    if (_currentUserId == userId) return;
    _librarySubscription?.cancel();
    _librarySubscription = null;
    _currentUserId = userId;
    _selectedFolderId = null;
    _items.clear();
    _initDefaultFolders();

    // 1. Load cached items & custom folders from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final foldersRaw = prefs.getString(_getFoldersKey(userId));
      if (foldersRaw != null && foldersRaw.isNotEmpty) {
        final List list = jsonDecode(foldersRaw);
        for (var item in list) {
          final f = LibraryFolderModel.fromJson(Map<String, dynamic>.from(item as Map));
          if (!_folders.any((existing) => existing.id == f.id)) {
            _folders.add(f);
          }
        }
      }

      final itemsRaw = prefs.getString(_getItemsKey(userId));
      if (itemsRaw != null && itemsRaw.isNotEmpty) {
        final List list = jsonDecode(itemsRaw);
        _items.clear();
        for (var item in list) {
          _items.add(LibraryItemModel.fromJson(Map<String, dynamic>.from(item as Map)));
        }
      }
      _recalculateFolderCounts();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading cached library: $e');
    }

    // 2. Real-time Firebase RTDB Sync
    try {
      final ref = FirebaseDatabase.instance.ref('users/$userId/library');
      _librarySubscription = ref.onValue.listen((event) {
        if (event.snapshot.exists && event.snapshot.value is Map) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          if (data['items'] is Map) {
            final itemsMap = Map<String, dynamic>.from(data['items'] as Map);
            final List<LibraryItemModel> loadedItems = [];
            itemsMap.forEach((k, v) {
              if (v is Map) {
                try {
                  loadedItems.add(LibraryItemModel.fromJson(Map<String, dynamic>.from(v)));
                } catch (_) {}
              }
            });
            loadedItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            _items.clear();
            _items.addAll(loadedItems);
          }

          if (data['folders'] is Map) {
            final foldersMap = Map<String, dynamic>.from(data['folders'] as Map);
            foldersMap.forEach((k, v) {
              if (v is Map) {
                try {
                  final f = LibraryFolderModel.fromJson(Map<String, dynamic>.from(v));
                  final idx = _folders.indexWhere((existing) => existing.id == f.id);
                  if (idx != -1) {
                    _folders[idx] = f;
                  } else {
                    _folders.add(f);
                  }
                } catch (_) {}
              }
            });
          }

          _recalculateFolderCounts();
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('Firebase library sync listener error: $e');
    }
  }

  void _recalculateFolderCounts() {
    for (int i = 0; i < _folders.length; i++) {
      final fid = _folders[i].id;
      final count = _items.where((it) => it.folderId == fid).length;
      _folders[i] = _folders[i].copyWith(itemCount: count);
    }
  }

  Future<void> _saveToStorageAndCloud() async {
    final uid = _currentUserId;
    if (uid == null || uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final itemsJson = jsonEncode(_items.map((i) => i.toJson()).toList());
      await prefs.setString(_getItemsKey(uid), itemsJson);

      // Only custom folders or folders with updated counts
      final foldersJson = jsonEncode(_folders.map((f) => f.toJson()).toList());
      await prefs.setString(_getFoldersKey(uid), foldersJson);

      // Sync to Firebase
      final ref = FirebaseDatabase.instance.ref('users/$uid/library');
      final Map<String, dynamic> itemsMap = {};
      for (var it in _items) {
        itemsMap[it.id] = it.toJson();
      }
      final Map<String, dynamic> foldersMap = {};
      for (var f in _folders) {
        foldersMap[f.id] = f.toJson();
      }
      await ref.set({
        'items': itemsMap,
        'folders': foldersMap,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Library save error: $e');
    }
  }

  /// Clears active user library session on logout
  void clearSession() {
    _librarySubscription?.cancel();
    _librarySubscription = null;
    _currentUserId = null;
    _selectedFolderId = null;
    _items.clear();
    _initDefaultFolders();
    notifyListeners();
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
    _saveToStorageAndCloud();
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
      cloudUrl: (mediaUrl != null && mediaUrl.startsWith('http')) ? mediaUrl : null,
      folderId: folderId ?? _selectedFolderId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      source: 'upload',
    );
    _items.insert(0, newItem);
    _recalculateFolderCounts();
    _saveToStorageAndCloud();
    notifyListeners();
  }

  void moveItem(String itemId, String? targetFolderId) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _items[index] = _items[index].copyWith(
        folderId: targetFolderId,
        clearFolderId: targetFolderId == null,
        updatedAt: DateTime.now(),
      );
      _recalculateFolderCounts();
      _saveToStorageAndCloud();
      notifyListeners();
    }
  }

  void deleteItem(String itemId) {
    _items.removeWhere((i) => i.id == itemId);
    _recalculateFolderCounts();
    _saveToStorageAndCloud();
    notifyListeners();
  }

  void renameItem(String itemId, String newName) {
    final index = _items.indexWhere((i) => i.id == itemId);
    if (index != -1 && newName.trim().isNotEmpty) {
      _items[index] = _items[index].copyWith(name: newName.trim(), updatedAt: DateTime.now());
      _saveToStorageAndCloud();
      notifyListeners();
    }
  }

  void deleteFolder(String folderId) {
    _items.removeWhere((i) => i.folderId == folderId);
    _folders.removeWhere((f) => f.id == folderId);
    if (_selectedFolderId == folderId) {
      _selectedFolderId = null;
    }
    _recalculateFolderCounts();
    _saveToStorageAndCloud();
    notifyListeners();
  }

  void emergencyWipeLibrary() {
    final uid = _currentUserId;
    if (uid != null && uid.isNotEmpty) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove(_getItemsKey(uid));
        prefs.remove(_getFoldersKey(uid));
      });
      try {
        FirebaseDatabase.instance.ref('users/$uid/library').remove();
      } catch (_) {}
    }
    _items.clear();
    _initDefaultFolders();
    _selectedFolderId = null;
    notifyListeners();
  }
}
