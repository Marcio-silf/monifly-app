import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../datasources/local/shared_prefs_helper.dart';
import '../../core/constants/app_constants.dart';

// Theme mode provider
class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved = SharedPrefsHelper.getString(AppConstants.keyThemeMode);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  void setTheme(ThemeMode mode) {
    state = mode;
    String key = 'system';
    if (mode == ThemeMode.dark) key = 'dark';
    if (mode == ThemeMode.light) key = 'light';
    SharedPrefsHelper.setString(AppConstants.keyThemeMode, key);
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    SharedPrefsHelper.setString(
      AppConstants.keyThemeMode,
      state == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);

// Balance visibility
class BalanceVisibilityNotifier extends Notifier<bool> {
  @override
  bool build() => SharedPrefsHelper.getBool(
    AppConstants.keyBalanceVisible,
    defaultValue: true,
  );

  void toggle() {
    state = !state;
    SharedPrefsHelper.setBool(AppConstants.keyBalanceVisible, state);
  }
}

final balanceVisibleProvider =
    NotifierProvider<BalanceVisibilityNotifier, bool>(
      BalanceVisibilityNotifier.new,
    );

// Notifications enabled
final notificationsEnabledProvider = StateProvider<bool>(
  (ref) => SharedPrefsHelper.getBool(
    AppConstants.keyNotificationsEnabled,
    defaultValue: true,
  ),
);

// Biometric enabled
final biometricEnabledProvider = StateProvider<bool>(
  (ref) => SharedPrefsHelper.getBool(
    AppConstants.keyBiometricEnabled,
    defaultValue: false,
  ),
);

