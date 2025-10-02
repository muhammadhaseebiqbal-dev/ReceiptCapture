import 'package:flutter/material.dart';
import '../shared/theme/app_theme.dart';

class SimpleSyncSettingsScreen extends StatefulWidget {
  const SimpleSyncSettingsScreen({super.key});

  @override
  State<SimpleSyncSettingsScreen> createState() => _SimpleSyncSettingsScreenState();
}

class _SimpleSyncSettingsScreenState extends State<SimpleSyncSettingsScreen> {
  bool _isAutoSync = false;
  int _autoSyncInterval = 30;
  int _pendingSyncCount = 0;
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Settings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        children: [
          // Sync Status Card
          _buildSyncStatusCard(),
          const SizedBox(height: AppTheme.spacingL),
          
          // Sync Mode Settings
          _buildSyncModeSection(),
          const SizedBox(height: AppTheme.spacingL),
          
          // Auto Sync Interval (only show if automatic mode)
          if (_isAutoSync) ...[
            _buildAutoSyncIntervalSection(),
            const SizedBox(height: AppTheme.spacingL),
          ],
          
          // Manual Sync Button
          _buildManualSyncSection(),
          const SizedBox(height: AppTheme.spacingL),
          
          // Sync Info
          _buildSyncInfoSection(),
        ],
      ),
    );
  }
  
  Widget _buildSyncStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_done,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: AppTheme.spacingS),
                Text(
                  'Sync Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pending receipts:', style: AppTheme.bodyMedium),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _pendingSyncCount > 0 ? AppTheme.warningColor.withOpacity(0.1) : AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _pendingSyncCount > 0 ? AppTheme.warningColor : AppTheme.successColor,
                    ),
                  ),
                  child: Text(
                    '$_pendingSyncCount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _pendingSyncCount > 0 ? AppTheme.warningColor : AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sync mode:', style: AppTheme.bodyMedium),
                Text(
                  _isAutoSync ? 'AUTOMATIC' : 'MANUAL',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSyncModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Mode',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            RadioListTile<bool>(
              title: const Text('Manual Sync'),
              subtitle: const Text('Sync receipts only when you tap the sync button'),
              value: false,
              groupValue: _isAutoSync,
              onChanged: (value) {
                setState(() {
                  _isAutoSync = value!;
                });
              },
            ),
            
            RadioListTile<bool>(
              title: const Text('Automatic Sync'),
              subtitle: const Text('Automatically sync receipts at regular intervals'),
              value: true,
              groupValue: _isAutoSync,
              onChanged: (value) {
                setState(() {
                  _isAutoSync = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAutoSyncIntervalSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto Sync Interval',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            Text(
              'Sync every $_autoSyncInterval minutes',
              style: AppTheme.bodyMedium,
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            Slider(
              value: _autoSyncInterval.toDouble(),
              min: 5,
              max: 120,
              divisions: 23,
              label: '$_autoSyncInterval min',
              onChanged: (value) {
                setState(() {
                  _autoSyncInterval = value.round();
                });
              },
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('5 min', style: AppTheme.bodySmall),
                Text('120 min', style: AppTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildManualSyncSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manual Sync',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingS),
            
            Text(
              'Tap the button below to sync all pending receipts now.',
              style: AppTheme.bodyMedium.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: AppTheme.spacingM),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSyncing || _pendingSyncCount == 0 ? null : _performSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: Text(
                  _isSyncing
                      ? 'Syncing...'
                      : _pendingSyncCount == 0
                          ? 'Nothing to Sync'
                          : 'Sync Now ($_pendingSyncCount items)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSyncInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingM),
            
            _buildInfoRow('Last sync:', 'Never'),
            const SizedBox(height: AppTheme.spacingS),
            _buildInfoRow('Sync method:', 'Email to company address'),
            const SizedBox(height: AppTheme.spacingS),
            _buildInfoRow('Status:', 'All synced'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTheme.bodyMedium),
        Text(
          value,
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _performSync() async {
    setState(() {
      _isSyncing = true;
    });

    // Simulate sync process
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isSyncing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sync completed successfully!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}