import 'package:equatable/equatable.dart';

// Helper function to safely parse amount from various types
double? _parseAmount(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    // Remove currency symbols and whitespace
    String cleanValue = value.replaceAll(RegExp(r'[^\d.-]'), '');
    return double.tryParse(cleanValue);
  }
  return null;
}

class Receipt extends Equatable {
  final String id;
  final String imagePath;
  final String? croppedImagePath;
  final String? merchantName;
  final double? amount;
  final DateTime? date;
  final String? category;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;
  final String uploadStatus; // 'queued', 'uploading', 'uploaded', 'failed'
  final String? encryptedData;

  const Receipt({
    required this.id,
    required this.imagePath,
    this.croppedImagePath,
    this.merchantName,
    this.amount,
    this.date,
    this.category,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
    this.uploadStatus = 'queued',
    this.encryptedData,
  });

  Receipt copyWith({
    String? id,
    String? imagePath,
    String? croppedImagePath,
    String? merchantName,
    double? amount,
    DateTime? date,
    String? category,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSynced,
    String? uploadStatus,
    String? encryptedData,
  }) {
    return Receipt(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      croppedImagePath: croppedImagePath ?? this.croppedImagePath,
      merchantName: merchantName ?? this.merchantName,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      encryptedData: encryptedData ?? this.encryptedData,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'cropped_image_path': croppedImagePath,
      'merchant_name': merchantName,
      'amount': amount,
      'date': date?.toIso8601String(),
      'category': category,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'upload_status': uploadStatus,
      'encrypted_data': encryptedData,
    };
  }

  factory Receipt.fromMap(Map<String, dynamic> map) {
    return Receipt(
      id: map['id'],
      imagePath: map['image_path'],
      croppedImagePath: map['cropped_image_path'],
      merchantName: map['merchant_name'],
      amount: _parseAmount(map['amount']),
      date: map['date'] != null ? DateTime.parse(map['date']) : null,
      category: map['category'],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isSynced: map['is_synced'] == 1,
      uploadStatus: map['upload_status'] ?? 'queued',
      encryptedData: map['encrypted_data'],
    );
  }

  @override
  List<Object?> get props => [
    id,
    imagePath,
    croppedImagePath,
    merchantName,
    amount,
    date,
    category,
    notes,
    createdAt,
    updatedAt,
    isSynced,
    uploadStatus,
    encryptedData,
  ];
}

enum SyncOperation { create, update, delete }

enum SyncStatus { pending, processing, completed, failed }

class SyncQueueItem extends Equatable {
  final String queueId;
  final String receiptId;
  final SyncOperation operation;
  final int retryCount;
  final DateTime? lastAttempt;
  final SyncStatus status;

  const SyncQueueItem({
    required this.queueId,
    required this.receiptId,
    required this.operation,
    this.retryCount = 0,
    this.lastAttempt,
    this.status = SyncStatus.pending,
  });

  SyncQueueItem copyWith({
    String? queueId,
    String? receiptId,
    SyncOperation? operation,
    int? retryCount,
    DateTime? lastAttempt,
    SyncStatus? status,
  }) {
    return SyncQueueItem(
      queueId: queueId ?? this.queueId,
      receiptId: receiptId ?? this.receiptId,
      operation: operation ?? this.operation,
      retryCount: retryCount ?? this.retryCount,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'queue_id': queueId,
      'receipt_id': receiptId,
      'operation': operation.name.toUpperCase(),
      'retry_count': retryCount,
      'last_attempt': lastAttempt?.toIso8601String(),
      'status': status.name.toUpperCase(),
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      queueId: map['queue_id'],
      receiptId: map['receipt_id'],
      operation: SyncOperation.values.firstWhere(
        (e) => e.name.toUpperCase() == map['operation'],
      ),
      retryCount: map['retry_count'] ?? 0,
      lastAttempt: map['last_attempt'] != null
          ? DateTime.parse(map['last_attempt'])
          : null,
      status: SyncStatus.values.firstWhere(
        (e) => e.name.toUpperCase() == map['status'],
      ),
    );
  }

  @override
  List<Object?> get props => [
    queueId,
    receiptId,
    operation,
    retryCount,
    lastAttempt,
    status,
  ];
}
