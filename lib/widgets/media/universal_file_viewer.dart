import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../services/download_service.dart';
import '../chat/voice_note_player.dart';

/// Inbuilt Universal File Viewer for Miralo.
/// - Inbuilt pinch & double-tap zoom for Images.
/// - Inbuilt interactive audio preview for Voice Notes & Audio.
/// - Rich preview cards for Videos, PDFs, and Documents.
/// - One-tap 'Open with System App' using open_filex.
/// - One-tap 'Save to Miralo' saving to /Download/Miralo/Category.
class UniversalFileViewer extends StatefulWidget {
  final String? filePath;
  final String? fileUrl;
  final String? fileBase64;
  final Uint8List? fileBytes;
  final String fileName;
  final String? fileType;
  final String? fileSize;
  final VoidCallback? onSaveToVault;
  final VoidCallback? onDelete;

  const UniversalFileViewer({
    super.key,
    this.filePath,
    this.fileUrl,
    this.fileBase64,
    this.fileBytes,
    required this.fileName,
    this.fileType,
    this.fileSize,
    this.onSaveToVault,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    String? filePath,
    String? fileUrl,
    String? fileBase64,
    Uint8List? fileBytes,
    required String fileName,
    String? fileType,
    String? fileSize,
    VoidCallback? onSaveToVault,
    VoidCallback? onDelete,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UniversalFileViewer(
          filePath: filePath,
          fileUrl: fileUrl,
          fileBase64: fileBase64,
          fileBytes: fileBytes,
          fileName: fileName,
          fileType: fileType,
          fileSize: fileSize,
          onSaveToVault: onSaveToVault,
          onDelete: onDelete,
        ),
      ),
    );
  }

  @override
  State<UniversalFileViewer> createState() => _UniversalFileViewerState();
}

class _UniversalFileViewerState extends State<UniversalFileViewer> {
  final TransformationController _transformationController = TransformationController();
  TapDownDetails? _doubleTapDetails;
  bool _isLoading = false;
  Uint8List? _resolvedBytes;
  String? _localSavedPath;

