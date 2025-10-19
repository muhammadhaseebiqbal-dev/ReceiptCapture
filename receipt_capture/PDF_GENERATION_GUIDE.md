# 📄 PDF Generation Feature - Complete Guide

## Overview

Every receipt captured in the app is **automatically converted to PDF format** and saved to a publicly accessible folder on your device. This makes receipts easy to share, backup, and access via your device's file manager.

---

## 🎯 Key Features

### 1. **Automatic PDF Generation**
- PDFs are generated automatically when you save a receipt
- No manual action required
- Uses the cropped/processed image for best quality

### 2. **Smart File Naming**
- PDFs are named with date-time format: `DD-MM-YYYY_HH:MM.pdf`
- Example: `19-10-2025_14:30.pdf`
- Easy to find and sort chronologically

### 3. **Public Folder Storage**
- **Android**: `/storage/emulated/0/Documents/Receipt Capture/`
- **iOS**: `Files App > Receipt Capture`
- Accessible via any file manager app
- Easy to share, backup, or move files

---

## 📂 File Locations

### Android
```
/storage/emulated/0/Documents/Receipt Capture/
├── 19-10-2025_14:30.pdf
├── 19-10-2025_15:45.pdf
├── 20-10-2025_09:15.pdf
└── ...
```

**Access via:**
- Files app (Google Files or any file manager)
- Navigate to: `Documents > Receipt Capture`
- Files are visible in your phone's file system

