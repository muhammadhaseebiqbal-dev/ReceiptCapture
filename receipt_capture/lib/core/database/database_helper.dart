import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static const _databaseName = 'receipt_capture.db';
  static const _databaseVersion = 1;

  static const tableReceipts = 'receipts';
  static const tableSyncQueue = 'sync_queue';

  // Receipt table columns
  static const columnId = 'id';
  static const columnImagePath = 'image_path';
  static const columnCroppedImagePath = 'cropped_image_path';
  static const columnMerchantName = 'merchant_name';
  static const columnAmount = 'amount';
  static const columnDate = 'date';
  static const columnCategory = 'category';
  static const columnNotes = 'notes';
  static const columnCreatedAt = 'created_at';
  static const columnUpdatedAt = 'updated_at';
  static const columnIsSynced = 'is_synced';
  static const columnUploadStatus = 'upload_status';
  static const columnEncryptedData = 'encrypted_data';

  // Sync queue table columns
  static const columnQueueId = 'queue_id';
  static const columnReceiptId = 'receipt_id';
  static const columnOperation = 'operation'; // CREATE, UPDATE, DELETE
  static const columnRetryCount = 'retry_count';
  static const columnLastAttempt = 'last_attempt';
  static const columnStatus =
      'status'; // PENDING, PROCESSING, COMPLETED, FAILED

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableReceipts (
        $columnId TEXT PRIMARY KEY,
        $columnImagePath TEXT NOT NULL,
        $columnCroppedImagePath TEXT,
        $columnMerchantName TEXT,
        $columnAmount REAL,
        $columnDate TEXT,
        $columnCategory TEXT,
        $columnNotes TEXT,
        $columnCreatedAt TEXT NOT NULL,
        $columnUpdatedAt TEXT NOT NULL,
        $columnIsSynced INTEGER NOT NULL DEFAULT 0,
        $columnUploadStatus TEXT NOT NULL DEFAULT 'queued',
        $columnEncryptedData TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableSyncQueue (
        $columnQueueId TEXT PRIMARY KEY,
        $columnReceiptId TEXT NOT NULL,
        $columnOperation TEXT NOT NULL,
        $columnRetryCount INTEGER NOT NULL DEFAULT 0,
        $columnLastAttempt TEXT,
        $columnStatus TEXT NOT NULL DEFAULT 'PENDING',
        FOREIGN KEY ($columnReceiptId) REFERENCES $tableReceipts ($columnId)
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_receipts_date ON $tableReceipts ($columnDate)
    ''');

    await db.execute('''
      CREATE INDEX idx_receipts_synced ON $tableReceipts ($columnIsSynced)
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_queue_status ON $tableSyncQueue ($columnStatus)
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < 2) {
      // Future upgrade logic
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  Future<void> deleteDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, _databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
