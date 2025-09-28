import 'package:equatable/equatable.dart';
import '../../../core/database/models.dart';

enum ReceiptStatus { initial, loading, success, failure, capturing, cropping }

class ReceiptState extends Equatable {
  const ReceiptState({
    this.status = ReceiptStatus.initial,
    this.receipts = const <Receipt>[],
    this.searchResults = const <Receipt>[],
    this.isSearching = false,
    this.searchQuery = '',
    this.errorMessage = '',
    this.capturedImagePath = '',
    this.croppedImagePath = '',
  });

  final ReceiptStatus status;
  final List<Receipt> receipts;
  final List<Receipt> searchResults;
  final bool isSearching;
  final String searchQuery;
  final String errorMessage;
  final String capturedImagePath;
  final String croppedImagePath;

  ReceiptState copyWith({
    ReceiptStatus? status,
    List<Receipt>? receipts,
    List<Receipt>? searchResults,
    bool? isSearching,
    String? searchQuery,
    String? errorMessage,
    String? capturedImagePath,
    String? croppedImagePath,
  }) {
    return ReceiptState(
      status: status ?? this.status,
      receipts: receipts ?? this.receipts,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      croppedImagePath: croppedImagePath ?? this.croppedImagePath,
    );
  }

  @override
  List<Object?> get props => [
    status,
    receipts,
    searchResults,
    isSearching,
    searchQuery,
    errorMessage,
    capturedImagePath,
    croppedImagePath,
  ];
}
