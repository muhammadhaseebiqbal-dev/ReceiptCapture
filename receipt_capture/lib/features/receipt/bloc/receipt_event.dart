import 'package:equatable/equatable.dart';
import '../../../core/database/models.dart';

abstract class ReceiptEvent extends Equatable {
  const ReceiptEvent();

  @override
  List<Object?> get props => [];
}

class LoadReceipts extends ReceiptEvent {
  const LoadReceipts();
}

class RefreshReceipts extends ReceiptEvent {
  const RefreshReceipts();
}

class CreateReceipt extends ReceiptEvent {
  final String imagePath;
  final String? croppedImagePath;
  final String? merchantName;
  final DateTime? date;
  final String? category;
  final String? notes;

  const CreateReceipt({
    required this.imagePath,
    this.croppedImagePath,
    this.merchantName,
    this.date,
    this.category,
    this.notes,
  });

  @override
  List<Object?> get props => [
    imagePath,
    croppedImagePath,
    merchantName,
    date,
    category,
    notes,
  ];
}

class UpdateReceipt extends ReceiptEvent {
  final Receipt receipt;

  const UpdateReceipt(this.receipt);

  @override
  List<Object?> get props => [receipt];
}

class DeleteReceipt extends ReceiptEvent {
  final String receiptId;

  const DeleteReceipt(this.receiptId);

  @override
  List<Object?> get props => [receiptId];
}

class SearchReceipts extends ReceiptEvent {
  final String query;

  const SearchReceipts(this.query);

  @override
  List<Object?> get props => [query];
}

class ClearSearch extends ReceiptEvent {
  const ClearSearch();
}

class CaptureReceiptImage extends ReceiptEvent {
  const CaptureReceiptImage();
}

class PickReceiptImageFromGallery extends ReceiptEvent {
  const PickReceiptImageFromGallery();
}

class CropReceiptImage extends ReceiptEvent {
  final String imagePath;

  const CropReceiptImage(this.imagePath);

  @override
  List<Object?> get props => [imagePath];
}
