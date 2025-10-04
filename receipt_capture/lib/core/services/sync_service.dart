import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/receipt_repository.dart';
import '../database/models.dart';

enum SyncMode { manual, automatic }

class SyncService {
  static const String _syncModeKey = 'sync_mode';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _autoSyncIntervalKey = 'auto_sync_interval';
  
  final ReceiptRepository _receiptRepository;
  final SharedPreferences _prefs;
  
  // Default to manual sync mode
  static const SyncMode _defaultSyncMode = SyncMode.manual;
  static const int _defaultAutoSyncInterval = 30; // minutes
  
  SyncService(this._receiptRepository, this._prefs);
  
  /// Get current sync mode
  SyncMode getSyncMode() {
    final modeString = _prefs.getString(_syncModeKey);
    if (modeString == null) return _defaultSyncMode;
    return SyncMode.values.firstWhere(
      (mode) => mode.name == modeString,
      orElse: () => _defaultSyncMode,
    );
  }
  
  /// Set sync mode
  Future<void> setSyncMode(SyncMode mode) async {
    await _prefs.setString(_syncModeKey, mode.name);
  }
  
  /// Get auto sync interval in minutes
  int getAutoSyncInterval() {
    return _prefs.getInt(_autoSyncIntervalKey) ?? _defaultAutoSyncInterval;
  }
  
  /// Set auto sync interval in minutes
  Future<void> setAutoSyncInterval(int minutes) async {
    await _prefs.setInt(_autoSyncIntervalKey, minutes);
  }
  
  /// Get last sync timestamp
  DateTime? getLastSyncTime() {
    final timestamp = _prefs.getInt(_lastSyncKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
  
  /// Set last sync timestamp
  Future<void> _setLastSyncTime(DateTime time) async {
    await _prefs.setInt(_lastSyncKey, time.millisecondsSinceEpoch);
  }
  
  /// Check if device is connected to internet
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
  
  /// Get count of pending sync items
  Future<int> getPendingSyncCount() async {
    try {
      final pendingItems = await _receiptRepository.getPendingSyncItems();
      return pendingItems.length;
    } catch (e) {
      print('Error getting pending sync count: $e');
      return 0;
    }
  }
  
  /// Get pending sync items
  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    return await _receiptRepository.getPendingSyncItems();
  }
  
  /// Manual sync trigger
  Future<SyncResult> syncNow() async {
    print('Starting manual sync...');
    
    if (!await isConnected()) {
      return SyncResult(
        success: false,
        message: 'No internet connection available',
        syncedCount: 0,
        failedCount: 0,
      );
    }
    
    try {
      final pendingItems = await _receiptRepository.getPendingSyncItems();
      
      if (pendingItems.isEmpty) {
        return SyncResult(
          success: true,
          message: 'All receipts are already synced',
          syncedCount: 0,
          failedCount: 0,
        );
      }
      
      int syncedCount = 0;
      int failedCount = 0;
      
      for (final item in pendingItems) {
        try {
          await _processSyncItem(item);
          syncedCount++;
        } catch (e) {
          print('Failed to sync item ${item.queueId}: $e');
          failedCount++;
          
          // Update retry count
          final updatedItem = item.copyWith(
            retryCount: item.retryCount + 1,
            lastAttempt: DateTime.now(),
            status: SyncStatus.failed,
          );
          await _receiptRepository.updateSyncQueueItem(updatedItem);
        }
      }
      
      await _setLastSyncTime(DateTime.now());
      
      return SyncResult(
        success: failedCount == 0,
        message: failedCount == 0
            ? 'Successfully synced $syncedCount receipts'
            : 'Synced $syncedCount receipts, $failedCount failed',
        syncedCount: syncedCount,
        failedCount: failedCount,
      );
      
    } catch (e) {
      print('Sync failed with error: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
        syncedCount: 0,
        failedCount: 0,
      );
    }
  }
  
  /// Process individual sync item
  Future<void> _processSyncItem(SyncQueueItem item) async {
    // For now, work in offline-first mode without external sync
    // This simulates processing but keeps data local
    print('=== SYNC SERVICE: Processing item ${item.queueId} in offline mode');
    final processingItem = item.copyWith(
      status: SyncStatus.processing,
      lastAttempt: DateTime.now(),
    );
    await _receiptRepository.updateSyncQueueItem(processingItem);
    
    // Simulate sync process (replace with actual email sending logic)
    await _simulateEmailSync(item);
    
    // Mark as completed and remove from queue
    await _receiptRepository.removeSyncQueueItem(item.queueId);
    
    // Update receipt sync status
    final receipt = await _receiptRepository.getReceiptById(item.receiptId);
    if (receipt != null) {
      final syncedReceipt = receipt.copyWith(
        isSynced: true,
        uploadStatus: 'uploaded',
        updatedAt: DateTime.now(),
      );
      await _receiptRepository.updateReceipt(syncedReceipt);
    }
  }
  
  /// Simulate email sync (replace with actual implementation)
  Future<void> _simulateEmailSync(SyncQueueItem item) async {
    // OFFLINE-FIRST MODE: No external email sending required
    // This marks receipts as "synced" locally without external dependencies
    // When you have email credentials, replace this with actual email logic:
    // 1. Get the receipt by ID
    // 2. Prepare email with receipt image and data
    // 3. Send to company's destination email
    // 4. Handle success/failure
    
    print('=== SYNC SERVICE: Processing receipt ${item.receiptId} in offline mode');
    
    // Simulate minimal processing time (no network calls)
    await Future.delayed(const Duration(milliseconds: 100));
    
    print('=== SYNC SERVICE: Marked receipt ${item.receiptId} as locally synced');
  }
  
  /// Check if automatic sync should run
  bool shouldAutoSync() {
    if (getSyncMode() != SyncMode.automatic) return false;
    
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;
    
    final interval = getAutoSyncInterval();
    final nextSyncTime = lastSync.add(Duration(minutes: interval));
    
    return DateTime.now().isAfter(nextSyncTime);
  }
  
  /// Run automatic sync if conditions are met
  Future<SyncResult?> autoSyncIfNeeded() async {
    if (!shouldAutoSync()) return null;
    if (!await isConnected()) return null;
    
    final pendingCount = await getPendingSyncCount();
    if (pendingCount == 0) return null;
    
    print('Running automatic sync...');
    return await syncNow();
  }
}

class SyncResult {
  final bool success;
  final String message;
  final int syncedCount;
  final int failedCount;
  
  SyncResult({
    required this.success,
    required this.message,
    required this.syncedCount,
    required this.failedCount,
  });
}