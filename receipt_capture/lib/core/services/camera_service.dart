import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class CameraService {
  static final CameraService instance = CameraService._privateConstructor();
  CameraService._privateConstructor();

  final ImagePicker _picker = ImagePicker();
  List<CameraDescription>? _cameras;
  CameraController? _controller;

  Future<void> initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      print('Error initializing cameras: $e');
    }
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<CameraController?> getCameraController() async {
    if (_cameras == null || _cameras!.isEmpty) {
      await initializeCameras();
    }

    if (_cameras != null && _cameras!.isNotEmpty) {
      _controller = CameraController(
        _cameras!.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      return _controller;
    }
    return null;
  }

  Future<String?> captureImage() async {
    try {
      if (_controller == null || !_controller!.value.isInitialized) {
        return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'receipt_$timestamp.jpg';
      final filePath = path.join(directory.path, 'receipts', fileName);

      // Ensure directory exists
      await Directory(path.dirname(filePath)).create(recursive: true);

      final XFile image = await _controller!.takePicture();
      await File(image.path).copy(filePath);
      await File(image.path).delete(); // Clean up temp file

      return filePath;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (image != null) {
        // Save to app directory
        final directory = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'receipt_gallery_$timestamp.jpg';
        final filePath = path.join(directory.path, 'receipts', fileName);

        // Ensure directory exists
        await Directory(path.dirname(filePath)).create(recursive: true);

        await File(image.path).copy(filePath);
        return filePath;
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  Future<String?> cropImage(String imagePath, {BuildContext? context}) async {
    // This method is now handled by navigating to SimpleCropScreen
    // It's kept for backward compatibility but should not be used directly
    print('Warning: cropImage called directly. Use SimpleCropScreen instead.');
    return null;
  }

  Future<String?> autoCropReceipt(String imagePath) async {
    // This is a simplified auto-cropping implementation
    // In a real app, you might use ML models or edge detection
    try {
      return await cropImage(imagePath);
    } catch (e) {
      print('Error auto-cropping receipt: $e');
      return null;
    }
  }

  void dispose() {
    _controller?.dispose();
  }

  Future<String> generateReceiptId() async {
    return const Uuid().v4();
  }

  Future<Directory> getReceiptsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final receiptsDir = Directory(path.join(appDir.path, 'receipts'));
    if (!receiptsDir.existsSync()) {
      await receiptsDir.create(recursive: true);
    }
    return receiptsDir;
  }

  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
