import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_endpoints.dart';
import '../database/receipt_repository.dart';
import '../database/models.dart';

enum SyncMode { manual, automatic }

class SyncService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';
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
    print('=== SYNC SERVICE: Processing item ${item.queueId} via backend upload');
    final processingItem = item.copyWith(
      status: SyncStatus.processing,
      lastAttempt: DateTime.now(),
    );
    await _receiptRepository.updateSyncQueueItem(processingItem);

    await _uploadReceipt(item);
    
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

  Future<void> _uploadReceipt(SyncQueueItem item) async {
    final token = _prefs.getString(_tokenKey);
    if (token == null || token.isEmpty) {
      throw Exception('No auth token found. Please sign in again.');
    }

    final receipt = await _receiptRepository.getReceiptById(item.receiptId);
    if (receipt == null) {
      throw Exception('Receipt not found for sync item ${item.queueId}');
    }

    final imagePath = receipt.croppedImagePath?.isNotEmpty == true
        ? receipt.croppedImagePath!
        : receipt.imagePath;
    final imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      throw Exception('Receipt image file not found: $imagePath');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse(AppEndpoints.apiPath('/api/receipts/upload')),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['receiptId'] = receipt.id;
    request.fields['status'] = 'pending';
    request.fields['createdAt'] = receipt.createdAt.toIso8601String();
    request.fields['updatedAt'] = receipt.updatedAt.toIso8601String();

    if (receipt.merchantName != null && receipt.merchantName!.isNotEmpty) {
      request.fields['merchantName'] = receipt.merchantName!;
    }
    if (receipt.amount != null) {
      request.fields['amount'] = receipt.amount!.toString();
    }
    if (receipt.date != null) {
      request.fields['receiptDate'] = receipt.date!.toIso8601String();
    }
    if (receipt.category != null && receipt.category!.isNotEmpty) {
      request.fields['category'] = receipt.category!;
    }
    if (receipt.notes != null && receipt.notes!.isNotEmpty) {
      request.fields['notes'] = receipt.notes!;
    }

    final userJson = _prefs.getString(_userKey);
    if (userJson != null && userJson.isNotEmpty) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final userId = userMap['id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          request.fields['userId'] = userId;
        }
      } catch (_) {
        // Keep upload resilient if cached user payload is malformed.
      }
    }

    request.files.add(await http.MultipartFile.fromPath('receiptImage', imagePath));

    final response = await request.send();
    final responseText = await response.stream.bytesToString();

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String backendError = 'Failed to upload receipt';
      if (responseText.isNotEmpty) {
        try {
          final payload = jsonDecode(responseText) as Map<String, dynamic>;
          backendError = payload['error']?.toString() ?? backendError;
        } catch (_) {
          backendError = responseText;
        }
      }

      throw Exception('$backendError (HTTP ${response.statusCode})');
    }
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