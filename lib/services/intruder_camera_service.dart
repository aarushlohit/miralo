import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

/// Captures actual photo using front-facing camera when unauthorized intruder attempts occur.
class IntruderCameraService {
  static Future<String?> captureFrontIntruderPhoto() async {
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;

      // Prefer front-facing camera to capture intruder's face
      final frontCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      final XFile photo = await controller.takePicture();
      final bytes = await photo.readAsBytes();
      final base64Photo = base64Encode(bytes);
      return base64Photo;
    } catch (e) {
      debugPrint('Intruder front camera capture notice: $e');
      return null;
    } finally {
      try {
        await controller?.dispose();
      } catch (_) {}
    }
  }
}
