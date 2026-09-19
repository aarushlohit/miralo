import 'package:flutter/material.dart';

class HideModeSettings {
  bool isEnabled;
  bool hideUsername;
  bool hideProfilePicture;
  bool hidePrivateChatNames;
  bool hideMessagePreviews;
  bool hideNotificationContent;

  HideModeSettings({
    this.isEnabled = false,
    this.hideUsername = true,
    this.hideProfilePicture = true,
    this.hidePrivateChatNames = true,
    this.hideMessagePreviews = true,
    this.hideNotificationContent = true,
  });

  HideModeSettings copyWith({
    bool? isEnabled,
    bool? hideUsername,
    bool? hideProfilePicture,
    bool? hidePrivateChatNames,
    bool? hideMessagePreviews,
    bool? hideNotificationContent,
  }) {
    return HideModeSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      hideUsername: hideUsername ?? this.hideUsername,
      hideProfilePicture: hideProfilePicture ?? this.hideProfilePicture,
      hidePrivateChatNames: hidePrivateChatNames ?? this.hidePrivateChatNames,
      hideMessagePreviews: hideMessagePreviews ?? this.hideMessagePreviews,
      hideNotificationContent:
          hideNotificationContent ?? this.hideNotificationContent,
    );
  }
}

class VaultProvider extends ChangeNotifier {
  // Credentials
  String _privateChatSecret = '1234';
  String _libraryPin = '1234';

  // Independent session states
  bool _isPrivateUnlocked = false;
  bool _isLibraryUnlocked = false;

  // Auto-lock setting (in minutes; 0 = immediate, 5 = 5 min, -1 = never)
  int _autoLockMinutes = 5;

  // Hide Mode settings
  HideModeSettings _hideMode = HideModeSettings();

  // Getters
  bool get isPrivateUnlocked => _isPrivateUnlocked;
  bool get isLibraryUnlocked => _isLibraryUnlocked;
  bool get hasPrivateSecret => _privateChatSecret.isNotEmpty;
  bool get hasLibraryPin => _libraryPin.isNotEmpty;
  int get autoLockMinutes => _autoLockMinutes;
  HideModeSettings get hideMode => _hideMode;

  // Private Chat unlock/lock
  bool verifyPasscode(String inputSecret) =>
      inputSecret.trim() == _privateChatSecret;

  bool unlockPrivate(String inputSecret) {
    if (verifyPasscode(inputSecret)) {
      _isPrivateUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockPrivate() {
    _isPrivateUnlocked = false;
    notifyListeners();
  }

  // Library Vault unlock/lock
  bool unlockLibrary(String inputPin) {
    if (inputPin.trim() == _libraryPin) {
      _isLibraryUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockLibrary() {
    _isLibraryUnlocked = false;
    notifyListeners();
  }

  // Lock both
  void lockAll() {
    _isPrivateUnlocked = false;
    _isLibraryUnlocked = false;
    notifyListeners();
  }

  // Update credentials
  void setPrivateChatSecret(String newSecret) {
    _privateChatSecret = newSecret.trim();
    notifyListeners();
  }

  void setLibraryPin(String newPin) {
    _libraryPin = newPin.trim();
    notifyListeners();
  }

  void setAutoLockMinutes(int minutes) {
    _autoLockMinutes = minutes;
    notifyListeners();
  }

  // Hide Mode controls
  void updateHideMode({
    bool? isEnabled,
    bool? hideUsername,
    bool? hideProfilePicture,
    bool? hidePrivateChatNames,
    bool? hideMessagePreviews,
    bool? hideNotificationContent,
  }) {
    _hideMode = _hideMode.copyWith(
      isEnabled: isEnabled,
      hideUsername: hideUsername,
      hideProfilePicture: hideProfilePicture,
      hidePrivateChatNames: hidePrivateChatNames,
      hideMessagePreviews: hideMessagePreviews,
      hideNotificationContent: hideNotificationContent,
    );
    notifyListeners();
  }

  // Emergency Panic Actions
  void emergencyLockEverything() {
    _isPrivateUnlocked = false;
    _isLibraryUnlocked = false;
    _hideMode.isEnabled = true;
    notifyListeners();
  }
}
