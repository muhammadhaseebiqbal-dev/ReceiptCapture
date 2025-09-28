import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../database/models.dart';
import '../services/encryption_service.dart';

class ReceiptRepository {
  static final ReceiptRepository instance =
      ReceiptRepository._privateConstructor();
  ReceiptRepository._privateConstructor();

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final EncryptionService _encryptionService = EncryptionService.instance;
  final Uuid _uuid = const Uuid();

  Future<String> createReceipt(Receipt receipt) async {
    final db = await _databaseHelper.database;

    try {
      await db.transaction((txn) async {
        // Encrypt sensitive data before storing
        final encryptedData = _encryptionService.encryptReceiptData(
          receipt.toMap(),
        );
        final receiptWithEncryption = Receipt.fromMap(encryptedData);

        await txn.insert(
          DatabaseHelper.tableReceipts,
          receiptWithEncryption.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Add to sync queue
        final syncQueueItem = SyncQueueItem(
          queueId: _uuid.v4(),
          receiptId: receipt.id,
          operation: SyncOperation.create,
        );

        await txn.insert(
          DatabaseHelper.tableSyncQueue,
          syncQueueItem.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });

      return receipt.id;
    } catch (e) {
      throw Exception('Failed to create receipt: $e');
    }
  }

  Future<Receipt?> getReceiptById(String id) async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableReceipts,
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [id],
      );

      if (maps.isNotEmpty) {
        final decryptedData = _encryptionService.decryptReceiptData(maps.first);
        return Receipt.fromMap(decryptedData);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get receipt: $e');
    }
  }

  Future<List<Receipt>> getAllReceipts({
    int? limit,
    int? offset,
    String? orderBy,
    bool descending = true,
  }) async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableReceipts,
        orderBy:
            '${orderBy ?? DatabaseHelper.columnCreatedAt} ${descending ? 'DESC' : 'ASC'}',
        limit: limit,
        offset: offset,
      );

      return maps.map((map) {
        final decryptedData = _encryptionService.decryptReceiptData(map);
        return Receipt.fromMap(decryptedData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get receipts: $e');
    }
  }

  Future<List<Receipt>> searchReceipts(String query) async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableReceipts,
        where:
            '''
          ${DatabaseHelper.columnMerchantName} LIKE ? OR
          ${DatabaseHelper.columnCategory} LIKE ? OR
          ${DatabaseHelper.columnNotes} LIKE ?
        ''',
        whereArgs: ['%$query%', '%$query%', '%$query%'],
        orderBy: '${DatabaseHelper.columnCreatedAt} DESC',
      );

      return maps.map((map) {
        final decryptedData = _encryptionService.decryptReceiptData(map);
        return Receipt.fromMap(decryptedData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search receipts: $e');
    }
  }

  Future<void> updateReceipt(Receipt receipt) async {
    final db = await _databaseHelper.database;

    try {
      await db.transaction((txn) async {
        // Encrypt sensitive data before storing
        final encryptedData = _encryptionService.encryptReceiptData(
          receipt.toMap(),
        );
        final receiptWithEncryption = Receipt.fromMap(encryptedData);

        await txn.update(
          DatabaseHelper.tableReceipts,
          receiptWithEncryption.toMap(),
          where: '${DatabaseHelper.columnId} = ?',
          whereArgs: [receipt.id],
        );

        // Add to sync queue if not already synced
        if (!receipt.isSynced) {
          final syncQueueItem = SyncQueueItem(
            queueId: _uuid.v4(),
            receiptId: receipt.id,
            operation: SyncOperation.update,
          );

          await txn.insert(
            DatabaseHelper.tableSyncQueue,
            syncQueueItem.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw Exception('Failed to update receipt: $e');
    }
  }

  Future<void> deleteReceipt(String id) async {
    final db = await _databaseHelper.database;

    try {
      await db.transaction((txn) async {
        // Add to sync queue for deletion
        final syncQueueItem = SyncQueueItem(
          queueId: _uuid.v4(),
          receiptId: id,
          operation: SyncOperation.delete,
        );

        await txn.insert(
          DatabaseHelper.tableSyncQueue,
          syncQueueItem.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        // Soft delete or hard delete based on sync status
        final receipt = await getReceiptById(id);
        if (receipt != null && receipt.isSynced) {
          // Mark as deleted but don't actually delete
          await txn.update(
            DatabaseHelper.tableReceipts,
            {'deleted_at': DateTime.now().toIso8601String()},
            where: '${DatabaseHelper.columnId} = ?',
            whereArgs: [id],
          );
        } else {
          // Hard delete if not synced
          await txn.delete(
            DatabaseHelper.tableReceipts,
            where: '${DatabaseHelper.columnId} = ?',
            whereArgs: [id],
          );
        }
      });
    } catch (e) {
      throw Exception('Failed to delete receipt: $e');
    }
  }

  Future<List<Receipt>> getUnsyncedReceipts() async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableReceipts,
        where: '${DatabaseHelper.columnIsSynced} = ?',
        whereArgs: [0],
        orderBy: '${DatabaseHelper.columnCreatedAt} ASC',
      );

      return maps.map((map) {
        final decryptedData = _encryptionService.decryptReceiptData(map);
        return Receipt.fromMap(decryptedData);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get unsynced receipts: $e');
    }
  }

  Future<void> markReceiptAsSynced(String id) async {
    final db = await _databaseHelper.database;

    try {
      await db.update(
        DatabaseHelper.tableReceipts,
        {
          DatabaseHelper.columnIsSynced: 1,
          DatabaseHelper.columnUpdatedAt: DateTime.now().toIso8601String(),
        },
        where: '${DatabaseHelper.columnId} = ?',
        whereArgs: [id],
      );
    } catch (e) {
      throw Exception('Failed to mark receipt as synced: $e');
    }
  }

  Future<List<SyncQueueItem>> getPendingSyncItems() async {
    final db = await _databaseHelper.database;

    try {
      final List<Map<String, dynamic>> maps = await db.query(
        DatabaseHelper.tableSyncQueue,
        where: '${DatabaseHelper.columnStatus} = ?',
        whereArgs: ['PENDING'],
        orderBy: '${DatabaseHelper.columnLastAttempt} ASC',
      );

      return maps.map((map) => SyncQueueItem.fromMap(map)).toList();
    } catch (e) {
      throw Exception('Failed to get pending sync items: $e');
    }
  }

  Future<void> updateSyncQueueItem(SyncQueueItem item) async {
    final db = await _databaseHelper.database;

    try {
      await db.update(
        DatabaseHelper.tableSyncQueue,
        item.toMap(),
        where: '${DatabaseHelper.columnQueueId} = ?',
        whereArgs: [item.queueId],
      );
    } catch (e) {
      throw Exception('Failed to update sync queue item: $e');
    }
  }

  Future<void> removeSyncQueueItem(String queueId) async {
    final db = await _databaseHelper.database;

    try {
      await db.delete(
        DatabaseHelper.tableSyncQueue,
        where: '${DatabaseHelper.columnQueueId} = ?',
        whereArgs: [queueId],
      );
    } catch (e) {
      throw Exception('Failed to remove sync queue item: $e');
    }
  }

  Future<int> getReceiptCount() async {
    final db = await _databaseHelper.database;

    try {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DatabaseHelper.tableReceipts}',
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      throw Exception('Failed to get receipt count: $e');
    }
  }
}
