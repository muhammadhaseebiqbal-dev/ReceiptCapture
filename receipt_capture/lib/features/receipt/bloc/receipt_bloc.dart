import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/models.dart';
import '../../../core/database/receipt_repository.dart';
import '../../../core/services/camera_service.dart';
import 'receipt_event.dart';
import 'receipt_state.dart';

class ReceiptBloc extends Bloc<ReceiptEvent, ReceiptState> {
  ReceiptBloc({
    ReceiptRepository? receiptRepository,
    CameraService? cameraService,
  }) : _receiptRepository = receiptRepository ?? ReceiptRepository.instance,
       _cameraService = cameraService ?? CameraService.instance,
       super(const ReceiptState()) {
    on<LoadReceipts>(_onLoadReceipts);
    on<RefreshReceipts>(_onRefreshReceipts);
    on<CreateReceipt>(_onCreateReceipt);
    on<UpdateReceipt>(_onUpdateReceipt);
    on<DeleteReceipt>(_onDeleteReceipt);
    on<SearchReceipts>(_onSearchReceipts);
    on<ClearSearch>(_onClearSearch);
    on<CaptureReceiptImage>(_onCaptureReceiptImage);
    on<PickReceiptImageFromGallery>(_onPickReceiptImageFromGallery);
    on<CropReceiptImage>(_onCropReceiptImage);
  }

  final ReceiptRepository _receiptRepository;
  final CameraService _cameraService;
  final Uuid _uuid = const Uuid();

  Future<void> _onLoadReceipts(
    LoadReceipts event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(state.copyWith(status: ReceiptStatus.loading));

    try {
      final receipts = await _receiptRepository.getAllReceipts();
      emit(state.copyWith(status: ReceiptStatus.success, receipts: receipts));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onRefreshReceipts(
    RefreshReceipts event,
    Emitter<ReceiptState> emit,
  ) async {
    try {
      final receipts = await _receiptRepository.getAllReceipts();
      emit(state.copyWith(status: ReceiptStatus.success, receipts: receipts));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCreateReceipt(
    CreateReceipt event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(state.copyWith(status: ReceiptStatus.loading));

    try {
      final receipt = Receipt(
        id: _uuid.v4(),
        imagePath: event.imagePath,
        croppedImagePath: event.croppedImagePath,
        merchantName: event.merchantName,
        amount: null, // Amount field removed
        date: event.date ?? DateTime.now(),
        category: event.category,
        notes: event.notes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isSynced: false,
      );

      await _receiptRepository.createReceipt(receipt);

      // Refresh the receipts list
      final receipts = await _receiptRepository.getAllReceipts();

      emit(
        state.copyWith(
          status: ReceiptStatus.success,
          receipts: receipts,
          capturedImagePath: '',
          croppedImagePath: '',
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onUpdateReceipt(
    UpdateReceipt event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(state.copyWith(status: ReceiptStatus.loading));

    try {
      final updatedReceipt = event.receipt.copyWith(
        updatedAt: DateTime.now(),
        isSynced: false, // Mark as unsynced when updated
      );

      await _receiptRepository.updateReceipt(updatedReceipt);

      // Refresh the receipts list
      final receipts = await _receiptRepository.getAllReceipts();

      emit(state.copyWith(status: ReceiptStatus.success, receipts: receipts));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDeleteReceipt(
    DeleteReceipt event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(state.copyWith(status: ReceiptStatus.loading));

    try {
      await _receiptRepository.deleteReceipt(event.receiptId);

      // Refresh the receipts list
      final receipts = await _receiptRepository.getAllReceipts();

      emit(state.copyWith(status: ReceiptStatus.success, receipts: receipts));
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSearchReceipts(
    SearchReceipts event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(state.copyWith(isSearching: true, searchQuery: event.query));

    try {
      final searchResults = await _receiptRepository.searchReceipts(
        event.query,
      );

      emit(
        state.copyWith(
          isSearching: true,
          searchResults: searchResults,
          status: ReceiptStatus.success,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          errorMessage: error.toString(),
          isSearching: false,
        ),
      );
    }
  }

  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(
      state.copyWith(
        isSearching: false,
        searchQuery: '',
        searchResults: const <Receipt>[],
      ),
    );
  }

  Future<void> _onCaptureReceiptImage(
    CaptureReceiptImage event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(state.copyWith(status: ReceiptStatus.capturing));

    try {
      // Check permissions first
      final hasPermission = await _cameraService.requestCameraPermission();
      if (!hasPermission) {
        emit(
          state.copyWith(
            status: ReceiptStatus.failure,
            errorMessage: 'Camera permission is required to capture receipts',
          ),
        );
        return;
      }

      final imagePath = await _cameraService.captureImage();

      if (imagePath != null) {
        emit(
          state.copyWith(
            status: ReceiptStatus.success,
            capturedImagePath: imagePath,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ReceiptStatus.failure,
            errorMessage: 'Failed to capture image',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onPickReceiptImageFromGallery(
    PickReceiptImageFromGallery event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(state.copyWith(status: ReceiptStatus.loading));

    try {
      final imagePath = await _cameraService.pickImageFromGallery();

      if (imagePath != null) {
        emit(
          state.copyWith(
            status: ReceiptStatus.success,
            capturedImagePath: imagePath,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ReceiptStatus.success,
            errorMessage: 'No image selected',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCropReceiptImage(
    CropReceiptImage event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(state.copyWith(status: ReceiptStatus.cropping));

    try {
      final croppedImagePath = await _cameraService.cropImage(event.imagePath);

      if (croppedImagePath != null) {
        emit(
          state.copyWith(
            status: ReceiptStatus.success,
            croppedImagePath: croppedImagePath,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: ReceiptStatus.success,
            errorMessage: 'Image cropping was cancelled',
          ),
        );
      }
    } catch (error) {
      emit(
        state.copyWith(
          status: ReceiptStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
