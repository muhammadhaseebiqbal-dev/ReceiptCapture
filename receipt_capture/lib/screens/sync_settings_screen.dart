import 'package:flutter/material.dart';
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
  
  @override
  void dispose() {
    _syncService = null;
    super.dispose();
  }
  
  Future<void> _initializeSyncService() async {
    if (!mounted) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Always use singleton instance for consistency
      final receiptRepository = ReceiptRepository.instance;
      
      // Initialize sync service - it should work without credentials for offline-first mode
      _syncService = SyncService(receiptRepository, prefs);
      
      await _loadSettings();
      
      debugPrint('=== SYNC SERVICE: Initialized successfully in offline-first mode');
    } catch (e) {
      debugPrint('=== SYNC SERVICE: Error initializing sync service: $e');
      debugPrint('=== SYNC SERVICE: App will continue in offline-only mode');
      
      // Set default values if initialization fails - app still works offline
      if (mounted) {
        setState(() {
          _currentSyncMode = SyncMode.manual;
          _autoSyncInterval = 30;
          _lastSyncTime = null;
          _pendingSyncCount = 0;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Future<void> _loadSettings() async {
    if (_syncService == null || !mounted) return;
    
    try {
      final syncMode = _syncService!.getSyncMode();
      final autoSyncInterval = _syncService!.getAutoSyncInterval();
      final lastSyncTime = _syncService!.getLastSyncTime();
      final pendingSyncCount = await _syncService!.getPendingSyncCount();
      
      debugPrint('=== SYNC SETTINGS: Loaded - Mode: $syncMode, Interval: ${autoSyncInterval}min, Pending: $pendingSyncCount');
      
      if (mounted) {
        setState(() {
          _currentSyncMode = syncMode;
          _autoSyncInterval = autoSyncInterval;
          _lastSyncTime = lastSyncTime;
          _pendingSyncCount = pendingSyncCount;
        });
      }
    } catch (e) {
      debugPrint('=== SYNC SETTINGS: Error loading settings: $e');
      debugPrint('=== SYNC SETTINGS: Using safe defaults - app works offline');
      
      // Set safe defaults - app still fully functional offline
      if (mounted) {
        setState(() {
          _currentSyncMode = SyncMode.manual;
          _autoSyncInterval = 30;
          _lastSyncTime = null;
          _pendingSyncCount = 0;
        });
      }
    }
  }
  
  Future<void> _updateSyncMode(SyncMode mode) async {
    if (_syncService == null || !mounted) return;
    
    try {
      await _syncService!.setSyncMode(mode);
      if (mounted) {
        setState(() {
          _currentSyncMode = mode;
        });
        
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Sync mode changed to ${mode.name}'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update sync mode: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  Future<void> _updateAutoSyncInterval(int minutes) async {
    if (_syncService == null || !mounted) return;
    
    try {
      await _syncService!.setAutoSyncInterval(minutes);
      if (mounted) {
        setState(() {
          _autoSyncInterval = minutes;
        });
      }
    } catch (e) {
      debugPrint('Error updating auto sync interval: $e');
      if (mounted) {
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update sync interval: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  Future<void> _performSync() async {
    if (_syncService == null || !mounted) return;
    
    // Store context references before async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    setState(() {
      _isSyncing = true;
    });
    
    try {
      final result = await _syncService!.syncNow();
      
      if (mounted) {
        // Refresh pending count and last sync time
        final pendingSyncCount = await _syncService!.getPendingSyncCount();
        final lastSyncTime = _syncService!.getLastSyncTime();
        
        setState(() {
          _pendingSyncCount = pendingSyncCount;
          _lastSyncTime = lastSyncTime;
        });
        
        // Show result
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: result.success ? AppTheme.successColor : AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
        
        // Return true to indicate sync was performed
        if (result.syncedCount > 0) {
          navigator.pop(true);
        }
      }
      
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Sync failed: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
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
          
          // Offline Mode Info
          _buildOfflineModeInfo(),
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
                    color: _pendingSyncCount > 0 ? AppTheme.warningColor.withValues(alpha: 0.1) : AppTheme.successColor.withValues(alpha: 0.1),
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
            
            Theme(
              data: Theme.of(context).copyWith(
                radioTheme: RadioThemeData(
                  fillColor: WidgetStateProperty.all(AppTheme.primaryColor),
                ),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Radio<SyncMode>(
                      value: SyncMode.manual,
                      groupValue: _currentSyncMode,
                      onChanged: (value) {
                        if (value != null) _updateSyncMode(value);
                      },
                    ),
                    title: const Text('Manual Sync'),
                    subtitle: const Text('Sync receipts only when you tap the sync button'),
                    onTap: () => _updateSyncMode(SyncMode.manual),
                  ),
                  
                  ListTile(
                    leading: Radio<SyncMode>(
                      value: SyncMode.automatic,
                      groupValue: _currentSyncMode,
                      onChanged: (value) {
                        if (value != null) _updateSyncMode(value);
                      },
                    ),
                    title: const Text('Automatic Sync'),
                    subtitle: const Text('Automatically sync receipts at regular intervals'),
                    onTap: () => _updateSyncMode(SyncMode.automatic),
                  ),
                ],
              ),
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
  
  Widget _buildOfflineModeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Offline-First Mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This app works fully offline! Your receipts are safely stored locally with PDF generation. All features work without internet connection or external credentials.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.blue[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Capture & store receipts locally\n'
            '• Generate PDFs automatically\n'
            '• Search & organize without internet\n'
            '• Sync settings ready for future cloud integration',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.blue[600],
            ),
          ),
        ],
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