import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class ZipExportDialog extends StatefulWidget {
  final List<String> selectedFiles;

  const ZipExportDialog({
    super.key,
    this.selectedFiles = const ['photo.jpg', 'video.mp4', 'notes.pdf'],
  });

  @override
  State<ZipExportDialog> createState() => _ZipExportDialogState();
}

class _ZipExportDialogState extends State<ZipExportDialog> {
  bool _protectWithPassword = true;
  final TextEditingController _passwordController =
      TextEditingController(text: '••••••••');
  bool _isCreating = false;
  double _progress = 0.0;

  void _startExport() async {
    setState(() {
      _isCreating = true;
      _progress = 0.1;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (!mounted) return;
      setState(() {
        _progress = i / 10.0;
      });
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ZIP archive created: private-vault-backup.zip'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurfacePrimary : AppColors.lightSurfacePrimary;
    final secondarySurface =
        isDark ? AppColors.darkSurfaceSecondary : AppColors.lightSurfaceSecondary;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textMuted =
        isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final borderColor =
        isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;

    return Dialog(
      backgroundColor: surfaceColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 14),
                Text(
                  'Export as ZIP',
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Selected Files Count
            Text(
              'Selected Files (${widget.selectedFiles.length})',
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            // Files Container
            Container(
              decoration: BoxDecoration(
                color: secondarySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Column(
                children: widget.selectedFiles.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  final icon = file.endsWith('.jpg') || file.endsWith('.png')
                      ? Icons.photo_outlined
                      : file.endsWith('.mp4')
                          ? Icons.videocam_outlined
                          : Icons.description_outlined;

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Icon(icon, size: 18, color: textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                file,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            Icon(Icons.check_circle,
                                size: 16, color: AppColors.success),
                          ],
                        ),
                      ),
                      if (index < widget.selectedFiles.length - 1)
                        Divider(color: borderColor, height: 1),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // Protect with password toggle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: secondarySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Protect with password',
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Switch(
                    value: _protectWithPassword,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.accentBlue,
                    onChanged: (val) {
                      setState(() => _protectWithPassword = val);
                    },
                  ),
                ],
              ),
            ),

            if (_protectWithPassword) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  prefixIcon: Icon(Icons.lock_outline, size: 18, color: textSecondary),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Keep your password safe. It cannot be recovered if lost.',
                style: TextStyle(color: textMuted, fontSize: 11),
              ),
            ],

            const SizedBox(height: 20),

            if (_isCreating) ...[
              LinearProgressIndicator(
                value: _progress,
                backgroundColor: borderColor,
                valueColor: const AlwaysStoppedAnimation(AppColors.accentBlue),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Compressing (${(_progress * 100).toInt()}%)...',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Create ZIP Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                onPressed: _isCreating ? null : _startExport,
                child: const Text(
                  'Create ZIP',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
