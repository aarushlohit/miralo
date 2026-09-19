import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class CameraViewSheet extends StatefulWidget {
  final Function(String capturedPhotoUrl) onPhotoCaptured;

  const CameraViewSheet({super.key, required this.onPhotoCaptured});

  @override
  State<CameraViewSheet> createState() => _CameraViewSheetState();
}

class _CameraViewSheetState extends State<CameraViewSheet> {
  bool _isFlashOn = false;
  bool _isFrontCamera = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.92,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Top bar controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 26),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on : Icons.flash_off,
                    color: _isFlashOn ? AppColors.warning : Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() => _isFlashOn = !_isFlashOn);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.hdr_auto_outlined, color: Colors.white, size: 24),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white, size: 24),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Viewfinder simulation
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black,
                    const Color(0xFF1F1E24),
                    const Color(0xFF382E39).withValues(alpha: 0.5),
                    const Color(0xFFE07A5F).withValues(alpha: 0.3),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
              ),
              child: Stack(
                children: [
                  // Center focus reticle
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  // Bottom mode selector
                  Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'PHOTO',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom capture controls
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Gallery Thumbnail
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF222222),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: const Icon(Icons.photo, color: Colors.white70, size: 22),
                ),

                // Shutter Button
                GestureDetector(
                  onTap: () {
                    // Capture photo simulation
                    Navigator.pop(context);
                    widget.onPhotoCaptured('mock_sunset');
                  },
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),

                // Flip Camera Button
                IconButton(
                  icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
                  onPressed: () {
                    setState(() => _isFrontCamera = !_isFrontCamera);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
