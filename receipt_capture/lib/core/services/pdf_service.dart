import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PdfService {
  static final PdfService instance = PdfService._privateConstructor();
  PdfService._privateConstructor();

  /// Converts an image to PDF and saves it in the Receipt Capture folder
  /// Returns the path to the generated PDF file
  Future<String?> convertImageToPdf(String imagePath) async {
    try {
      // Read the image file
      final imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        throw Exception('Image file not found: $imagePath');
      }

      final imageBytes = await imageFile.readAsBytes();

      // Create PDF document
      final pdf = pw.Document();

      // Create PDF image from bytes
      final pdfImage = pw.MemoryImage(imageBytes);

      // Add page with image
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Center(child: pw.Image(pdfImage, fit: pw.BoxFit.contain));
          },
        ),
      );

      // Generate filename with date-time format: DD-MM-YYYY_HH:MM.pdf
      final now = DateTime.now();
      final dateFormatter = DateFormat('dd-MM-yyyy_HH:mm');
      final fileName = '${dateFormatter.format(now)}.pdf';

      print('=== PDF SERVICE: Generated filename: $fileName');

      // Use app's external storage directory (accessible to user via file manager)
      final Directory? externalDir = await getExternalStorageDirectory();
      late Directory receiptCaptureDir;

      if (externalDir != null) {
        // Create Receipt Capture folder in app's external storage
        receiptCaptureDir = Directory(
          path.join(externalDir.path, 'Receipt Capture'),
        );
      } else {
        // Fallback to app documents directory
        final appDocDir = await getApplicationDocumentsDirectory();
        receiptCaptureDir = Directory(
          path.join(appDocDir.path, 'Receipt Capture'),
        );
      }

      // Create the Receipt Capture directory if it doesn't exist
      if (!await receiptCaptureDir.exists()) {
        await receiptCaptureDir.create(recursive: true);
      }

      // Create the full file path
      final pdfFilePath = path.join(receiptCaptureDir.path, fileName);

      // Save PDF to file
      final pdfFile = File(pdfFilePath);
      await pdfFile.writeAsBytes(await pdf.save());

      return pdfFilePath;
    } catch (e, stackTrace) {
      print('Error converting image to PDF: $e');
      print('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Converts multiple images to a single PDF
  Future<String?> convertImagesToPdf(List<String> imagePaths) async {
    try {
      if (imagePaths.isEmpty) {
        throw Exception('No images provided');
      }

      // Create PDF document
      final pdf = pw.Document();

      // Add each image as a separate page
      for (final imagePath in imagePaths) {
        final imageFile = File(imagePath);
        if (!imageFile.existsSync()) {
          print('Warning: Image file not found: $imagePath');
          continue;
        }

        final imageBytes = await imageFile.readAsBytes();
        final pdfImage = pw.MemoryImage(imageBytes);

        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }

      // Generate filename with date-time format
      final now = DateTime.now();
      final dateFormatter = DateFormat('dd-MM-yyyy_HH:mm');
      final fileName = '${dateFormatter.format(now)}_multi.pdf';

      // Use app's external storage directory
      final Directory? externalDir = await getExternalStorageDirectory();
      late Directory receiptCaptureDir;

      if (externalDir != null) {
        receiptCaptureDir = Directory(
          path.join(externalDir.path, 'Receipt Capture'),
        );
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        receiptCaptureDir = Directory(
          path.join(appDocDir.path, 'Receipt Capture'),
        );
      }

      if (!await receiptCaptureDir.exists()) {
        await receiptCaptureDir.create(recursive: true);
      }

      final pdfFilePath = path.join(receiptCaptureDir.path, fileName);

      // Save PDF to file
      final pdfFile = File(pdfFilePath);
      await pdfFile.writeAsBytes(await pdf.save());

      return pdfFilePath;
    } catch (e) {
      print('Error converting images to PDF: $e');
      return null;
    }
  }

  /// Checks if the Receipt Capture folder exists in Documents
  Future<bool> receiptCaptureFolderExists() async {
    try {
      final Directory? externalDir = await getExternalStorageDirectory();
      late String documentsPath;

      if (externalDir != null) {
        final List<String> pathSegments = externalDir.path.split('/');
        final int androidIndex = pathSegments.indexOf('Android');
        if (androidIndex >= 0) {
          documentsPath =
              '/${pathSegments.sublist(1, androidIndex).join('/')}/Documents';
        } else {
          documentsPath = '/storage/emulated/0/Documents';
        }
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        documentsPath = appDocDir.path;
      }

      final receiptCaptureDir = Directory(
        path.join(documentsPath, 'Receipt Capture'),
      );
      return await receiptCaptureDir.exists();
    } catch (e) {
      return false;
    }
  }

  /// Gets the path to the Receipt Capture folder
  Future<String?> getReceiptCaptureFolderPath() async {
    try {
      final Directory? externalDir = await getExternalStorageDirectory();

      if (externalDir != null) {
        return path.join(externalDir.path, 'Receipt Capture');
      } else {
        final appDocDir = await getApplicationDocumentsDirectory();
        return path.join(appDocDir.path, 'Receipt Capture');
      }
    } catch (e) {
      return null;
    }
  }
}
