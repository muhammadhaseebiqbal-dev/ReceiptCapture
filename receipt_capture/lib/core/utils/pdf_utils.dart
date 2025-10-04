import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class PdfUtils {
  /// Shows a snackbar with PDF save location
  static void showPdfSavedMessage(BuildContext context, String? pdfPath) {
    if (pdfPath == null) return;
    
    final fileName = path.basename(pdfPath);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PDF Generated Successfully! 📄'),
            const SizedBox(height: 4),
            Text(
              'Saved as: $fileName',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
            const SizedBox(height: 4),
            const Text(
              'Location: Receipt Capture folder in app storage',
              style: TextStyle(fontSize: 11, color: Colors.white60),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Shows error message when PDF generation fails
  static void showPdfErrorMessage(BuildContext context, String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('PDF Generation Failed ❌'),
            const SizedBox(height: 4),
            Text(
              error,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Gets a user-friendly path description
  static Future<String> getFolderDescription() async {
    try {
      final Directory? externalDir = await getExternalStorageDirectory();
      
      if (externalDir != null) {
        return 'Android/data/com.example.receipt_capture/files/Receipt Capture';
      } else {
        return 'App Documents/Receipt Capture';
      }
    } catch (e) {
      return 'Receipt Capture folder';
    }
  }

  /// Checks if PDF file exists
  static Future<bool> pdfExists(String? pdfPath) async {
    if (pdfPath == null || pdfPath.isEmpty) return false;
    
    try {
      final file = File(pdfPath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
}