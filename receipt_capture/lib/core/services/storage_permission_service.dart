import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service to handle storage permissions for saving PDFs
class StoragePermissionService {
  static final StoragePermissionService instance =
      StoragePermissionService._privateConstructor();
  StoragePermissionService._privateConstructor();

  /// Request storage permission based on Android version
  /// Returns true if permission is granted or not needed
  Future<bool> requestStoragePermission() async {
    if (!Platform.isAndroid) {
      // iOS doesn't need explicit storage permission for app documents
      return true;
    }

    try {
      // For Android 13+ (API 33+), we don't need WRITE_EXTERNAL_STORAGE
      // For Android 10-12 (API 29-32), we use scoped storage
      // For Android 9 and below (API 28-), we need WRITE_EXTERNAL_STORAGE

      if (Platform.isAndroid) {
        final androidVersion = await _getAndroidVersion();

        if (androidVersion >= 13) {
          // Android 13+ (API 33+) - Use READ_MEDIA_IMAGES
          // No need for storage permission to write to public Documents
          return true;
        } else if (androidVersion >= 10) {
          // Android 10-12 (API 29-32) - Scoped storage
          // No need for permission to write to public Documents via MediaStore
          return true;
        } else {
          // Android 9 and below - Need WRITE_EXTERNAL_STORAGE
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }

  /// Check if storage permission is granted
  Future<bool> hasStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final androidVersion = await _getAndroidVersion();

      if (androidVersion >= 10) {
        // Android 10+ - No permission needed for public Documents
        return true;
      } else {
        // Android 9 and below
        return await Permission.storage.isGranted;
      }
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      return false;
    }
  }

  /// Request MANAGE_EXTERNAL_STORAGE for full file access (optional)
  /// This is only needed if you want to access all files, not required for Documents folder
  Future<bool> requestManageStoragePermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      final androidVersion = await _getAndroidVersion();

      if (androidVersion >= 11) {
        // Android 11+ (API 30+)
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting manage storage permission: $e');
      return false;
    }
  }

  /// Get Android version (API level)
  Future<int> _getAndroidVersion() async {
    // This is a simplified version - in production, you'd use platform channels
    // or a package like device_info_plus to get the exact API level
    // For now, we'll assume Android 13+ for modern devices
    return 33; // Default to Android 13
  }

  /// Show permission dialog explanation
  Future<void> showPermissionDialog() async {
    // This would be implemented in the UI layer
    // Just a placeholder for now
    debugPrint('Storage permission explanation should be shown to user');
  }
}
