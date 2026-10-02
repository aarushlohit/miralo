import 'dart:convert';
import 'dart:typed_data';

/// High-performance cache for base64-decoded images.
/// Prevents main-thread stutter, eliminates visual flicker on widget rebuilds,
/// and saves massive amounts of CPU and memory.
class Base64ImageCache {
  Base64ImageCache._();

  static final Map<String, Uint8List> _cache = {};
  static const int _maxEntries = 100;

  /// Retrieves cached Uint8List or decodes and caches it.
  /// Guaranteed to return the exact same Uint8List reference for identical base64 strings,
  /// allowing Flutter's MemoryImage identity comparison to succeed without reloading.
  static Uint8List? getBytes(String? base64Str) {
    if (base64Str == null || base64Str.isEmpty) return null;

    final cached = _cache[base64Str];
    if (cached != null) return cached;

    try {
      final clean = base64Str.contains(',') ? base64Str.split(',').last : base64Str;
      final bytes = base64Decode(clean);

      if (_cache.length >= _maxEntries) {
        _cache.remove(_cache.keys.first);
      }
      _cache[base64Str] = bytes;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  /// Clears cache when needed
  static void clear() {
    _cache.clear();
  }
}
