import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../../core/theme/miralo_tokens.dart';
import '../../services/cloudinary_service.dart';

/// Modal sheet for recording voice notes.
class VoiceNoteRecorderSheet extends StatefulWidget {
  final Function(String audioUrlOrBase64, String durationText)? onVoiceNoteRecorded;

  const VoiceNoteRecorderSheet({
    super.key,
    this.onVoiceNoteRecorded,
  });

  static Future<void> show(
    BuildContext context, {
    Function(String audioUrlOrBase64, String durationText)? onVoiceNoteRecorded,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? MiraloColors.darkSurfacePrimary : MiraloColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MiraloRadius.bottomSheet)),
      ),
      builder: (_) => VoiceNoteRecorderSheet(onVoiceNoteRecorded: onVoiceNoteRecorded),
    );
  }

  @override
  State<VoiceNoteRecorderSheet> createState() => _VoiceNoteRecorderSheetState();
}

class _VoiceNoteRecorderSheetState extends State<VoiceNoteRecorderSheet> {
  final AudioRecorder _audioRecorder = AudioRecorder();
  int _secondsElapsed = 0;
  Timer? _timer;
  String? _recordedPath;
  bool _isPaused = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _startRecording();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _secondsElapsed = 0;
          _recordedPath = path;
          _isPaused = false;
        });

        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted && !_isPaused) {
            setState(() => _secondsElapsed++);
          }
        });
      }
    } catch (e) {
      debugPrint('Error starting voice recording: $e');
    }
  }

  Future<void> _togglePauseResume() async {
    if (_isProcessing) return;
    try {
      if (_isPaused) {
        await _audioRecorder.resume();
        setState(() => _isPaused = false);
      } else {
        await _audioRecorder.pause();
        setState(() => _isPaused = true);
      }
    } catch (e) {
      debugPrint('Error toggling pause/resume: $e');
    }
  }

  Future<void> _stopAndSend() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _timer?.cancel();

    try {
      final path = await _audioRecorder.stop();

      final finalPath = path ?? _recordedPath;
      if (finalPath != null) {
        final file = File(finalPath);
        if (file.existsSync()) {
          final bytes = await file.readAsBytes();
          final minutes = (_secondsElapsed ~/ 60).toString().padLeft(1, '0');
          final secs = (_secondsElapsed % 60).toString().padLeft(2, '0');
          final durationText = '$minutes:$secs';
          final fileName = 'voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';

          // Attempt Cloudinary upload first
          final cloudUrl = await CloudinaryService.uploadFileBytes(
            fileBytes: bytes,
            fileName: fileName,
            resourceType: 'raw',
          );

          if (mounted) Navigator.pop(context);

          if (cloudUrl != null && cloudUrl.isNotEmpty) {
            widget.onVoiceNoteRecorded?.call(cloudUrl, durationText);
          } else {
            final base64String = base64Encode(bytes);
            widget.onVoiceNoteRecorded?.call(base64String, durationText);
          }
        }
      }
    } catch (e) {
      debugPrint('Error stopping voice recording: $e');
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelRecording() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    _timer?.cancel();
    try {
      await _audioRecorder.stop();
    } catch (_) {}
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? MiraloColors.darkTextPrimary : MiraloColors.lightTextPrimary;
    final textSecondary = isDark ? MiraloColors.darkTextSecondary : MiraloColors.lightTextSecondary;

    final minutes = (_secondsElapsed ~/ 60).toString().padLeft(1, '0');
    final secs = (_secondsElapsed % 60).toString().padLeft(2, '0');
    final timerFormatted = '$minutes:$secs';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _isPaused ? Colors.amber : Colors.redAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isPaused ? 'Recording Paused' : 'Recording Voice Note...',
                  style: MiraloTypography.titleMedium(color: textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              timerFormatted,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: MiraloColors.accent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 12),
            _VoiceWaveformVisualizer(isPaused: _isPaused),
            const SizedBox(height: 8),
            Text(
              _isPaused ? 'Tap resume to continue' : 'Speak into your microphone',
              style: MiraloTypography.bodySmall(color: textSecondary),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                  label: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : _cancelRecording,
                ),
                IconButton.filledTonal(
                  icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: MiraloColors.accent),
                  iconSize: 24,
                  onPressed: _isProcessing ? null : _togglePauseResume,
                  tooltip: _isPaused ? 'Resume' : 'Pause',
                ),
                ElevatedButton.icon(
                  icon: _isProcessing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isProcessing ? 'Sending...' : 'Send Voice Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: MiraloColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isProcessing ? null : _stopAndSend,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _VoiceWaveformVisualizer extends StatefulWidget {
  final bool isPaused;
  const _VoiceWaveformVisualizer({required this.isPaused});

  @override
  State<_VoiceWaveformVisualizer> createState() => _VoiceWaveformVisualizerState();
}

class _VoiceWaveformVisualizerState extends State<_VoiceWaveformVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _VoiceWaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPaused) {
      _animController.stop();
    } else if (!_animController.isAnimating) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final val = _animController.value;
        return SizedBox(
          height: 36,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAlignment.center,
            children: List.generate(24, (index) {
              final sinFactor = (index % 5 + 1) * 0.2;
              final height = widget.isPaused
                  ? 6.0
                  : 8.0 + (24.0 * ((val + sinFactor) % 1.0));
              return Container(
                width: 3,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.isPaused
                      ? (isDark ? Colors.white30 : Colors.black26)
                      : MiraloColors.accent.withOpacity(0.6 + 0.4 * ((val + sinFactor) % 1.0)),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
