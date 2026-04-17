import 'package:flutter/material.dart';
import '../core/services/app_preferences_service.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/loading_indicator.dart';

class DataEncryptionSettingsScreen extends StatefulWidget {
  const DataEncryptionSettingsScreen({super.key});

  @override
  State<DataEncryptionSettingsScreen> createState() =>
      _DataEncryptionSettingsScreenState();
}

class _DataEncryptionSettingsScreenState extends State<DataEncryptionSettingsScreen> {
  bool _isLoading = true;
  bool _encryptionEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await AppPreferencesService.isDataEncryptionEnabled();

    if (!mounted) return;

    setState(() {
      _encryptionEnabled = enabled;
      _isLoading = false;
    });
  }

  Future<void> _updateEncryptionEnabled(bool enabled) async {
    setState(() {
      _encryptionEnabled = enabled;
    });
    await AppPreferencesService.setDataEncryptionEnabled(enabled);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Data Encryption')),
        body: const LoadingIndicator(message: 'Loading encryption settings...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Encryption'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          Card(
            child: SwitchListTile.adaptive(
              value: _encryptionEnabled,
              onChanged: _updateEncryptionEnabled,
              title: const Text('Encrypt Receipt Data'),
              subtitle: const Text(
                'Protect sensitive receipt fields in local storage.',
              ),
              secondary: Icon(
                _encryptionEnabled
                    ? Icons.lock_outline
                    : Icons.lock_open_outlined,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Encryption Protection',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your data is protected with an improved encryption standard when this setting is enabled.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This setting applies to new and updated receipts. Existing encrypted records remain readable in the app.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}