**Fallback Location** (if Documents isn't accessible):
```
/storage/emulated/0/Download/Receipt Capture/
```

### iOS
```
Files App > On My iPhone > Receipt Capture/
├── 19-10-2025_14:30.pdf
├── 19-10-2025_15:45.pdf
└── ...
```

**Access via:**
- iOS Files app
- Navigate to: `On My iPhone > Receipt Capture`
- Can be backed up to iCloud if enabled

---

## 🚀 How It Works

### Receipt Capture Flow

```
1. User captures/selects receipt image
        ↓
2. Image is processed (auto-crop with edge detection)
        ↓
3. User fills receipt form and saves
        ↓
4. Receipt is saved to database
        ↓
5. PDF is AUTOMATICALLY generated from image
        ↓
6. PDF is saved to "Receipt Capture" folder
        ↓
7. Success notification shows PDF location
```

### Technical Implementation

```dart
// When user saves receipt in receipt_form_screen.dart:
void _saveReceipt() {
  context.read<ReceiptBloc>().add(
    CreateReceipt(
      imagePath: widget.imagePath,
      croppedImagePath: _currentImagePath,
      // ... other fields
    ),
  );
}

// ReceiptBloc automatically handles PDF generation:
Future<void> _onCreateReceipt(...) async {
  // 1. Generate PDF
  pdfPath = await _cameraService.generatePdfFromImage(imagePathForPdf);
  
  // 2. Save receipt with PDF path
  final receipt = Receipt(
    // ... fields
    pdfPath: pdfPath,  // Store PDF path in database
  );
  
  await _receiptRepository.createReceipt(receipt);
}
```

---

## 🔒 Permissions

### Android Permissions Required

#### AndroidManifest.xml
```xml
<!-- For Android 9 and below (API 28-) -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" 
    android:maxSdkVersion="28" />

<!-- For Android 10-12 (API 29-32) -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" 
    android:maxSdkVersion="32" />

<!-- For Android 13+ (API 33+) -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />

<!-- Optional: For full file access (not required for Documents folder) -->
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" 
    tools:ignore="ScopedStorage" />

<!-- Enable legacy storage for Android 10-11 -->
<application
    android:requestLegacyExternalStorage="true">
```

### Permission Handling by Android Version

| Android Version | API Level | Permission Needed | Behavior |
|----------------|-----------|-------------------|----------|
| Android 13+ | 33+ | None (for Documents) | Direct write to public Documents folder |
| Android 10-12 | 29-32 | None (scoped storage) | Uses MediaStore or scoped storage API |
| Android 9- | 28- | WRITE_EXTERNAL_STORAGE | Traditional storage permission |

### iOS Permissions
- **No explicit permission needed** for app documents folder
- Automatically accessible via Files app
- Can enable iCloud backup for Files app storage

---

## 📱 User Experience

### Success Notification
When a PDF is successfully generated:

```
✅ PDF Generated Successfully!

Saved as: 19-10-2025_14:30.pdf
Location: Documents/Receipt Capture (accessible via File Manager)

[OK]
```

### Error Handling
If PDF generation fails:

```
❌ PDF Generation Failed

Error: Unable to create PDF file

[OK]
```

**Note:** Receipt is still saved to database even if PDF generation fails.

---

## 🔧 PDF Service Implementation

### pdf_service.dart

```dart
class PdfService {
  Future<String?> convertImageToPdf(String imagePath) async {
    // 1. Read image file
    final imageBytes = await File(imagePath).readAsBytes();
    
    // 2. Create PDF document
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Image(pw.MemoryImage(imageBytes)),
      ),
    );
    
    // 3. Generate filename with date-time
    final fileName = DateFormat('dd-MM-yyyy_HH:mm').format(DateTime.now());
    
    // 4. Save to public Documents folder
    final pdfDir = Directory('/storage/emulated/0/Documents/Receipt Capture');
    await pdfDir.create(recursive: true);
    
    final pdfPath = '${pdfDir.path}/$fileName.pdf';
    await File(pdfPath).writeAsBytes(await pdf.save());
    
    return pdfPath;
  }
}
```

### Key Components

1. **Image to PDF Conversion**: Uses `pdf` package to create A4-sized PDFs
2. **Date-Time Naming**: Automatic naming with `DateFormat('dd-MM-yyyy_HH:mm')`
3. **Public Folder Creation**: Creates `Receipt Capture` folder if doesn't exist
4. **Error Handling**: Graceful fallback to Download folder if needed

---

## 📊 Database Schema

### Receipt Model
```dart
class Receipt {
  final String id;
  final String imagePath;         // Original/cropped image path
  final String? pdfPath;           // 🆕 PDF file path
  final String? merchantName;      // Actually receipt name (date-time)
  final DateTime? date;
  final String? category;
  final String? notes;
  // ...
}
```

### Receipt Table (SQLite)
```sql
CREATE TABLE receipts (
  id TEXT PRIMARY KEY,
  image_path TEXT NOT NULL,
  cropped_image_path TEXT,
  pdf_path TEXT,                   -- 🆕 PDF file path
  merchant_name TEXT,              -- Receipt name (date-time format)
  date INTEGER,
  category TEXT,
  notes TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  is_synced INTEGER DEFAULT 0
);
```

---

## 🎨 UI/UX Enhancements

### Receipt Form Screen
- Auto-generates receipt name with date-time format
- Refresh button to regenerate name if needed
- Shows PDF generation progress
- Success notification with file location

### Receipt Details
- View PDF path in receipt details
- Option to open PDF in external viewer
- Share PDF functionality
- Delete PDF along with receipt

---

## 🧪 Testing Guide

### Test Scenarios

#### 1. Basic PDF Generation
```
✅ Capture receipt
✅ Save with auto-generated name
✅ Check PDF in Documents/Receipt Capture folder
✅ Verify filename matches date-time format
✅ Open PDF and verify image quality
```

#### 2. Permission Testing
```
✅ Test on Android 9 (requires permission)
✅ Test on Android 10-12 (scoped storage)
✅ Test on Android 13+ (modern approach)
✅ Verify no permission prompts on iOS
```

#### 3. Error Scenarios
```
✅ Fill storage space - check error handling
✅ Revoke storage permission - check fallback
✅ Corrupted image - verify graceful failure
✅ Receipt still saves even if PDF fails
```

#### 4. Edge Cases
```
✅ Multiple receipts at same minute - unique filenames
✅ Special characters in path - sanitization
✅ Very large images - compression/optimization
✅ App uninstall/reinstall - folder persistence
```

---

## 🔄 Future Enhancements

### Planned Features
1. **Batch PDF Generation** - Combine multiple receipts into one PDF
2. **PDF Templates** - Add headers, footers, receipt metadata
3. **Cloud Backup** - Auto-upload PDFs to Google Drive/Dropbox
4. **PDF Annotations** - Add notes directly to PDF
5. **Email Integration** - Quick email PDF from app
6. **PDF Search** - Full-text search within PDFs (OCR)

### Code Extensions
```dart
// Future: Batch PDF generation
Future<String?> convertImagesToPdf(List<String> imagePaths) async {
  // Combine multiple receipts into single PDF
}

// Future: PDF with metadata
Future<String?> generateReceiptPdf(Receipt receipt) async {
  // Add receipt details as text in PDF
  // Include merchant, date, amount, category
}

// Future: Cloud upload
Future<void> uploadPdfToCloud(String pdfPath) async {
  // Upload to Google Drive API
}
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. PDFs not appearing in File Manager
**Cause**: Folder not indexed by media scanner
**Solution**: 
```dart
// Notify media scanner (Android)
await Process.run('am', [
  'broadcast',
  '-a', 'android.intent.action.MEDIA_SCANNER_SCAN_FILE',
  '-d', 'file://$pdfPath'
]);
```

#### 2. Permission Denied on Android 9
**Cause**: WRITE_EXTERNAL_STORAGE not granted
**Solution**: Request permission explicitly:
```dart
final hasPermission = await StoragePermissionService.instance.requestStoragePermission();
if (!hasPermission) {
  // Show permission explanation dialog
}
```

#### 3. Large PDF file sizes
**Cause**: High-resolution images
**Solution**: Compress images before PDF conversion:
```dart
final compressedImage = img.copyResize(
  originalImage,
  width: 1024,  // Max width
);
```

#### 4. iOS Files app not showing folder
**Cause**: App documents not enabled for Files app
**Solution**: Add to Info.plist:
```xml
<key>UISupportsDocumentBrowser</key>
<true/>
<key>LSSupportsOpeningDocumentsInPlace</key>
<true/>
```

---

## 📚 Related Files

### Core Implementation
- `lib/core/services/pdf_service.dart` - PDF generation logic
- `lib/core/services/storage_permission_service.dart` - Permission handling
- `lib/core/utils/pdf_utils.dart` - PDF utility functions

### UI Layer
- `lib/screens/receipt_form_screen.dart` - Receipt form with PDF status
- `lib/features/receipt/bloc/receipt_bloc.dart` - Receipt BLoC with PDF generation

### Configuration
- `android/app/src/main/AndroidManifest.xml` - Android permissions
- `ios/Runner/Info.plist` - iOS configurations
- `pubspec.yaml` - PDF package dependency

---

## 📖 Dependencies

```yaml
dependencies:
  pdf: ^3.10.4              # PDF generation
  path_provider: ^2.1.1     # Get device directories
  path: ^1.8.3              # Path manipulation
  intl: ^0.18.1             # Date formatting
  permission_handler: ^11.0.1  # Permission handling
  image: ^4.1.3             # Image processing
```

---

## ✅ Summary

**Key Takeaways:**
- ✅ Automatic PDF generation for every receipt
- ✅ Saves to publicly accessible folder
- ✅ Date-time naming format (DD-MM-YYYY_HH:MM)
- ✅ Cross-platform (Android & iOS)
- ✅ Proper permission handling
- ✅ Graceful error handling
- ✅ User-friendly notifications

**Receipt Lifecycle:**
```
Capture → Process → Save → PDF Generated → Stored in Receipt Capture folder
```

**End Result:**
Users can easily access, share, and backup their receipt PDFs directly from their device's file manager, making receipt management seamless and professional! 🎉
