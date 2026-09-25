import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/vault_provider.dart';
import 'providers/ai_chat_provider.dart';
import 'providers/private_chat_provider.dart';
import 'providers/library_provider.dart';

import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/security_setup_screen.dart';
import 'screens/home/ai_home_screen.dart';
import 'screens/ai_chat/ai_chat_screen.dart';
import 'screens/private_chat/private_chat_list_screen.dart';
import 'screens/private_chat/private_chat_detail_screen.dart';
import 'screens/images/private_images_screen.dart';
import 'screens/library/library_locked_screen.dart';
import 'screens/library/library_screen.dart';
import 'screens/library/library_folder_screen.dart';
import 'screens/naughty/naughty_mode_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/settings/profile_screen.dart';
import 'screens/settings/privacy_security_screen.dart';
import 'screens/settings/ai_settings_screen.dart';
import 'screens/settings/notifications_screen.dart';
import 'screens/settings/data_controls_screen.dart';
import 'screens/hide_mode/hide_mode_screen.dart';
import 'screens/blacksheep/blacksheep_screen.dart';
import 'screens/emergency/emergency_screen.dart';

import 'services/remote_share_service.dart';

class MiraloApp extends StatelessWidget {
  final VaultProvider vault;
  final AuthProvider? auth;
  const MiraloApp({super.key, required this.vault, this.auth});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        auth != null
            ? ChangeNotifierProvider.value(value: auth!)
            : ChangeNotifierProvider(create: (_) => AuthProvider()),
        // Use the pre-loaded vault so persisted passcode is available immediately
        ChangeNotifierProvider.value(value: vault),
        ChangeNotifierProvider(create: (_) => AiChatProvider()),
        ChangeNotifierProvider(create: (_) => PrivateChatProvider()),
        ChangeNotifierProvider(create: (_) => LibraryProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'MIRALO AI',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            builder: (context, child) {
              Provider.of<PrivateChatProvider>(context, listen: false).setNavigationContext(context);
              RemoteShareService.initSharingIntentListener(context);
              return child ?? const SizedBox();
            },
            initialRoute: AppRoutes.splash,
            routes: {
              AppRoutes.splash: (_) => const SplashScreen(),
              AppRoutes.onboarding: (_) => const OnboardingScreen(),
              AppRoutes.signup: (_) => const SignUpScreen(),
              AppRoutes.login: (_) => const LoginScreen(),
              AppRoutes.securitySetup: (_) => const SecuritySetupScreen(),
              AppRoutes.home: (_) => const AiHomeScreen(),
              AppRoutes.chat: (_) => const AiChatScreen(),
              AppRoutes.privateChats: (_) => const PrivateChatListScreen(),
              AppRoutes.privateChat: (_) => const PrivateChatDetailScreen(),
              AppRoutes.images: (_) => const PrivateImagesScreen(),
              AppRoutes.libraryLocked: (_) => const LibraryLockedScreen(),
              AppRoutes.library: (_) => const LibraryScreen(),
              AppRoutes.libraryFolder: (_) => const LibraryFolderScreen(),
              AppRoutes.naughtyMode: (_) => const NaughtyModeScreen(),
              AppRoutes.settings: (_) => const SettingsScreen(),
              AppRoutes.settingsProfile: (_) => const ProfileScreen(),
              AppRoutes.settingsPrivacy: (_) => const PrivacySecurityScreen(),
              AppRoutes.settingsAi: (_) => const AiSettingsScreen(),
              AppRoutes.settingsNotifications: (_) => const NotificationsScreen(),
              AppRoutes.settingsData: (_) => const DataControlsScreen(),
              AppRoutes.hideMode: (_) => const HideModeScreen(),
              AppRoutes.emergency: (_) => const EmergencyScreen(),
              AppRoutes.blacksheep: (_) => const BlacksheepScreen(),
            },
          );
        },
      ),
    );
  }
}
