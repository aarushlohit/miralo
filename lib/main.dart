import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/vault_provider.dart';
import 'services/ai_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init notice: $e');
  }

  // Pre-initialize AI inference service (keys, selected model)
  await AiService.instance.init();

  // Load persisted vault credentials (passcode / library PIN) before UI.
  final vault = VaultProvider();
  await vault.loadFromStorage();

  // Load persisted user authentication session before UI.
  final auth = AuthProvider();
  await auth.loadFromStorage();

  // Set system UI overlay style for dark-first premium mobile aesthetic
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(MiraloApp(vault: vault, auth: auth));
}
