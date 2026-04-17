import 'package:flutter/material.dart';
import '../core/services/app_preferences_service.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/loading_indicator.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  bool _syncRemindersEnabled = true;
  bool _weeklySummaryEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled =
        await AppPreferencesService.isNotificationsEnabled();
    final syncRemindersEnabled =
        await AppPreferencesService.isSyncRemindersEnabled();
    final weeklySummaryEnabled =
        await AppPreferencesService.isWeeklySummaryEnabled();

    if (!mounted) return;

    setState(() {
      _notificationsEnabled = notificationsEnabled;
      _syncRemindersEnabled = syncRemindersEnabled;
      _weeklySummaryEnabled = weeklySummaryEnabled;
      _isLoading = false;
    });
  }

  Future<void> _updateNotificationsEnabled(bool enabled) async {
    setState(() {
      _notificationsEnabled = enabled;
    });
    await AppPreferencesService.setNotificationsEnabled(enabled);
  }

  Future<void> _updateSyncRemindersEnabled(bool enabled) async {
    setState(() {
      _syncRemindersEnabled = enabled;
    });
    await AppPreferencesService.setSyncRemindersEnabled(enabled);
  }

  Future<void> _updateWeeklySummaryEnabled(bool enabled) async {
    setState(() {
      _weeklySummaryEnabled = enabled;
    });
    await AppPreferencesService.setWeeklySummaryEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notifications')),
        body: const LoadingIndicator(message: 'Loading notification settings...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          Card(
            child: SwitchListTile.adaptive(
              value: _notificationsEnabled,
              onChanged: _updateNotificationsEnabled,
              title: const Text('Enable Notifications'),
              subtitle: const Text(
                'Turn app notifications on or off.',
              ),
              secondary: const Icon(Icons.notifications_active_outlined),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Card(
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  value: _syncRemindersEnabled,
                  onChanged: _notificationsEnabled
                      ? _updateSyncRemindersEnabled
                      : null,
                  title: const Text('Sync Reminders'),
                  subtitle: const Text(
                    'Receive reminders when receipts are waiting to sync.',
                  ),
                  secondary: const Icon(Icons.cloud_sync_outlined),
                ),
                const Divider(height: 1),
                SwitchListTile.adaptive(
                  value: _weeklySummaryEnabled,
                  onChanged: _notificationsEnabled
                      ? _updateWeeklySummaryEnabled
                      : null,
                  title: const Text('Weekly Summary'),
                  subtitle: const Text(
                    'Get a weekly summary of captured and synced receipts.',
                  ),
                  secondary: const Icon(Icons.summarize_outlined),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}