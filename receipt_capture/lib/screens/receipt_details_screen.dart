import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../features/receipt/bloc/receipt_bloc.dart';
import '../features/receipt/bloc/receipt_event.dart';
import '../core/database/models.dart';
import '../core/services/ocr_service.dart';

class ReceiptDetailsScreen extends StatefulWidget {
  final String imagePath;

  const ReceiptDetailsScreen({Key? key, required this.imagePath})
    : super(key: key);

  @override
  State<ReceiptDetailsScreen> createState() => _ReceiptDetailsScreenState();
}

class _ReceiptDetailsScreenState extends State<ReceiptDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isProcessing = false;
  bool _isConnected = false;
  String _extractedCompany = '';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _extractReceiptData();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = connectivityResult != ConnectivityResult.none;
    });

    // Listen to connectivity changes
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

  Future<void> _extractReceiptData() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Use OCR service to extract data from the image
      final ocrService = OCRService();
      final extractedData = await ocrService.extractTextFromImage(
        widget.imagePath,
      );

      _extractedCompany = extractedData['company'] ?? 'Unknown Business';

      setState(() {
        _companyController.text = _extractedCompany;
        _isProcessing = false;
      });
    } catch (e) {
      print('Error extracting receipt data: $e');
      // Fallback to default values
      setState(() {
        _extractedCompany = 'Unknown Business';
        _companyController.text = _extractedCompany;
        _isProcessing = false;
      });
    }
  }

  Future<void> _sendReceipt() async {
    if (!_formKey.currentState!.validate()) return;

    if (_isConnected) {
      // Show connected alert and simulate upload
      _showConnectedAlert();
    } else {
      // Save to offline queue
      context.read<ReceiptBloc>().add(
        CreateReceipt(
          imagePath: widget.imagePath,
          merchantName: _companyController.text,
          date: DateTime.now(),
          notes: _notesController.text.isEmpty ? null : _notesController.text,
        ),
      );
      _showOfflineQueueAlert();
    }
  }

  void _showConnectedAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Connected to Internet'),
        content: const Text('Receipt is being uploaded to the server...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _simulateUpload();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showOfflineQueueAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Mode'),
        content: const Text(
          'Receipt saved to offline queue. It will be uploaded when internet connection is available.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to main screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _simulateUpload() async {
    // Simulate upload process
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Uploading receipt...'),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 3));

    // Simulate random success/failure
    final random = Random();
    final success = random.nextBool();

    // Create receipt with upload status
    context.read<ReceiptBloc>().add(
      CreateReceipt(
        imagePath: widget.imagePath,
        merchantName: _companyController.text,
        date: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      ),
    );

    Navigator.pop(context); // Close loading

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(success ? 'Success' : 'Failed'),
        content: Text(
          success
              ? 'Receipt uploaded successfully!'
              : 'Upload failed. Receipt saved to retry queue.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to main screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _isConnected
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isConnected ? Colors.green : Colors.orange,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isConnected ? Icons.wifi : Icons.wifi_off,
                      color: _isConnected ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isConnected ? 'Connected to Internet' : 'Offline Mode',
                      style: TextStyle(
                        color: _isConnected
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Receipt Image
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 24),

              // Processing indicator or form
              if (_isProcessing) ...[
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Extracting receipt data...'),
                    ],
                  ),
                ),
              ] else ...[
                // Company Name Field (Read-only, extracted from receipt)
                Text(
                  'Company Name',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _companyController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Extracted from receipt',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.business),
                    fillColor: Colors.grey.shade50,
                    filled: true,
                    suffixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.grey,
                      size: 20,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Notes Field
                Text(
                  'Notes (Optional)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Add any notes...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 32),

                // Send Receipt Button
                ElevatedButton(
                  onPressed: _sendReceipt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Send Receipt',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _companyController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
