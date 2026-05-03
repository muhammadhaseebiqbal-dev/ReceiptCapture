import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../features/receipt/bloc/receipt_bloc.dart';
import '../features/receipt/bloc/receipt_event.dart';
import '../features/receipt/bloc/receipt_state.dart';
import '../core/services/ocr_service.dart';

class ReceiptDetailsScreen extends StatefulWidget {
  final String imagePath;

  const ReceiptDetailsScreen({super.key, required this.imagePath});

  @override
  State<ReceiptDetailsScreen> createState() => _ReceiptDetailsScreenState();
}

class _ReceiptDetailsScreenState extends State<ReceiptDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  bool _isProcessing = false;
  bool _isConnected = false;
  String _extractedCompany = '';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _extractReceiptData();
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    _companyController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() {
        _isConnected = connectivityResult != ConnectivityResult.none;
      });
    }

    // Listen to connectivity changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (mounted) {
        setState(() {
          _isConnected = result != ConnectivityResult.none;
        });
      }
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
      final amount = extractedData['amount'];
      final amountStr = amount != null ? amount.toStringAsFixed(2) : '';

      setState(() {
        _companyController.text = _extractedCompany;
        if (amountStr.isNotEmpty) {
          _amountController.text = amountStr;
        }
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Error extracting receipt data: $e');
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

    double? amount;
    if (_amountController.text.isNotEmpty) {
      amount = double.tryParse(_amountController.text);
    }

    context.read<ReceiptBloc>().add(
      CreateReceipt(
        imagePath: widget.imagePath,
        merchantName: _companyController.text,
        amount: amount,
        date: DateTime.now(),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
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
      body: BlocListener<ReceiptBloc, ReceiptState>(
        listener: (context, state) {
          if (state.status == ReceiptStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  _isConnected
                      ? 'Receipt saved and synced successfully'
                      : 'Receipt saved to offline queue',
                ),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context);
          } else if (state.status == ReceiptStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
                ],
                const SizedBox(height: 24),
                Text(
                  'Receipt Amount',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    hintText: 'Enter receipt amount',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: const Icon(Icons.attach_money),
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final amount = double.tryParse(value);
                      if (amount == null) {
                        return 'Please enter a valid amount';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
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
            ),
          ),
        ),
      ),
    );
  }
}