  @override
  void initState() {
    super.initState();
    _localSavedPath = widget.filePath;
    _resolveBytes();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _resolveBytes() async {
    if (widget.fileBytes != null) {
      _resolvedBytes = widget.fileBytes;
      return;
    }
    if (widget.fileBase64 != null && widget.fileBase64!.isNotEmpty) {
      try {
        _resolvedBytes = base64Decode(widget.fileBase64!);
        return;
      } catch (_) {}
    }
    if (_localSavedPath != null && File(_localSavedPath!).existsSync()) {
      try {
        _resolvedBytes = await File(_localSavedPath!).readAsBytes();
        return;
      } catch (_) {}
    }
    if (widget.fileUrl != null && widget.fileUrl!.startsWith('http')) {
      setState(() => _isLoading = true);
      try {
        final resp = await http.get(Uri.parse(widget.fileUrl!));
        if (resp.statusCode == 200 && mounted) {
          setState(() {
            _resolvedBytes = resp.bodyBytes;
            _isLoading = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  String get _category {
    return DownloadService.getCategory(widget.fileName, widget.fileType);
  }

  bool get _isImage =>
      _category == 'Images' ||
      widget.fileType == 'image' ||
      widget.fileType == 'gif' ||
      (widget.fileBase64 != null && widget.fileBase64!.isNotEmpty && widget.fileType != 'voice');

  bool get _isAudio =>
      _category == 'Audio' ||
      widget.fileType == 'voice' ||
      widget.fileType == 'audio';

  bool get _isVideo =>
      _category == 'Videos' ||
      widget.fileType == 'video';

  Future<String?> _ensureLocalFile() async {
    if (_localSavedPath != null && File(_localSavedPath!).existsSync()) {
      return _localSavedPath;
    }

    if (_resolvedBytes == null) {
      await _resolveBytes();
    }

    if (_resolvedBytes != null) {
      try {
        final dir = await getTemporaryDirectory();
        final cleanName = widget.fileName.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
        final file = File('${dir.path}/$cleanName');
        await file.writeAsBytes(_resolvedBytes!);
        _localSavedPath = file.path;
        return file.path;
      } catch (e) {
        debugPrint('Error preparing local temp file: $e');
      }
    }
    return null;
  }

  Future<void> _openWithSystemApp() async {
    setState(() => _isLoading = true);
    final path = await _ensureLocalFile();
    setState(() => _isLoading = false);

    if (path != null) {
      final res = await OpenFilex.open(path);
      if (res.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file: ${res.message}')),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not prepare file for opening.')),
      );
    }
  }

  Future<void> _saveToMiraloFolder() async {
    if (_resolvedBytes == null) {
      await _resolveBytes();
    }
    if (_resolvedBytes == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File data is still loading.')),
      );
      return;
    }

    if (mounted) {
      await DownloadService.downloadAndPrompt(
        context,
        fileName: widget.fileName,
        bytes: _resolvedBytes!,
        type: widget.fileType,
      );
    }
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      _transformationController.value = Matrix4.identity()
        ..translateByDouble(-position.dx * 1.5, -position.dy * 1.5, 0.0, 1.0)
        ..scaleByDouble(2.5, 2.5, 1.0, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = MiraloColors.darkBackground;
    final textPrimary = MiraloColors.darkTextPrimary;
    final textMuted = MiraloColors.darkTextMuted;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.6),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.fileName,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (widget.fileSize != null)
              Text(
                widget.fileSize!,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
            tooltip: 'Save to Miralo',
            onPressed: _saveToMiraloFolder,
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 22),
            tooltip: 'Open with System App',
            onPressed: _openWithSystemApp,
          ),
          if (widget.onSaveToVault != null || widget.onDelete != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onSelected: (val) {
                if (val == 'vault') {
                  widget.onSaveToVault?.call();
                } else if (val == 'delete') {
                  Navigator.pop(context);
                  widget.onDelete?.call();
                }
              },
              itemBuilder: (_) => [
                if (widget.onSaveToVault != null)
                  const PopupMenuItem(
                    value: 'vault',
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, size: 18, color: MiraloColors.accent),
                        SizedBox(width: 8),
                        Text('Save to Encrypted Vault'),
                      ],
                    ),
                  ),
                if (widget.onDelete != null)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, size: 18, color: MiraloColors.danger),
                        SizedBox(width: 8),
                        Text('Delete File'),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: _buildBody(context, isDark, textPrimary, textMuted),
          ),
          if (_isLoading)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: MiraloColors.accent),
              ),
            ),
          // Bottom action dock
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text('Open with System App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MiraloColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: _openWithSystemApp,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12, width: 0.8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 22),
                    tooltip: 'Save to Miralo/$_category',
                    padding: const EdgeInsets.all(14),
                    onPressed: _saveToMiraloFolder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, Color textPrimary, Color textMuted) {
    if (_isImage) {
      return GestureDetector(
        onDoubleTapDown: (details) => _doubleTapDetails = details,
        onDoubleTap: _handleDoubleTap,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 5.0,
          child: _resolvedBytes != null
              ? Image.memory(
                  _resolvedBytes!,
                  fit: BoxFit.contain,
                )
              : (widget.fileUrl != null && widget.fileUrl!.startsWith('http')
                  ? Image.network(
                      widget.fileUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => _buildErrorCard('Could not load image.'),
                    )
                  : const Center(child: CircularProgressIndicator())),
        ),
      );
    }

    if (_isAudio) {
      final payload = widget.fileUrl ?? (widget.fileBase64 != null ? 'data:audio/m4a;base64,${widget.fileBase64}' : '');
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: MiraloColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_rounded, color: MiraloColors.accent, size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                widget.fileName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.fileSize ?? 'Audio Clip',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 24),
              if (payload.isNotEmpty)
                VoiceNotePlayer(
                  audioUrlOrBase64: payload,
                  durationText: widget.fileSize,
                ),
            ],
          ),
        ),
      );
    }

    if (_isVideo) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C20),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.redAccent, size: 48),
              ),
              const SizedBox(height: 16),
              Text(
                widget.fileName,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${widget.fileSize ?? ''} • Video File',
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
                label: const Text('Play Video'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white12,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _openWithSystemApp,
              ),
            ],
          ),
        ),
      );
    }

    // Default: Document / PDF / Archive
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: MiraloColors.accentBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.fileName.toLowerCase().endsWith('.pdf')
                    ? Icons.picture_as_pdf_rounded
                    : (widget.fileName.toLowerCase().endsWith('.zip')
                        ? Icons.folder_zip_rounded
                        : Icons.description_rounded),
                color: MiraloColors.accentBlue,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.fileName,
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.fileSize ?? ''} • ${_category.toUpperCase()}',
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: MiraloColors.accent),
                  SizedBox(width: 6),
                  Text(
                    'Miralo Encrypted Storage',
                    style: TextStyle(color: MiraloColors.accent, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined, size: 48, color: Colors.white38),
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Colors.white60, fontSize: 14)),
        ],
      ),
    );
  }
}
