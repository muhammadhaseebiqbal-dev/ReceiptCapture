import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../core/services/sync_service.dart';
import '../core/database/receipt_repository.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/loading_indicator.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  SyncService? _syncService;
  bool _isLoading = true;
  bool _isSyncing = false;
  
  SyncMode _currentSyncMode = SyncMode.manual;
  int _autoSyncInterval = 30;
  DateTime? _lastSyncTime;
  int _pendingSyncCount = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeSyncService();
  }
  
  Future<void> _initializeSyncService() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Try to get repository from context, if not available use singleton instance
      ReceiptRepository receiptRepository;
      try {
        receiptRepository = RepositoryProvider.of<ReceiptRepository>(context);
      } catch (e) {
        // If RepositoryProvider is not available, use singleton instance
        receiptRepository = ReceiptRepository.instance;
      }
      
      _syncService = SyncService(receiptRepository, prefs);
      
      await _loadSettings();
    } catch (e) {
      print('Error initializing sync service: $e');
      // Set default values if initialization fails
      _currentSyncMode = SyncMode.manual;
      _autoSyncInterval = 30;
      _lastSyncTime = null;
      _pendingSyncCount = 0;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadSettings() async {
    try {
      _currentSyncMode = _syncService!.getSyncMode();
      _autoSyncInterval = _syncService!.getAutoSyncInterval();
      _lastSyncTime = _syncService!.getLastSyncTime();
      _pendingSyncCount = await _syncService!.getPendingSyncCount();
    } catch (e) {
      print('Error loading sync settings: $e');
      // Set safe defaults
      _currentSyncMode = SyncMode.manual;
      _autoSyncInterval = 30;
      _lastSyncTime = null;
      _pendingSyncCount = 0;
    }
  }
  
  Future<void> _updateSyncMode(SyncMode mode) async {
    if (_syncService == null) return;
    
    await _syncService!.setSyncMode(mode);
    setState(() {
      _currentSyncMode = mode;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sync mode changed to ${mode.name}'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
  
  Future<void> _updateAutoSyncInterval(int minutes) async {
    if (_syncService == null) return;
    
    await _syncService!.setAutoSyncInterval(minutes);
    setState(() {
      _autoSyncInterval = minutes;
    });
  }
  
  Future<void> _performSync() async {
    if (_syncService == null) return;
    
    setState(() {
      _isSyncing = true;
    });
    
    try {
      final result = await _syncService!.syncNow();
      
      // Refresh pending count
      _pendingSyncCount = await _syncService!.getPendingSyncCount();
      _lastSyncTime = _syncService!.getLastSyncTime();
      
      // Show result
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? AppTheme.successColor : AppTheme.errorColor,
          duration: const Duration(seconds: 4),
        ),
      );
      
      // Return true to indicate sync was performed
      if (result.syncedCount > 0) {
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sync Settings')),
        body: const LoadingIndicator(message: 'Loading sync settings...'),
      );
    }
    
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
          if (_currentSyncMode == SyncMode.automatic) ...[
            _buildAutoSyncIntervalSection(),
            const SizedBox(height: AppTheme.spacingL),
          ],
          
          // Manual Sync Button
          _buildManualSyncSection(),
          const SizedBox(height: AppTheme.spacingL),
          
          // Sync History/Info
          _buildSyncInfoSection(),
        ],
      ),
    );
  }
  
  Widget _buildSyncStatusCard() {
    final isConnected = _pendingSyncCount >= 0; // Simplified check
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.cloud_done : Icons.cloud_off,
                  color: isConnected ? AppTheme.successColor : AppTheme.warningColor,
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
                  _currentSyncMode.name.toUpperCase(),
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
            
            RadioListTile<SyncMode>(
              title: const Text('Manual Sync'),
              subtitle: const Text('Sync receipts only when you tap the sync button'),
              value: SyncMode.manual,
              groupValue: _currentSyncMode,
              onChanged: (value) {
                if (value != null) _updateSyncMode(value);
              },
            ),
            
            RadioListTile<SyncMode>(
              title: const Text('Automatic Sync'),
              subtitle: const Text('Automatically sync receipts at regular intervals'),
              value: SyncMode.automatic,
              groupValue: _currentSyncMode,
              onChanged: (value) {
                if (value != null) _updateSyncMode(value);
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
              onChangeEnd: (value) {
                _updateAutoSyncInterval(value.round());
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
            
            _buildInfoRow(
              'Last sync:',
              _lastSyncTime != null
                  ? DateFormat('MMM dd, yyyy at HH:mm').format(_lastSyncTime!)
                  : 'Never',
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            _buildInfoRow(
              'Sync method:',
              'Email to company address',
            ),
            
            const SizedBox(height: AppTheme.spacingS),
            
            _buildInfoRow(
              'Status:',
              _pendingSyncCount == 0 ? 'All synced' : '$_pendingSyncCount pending',
            ),
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
}