import 'package:shared_preferences/shared_preferences.dart';

class AppPreferencesService {
  static const _notificationsEnabledKey = 'notifications_enabled';
  static const _syncRemindersEnabledKey = 'sync_reminders_enabled';
  static const _weeklySummaryEnabledKey = 'weekly_summary_enabled';
  static const _dataEncryptionEnabledKey = 'data_encryption_enabled';

  static const bool _defaultNotificationsEnabled = true;
  static const bool _defaultSyncRemindersEnabled = true;
  static const bool _defaultWeeklySummaryEnabled = false;
  static const bool _defaultDataEncryptionEnabled = true;

  static Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ??
        _defaultNotificationsEnabled;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  static Future<bool> isSyncRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_syncRemindersEnabledKey) ??
        _defaultSyncRemindersEnabled;
  }

  static Future<void> setSyncRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_syncRemindersEnabledKey, enabled);
  }

  static Future<bool> isWeeklySummaryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_weeklySummaryEnabledKey) ??
        _defaultWeeklySummaryEnabled;
  }

  static Future<void> setWeeklySummaryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_weeklySummaryEnabledKey, enabled);
  }

  static Future<bool> isDataEncryptionEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dataEncryptionEnabledKey) ??
        _defaultDataEncryptionEnabled;
  }

  static Future<void> setDataEncryptionEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dataEncryptionEnabledKey, enabled);
  }
}