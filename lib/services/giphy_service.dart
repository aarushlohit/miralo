import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Representation of a GIPHY GIF.
class GiphyGif {
  final String id;
  final String title;
  final String url;
  final String previewUrl;
  final double? width;
  final double? height;

  const GiphyGif({
    required this.id,
    required this.title,
    required this.url,
    required this.previewUrl,
    this.width,
    this.height,
  });

  factory GiphyGif.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as Map<String, dynamic>? ?? {};
    
    // Choose best full-size animated GIF url
    String fullUrl = '';
    if (images['downsized_medium']?['url'] != null) {
      fullUrl = images['downsized_medium']['url'];
    } else if (images['downsized']?['url'] != null) {
      fullUrl = images['downsized']['url'];
    } else if (images['original']?['url'] != null) {
      fullUrl = images['original']['url'];
    } else if (images['fixed_height']?['url'] != null) {
      fullUrl = images['fixed_height']['url'];
    }

    // Choose best lightweight preview url
    String prevUrl = '';
    if (images['fixed_width_small']?['url'] != null) {
      prevUrl = images['fixed_width_small']['url'];
    } else if (images['fixed_height_small']?['url'] != null) {
      prevUrl = images['fixed_height_small']['url'];
    } else if (images['fixed_width']?['url'] != null) {
      prevUrl = images['fixed_width']['url'];
    } else {
      prevUrl = fullUrl;
    }

    double? w;
    double? h;
    if (images['fixed_width'] != null) {
      w = double.tryParse(images['fixed_width']['width']?.toString() ?? '');
      h = double.tryParse(images['fixed_width']['height']?.toString() ?? '');
    }

    return GiphyGif(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'GIF',
      url: fullUrl,
      previewUrl: prevUrl,
      width: w,
      height: h,
    );
  }
}

/// Thrown when the user exceeds the 100 requests / 1 hour GIPHY quota.
class GiphyRateLimitException implements Exception {
  final int remainingSeconds;

  const GiphyRateLimitException({required this.remainingSeconds});

  int get remainingMinutes => (remainingSeconds / 60).ceil();

  String get userFriendlyMessage =>
      'Rate limit reached. Please wait for cooldown ($remainingMinutes mins remaining)';

  @override
  String toString() => userFriendlyMessage;
}

/// Service providing GIPHY API search and trending with a strict sliding-window
/// rate limiter enforcing a maximum of 100 requests per 1 hour.
class GiphyService {
  static final GiphyService instance = GiphyService._();
  GiphyService._();

  static const String _defaultApiKey = 'yLGChiIPs2cLsfsS3IMtlrsExZAVbi79';
  static const String _prefsTimestampsKey = 'giphy_hourly_request_timestamps';
  static const int maxRequestsPerHour = 100;
  static const Duration windowDuration = Duration(hours: 1);

  String? _customApiKey;

  void configureApiKey(String apiKey) {
    _customApiKey = apiKey.trim();
  }

  /// Get the active GIPHY API key: custom > .env file on disk > default verified key.
  String get apiKey {
    if (_customApiKey != null && _customApiKey!.isNotEmpty) {
      return _customApiKey!;
    }
    // Attempt local .env read if available
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final lines = envFile.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('GIPHY_API_KEY=')) {
            final val = trimmed.substring('GIPHY_API_KEY='.length).trim();
            if (val.isNotEmpty) return val;
          }
        }
      }
    } catch (_) {}

    return _defaultApiKey;
  }

  /// Enforces sliding window rate limit (100 requests per 1 hour).
  /// Throws [GiphyRateLimitException] if limit exceeded.
  Future<void> checkAndRecordRequest() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    final cutoff = now - windowDuration.inMilliseconds;

    final rawList = prefs.getStringList(_prefsTimestampsKey) ?? [];
    final validTimestamps = <int>[];

    for (final raw in rawList) {
      final ts = int.tryParse(raw);
      if (ts != null && ts > cutoff) {
        validTimestamps.add(ts);
      }
    }
    validTimestamps.sort();

    if (validTimestamps.length >= maxRequestsPerHour) {
      // Exceeded limit! Find remaining cooldown time based on oldest timestamp
      final oldest = validTimestamps.first;
      final cooldownMs = (oldest + windowDuration.inMilliseconds) - now;
      final remainingSec = (cooldownMs / 1000).ceil();
      throw GiphyRateLimitException(
        remainingSeconds: remainingSec > 0 ? remainingSec : 60,
      );
    }

    // Record this request
    validTimestamps.add(now);
    await prefs.setStringList(
      _prefsTimestampsKey,
      validTimestamps.map((e) => e.toString()).toList(),
    );
  }

  /// Check remaining requests in current 1-hour window.
  Future<int> getRemainingRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now().millisecondsSinceEpoch;
      final cutoff = now - windowDuration.inMilliseconds;
      final rawList = prefs.getStringList(_prefsTimestampsKey) ?? [];
      final active = rawList
          .map((r) => int.tryParse(r))
          .where((ts) => ts != null && ts > cutoff)
          .length;
      return (maxRequestsPerHour - active).clamp(0, maxRequestsPerHour);
    } catch (_) {
      return maxRequestsPerHour;
    }
  }

  /// Reset timestamps (useful for testing or manual wipe).
  Future<void> resetRateLimiter() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsTimestampsKey);
  }

  /// Fetch trending GIFs from GIPHY.
  Future<List<GiphyGif>> getTrendingGifs({int limit = 25, int offset = 0}) async {
    await checkAndRecordRequest();

    final uri = Uri.parse(
      'https://api.giphy.com/v1/gifs/trending?api_key=$apiKey&limit=$limit&offset=$offset&rating=g',
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>?) ?? [];
      return list
          .map((item) => GiphyGif.fromJson(item as Map<String, dynamic>))
          .where((g) => g.url.isNotEmpty)
          .toList();
    } else if (response.statusCode == 429) {
      throw const GiphyRateLimitException(remainingSeconds: 3600);
    } else {
      debugPrint('GIPHY trending error: ${response.statusCode} ${response.body}');
      return [];
    }
  }

  /// Search GIFs on GIPHY.
  Future<List<GiphyGif>> searchGifs(String query, {int limit = 25, int offset = 0}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return getTrendingGifs(limit: limit, offset: offset);
    }

    await checkAndRecordRequest();

    final uri = Uri.parse(
      'https://api.giphy.com/v1/gifs/search?api_key=$apiKey&q=${Uri.encodeComponent(cleanQuery)}&limit=$limit&offset=$offset&rating=g',
    );

    final response = await http.get(uri);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final list = (data['data'] as List<dynamic>?) ?? [];
      return list
          .map((item) => GiphyGif.fromJson(item as Map<String, dynamic>))
          .where((g) => g.url.isNotEmpty)
          .toList();
    } else if (response.statusCode == 429) {
      throw const GiphyRateLimitException(remainingSeconds: 3600);
    } else {
      debugPrint('GIPHY search error: ${response.statusCode} ${response.body}');
      return [];
    }
  }
}
