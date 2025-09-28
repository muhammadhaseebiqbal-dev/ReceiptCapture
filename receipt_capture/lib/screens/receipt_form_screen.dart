import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:io';
import '../features/receipt/bloc/receipt_bloc.dart';
import '../features/receipt/bloc/receipt_event.dart';
import '../features/receipt/bloc/receipt_state.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/loading_indicator.dart';
import 'simple_crop_screen.dart';

class ReceiptFormScreen extends StatefulWidget {
  final String imagePath;
  final String? croppedImagePath;
  final bool isEditing;

  const ReceiptFormScreen({
    super.key,
    required this.imagePath,
    this.croppedImagePath,
    this.isEditing = false,
  });

  @override
  State<ReceiptFormScreen> createState() => _ReceiptFormScreenState();
}

class _ReceiptFormScreenState extends State<ReceiptFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  String? _currentImagePath;
  bool _isCropping = false;

  final List<String> _categories = [
    'Food & Dining',
    'Shopping',
    'Transportation',
    'Entertainment',
    'Health & Medical',
    'Bills & Utilities',
    'Travel',
    'Business',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _currentImagePath = widget.croppedImagePath ?? widget.imagePath;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _cropImage() async {
    setState(() {
      _isCropping = true;
    });

    try {
      final String? croppedPath = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleCropScreen(imagePath: widget.imagePath),
        ),
      );

      if (croppedPath != null) {
        setState(() {
          _currentImagePath = croppedPath;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to crop image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCropping = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  void _saveReceipt() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final merchantName = _merchantController.text.trim().isEmpty
        ? null
        : _merchantController.text.trim();

    final amountText = _amountController.text.trim();
    final amount = amountText.isEmpty ? null : double.tryParse(amountText);

    final notes = _notesController.text.trim().isEmpty
        ? null
        : _notesController.text.trim();

    context.read<ReceiptBloc>().add(
      CreateReceipt(
        imagePath: widget.imagePath,
        croppedImagePath: _currentImagePath != widget.imagePath
            ? _currentImagePath
            : null,
        merchantName: merchantName,
        amount: amount,
        date: _selectedDate,
        category: _selectedCategory,
        notes: notes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Receipt' : 'New Receipt'),
        actions: [
          TextButton(
            onPressed: _saveReceipt,
            child: Text(
              'Save',
              style: TextStyle(
                color: Theme.of(context).appBarTheme.foregroundColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: BlocListener<ReceiptBloc, ReceiptState>(
        listener: (context, state) {
          if (state.status == ReceiptStatus.success && !widget.isEditing) {
            // Receipt saved successfully, go back
            Navigator.of(context).pop();
          } else if (state.status == ReceiptStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          } else if (state.croppedImagePath.isNotEmpty &&
              state.croppedImagePath != _currentImagePath) {
            setState(() {
              _currentImagePath = state.croppedImagePath;
              _isCropping = false;
            });
          }
        },
        child: BlocBuilder<ReceiptBloc, ReceiptState>(
          builder: (context, state) {
            if (state.status == ReceiptStatus.loading) {
              return const LoadingIndicator(message: 'Saving receipt...');
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingM),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Receipt image
                    _buildImageSection(),
                    const SizedBox(height: AppTheme.spacingL),

                    // Receipt details form
                    _buildFormFields(),

                    const SizedBox(height: AppTheme.spacingXL),

                    // Save button
                    ElevatedButton(
                      onPressed: _saveReceipt,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        widget.isEditing ? 'Update Receipt' : 'Save Receipt',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Image display
          Container(
            height: 300,
            width: double.infinity,
            child:
                _currentImagePath != null &&
                    File(_currentImagePath!).existsSync()
                ? Image.file(File(_currentImagePath!), fit: BoxFit.cover)
                : Container(
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.receipt,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
          ),

          // Image actions
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingM),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: _isCropping ? null : _cropImage,
                  icon: _isCropping
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.crop),
                  label: Text(_isCropping ? 'Cropping...' : 'Crop'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement retake functionality
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Retake'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Merchant name
        TextFormField(
          controller: _merchantController,
          decoration: const InputDecoration(
            labelText: 'Merchant Name',
            hintText: 'e.g., Walmart, Target, etc.',
            prefixIcon: Icon(Icons.store),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Amount
        TextFormField(
          controller: _amountController,
          decoration: const InputDecoration(
            labelText: 'Amount',
            hintText: '0.00',
            prefixIcon: Icon(Icons.attach_money),
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value != null && value.isNotEmpty) {
              if (double.tryParse(value) == null) {
                return 'Please enter a valid amount';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Date
        InkWell(
          onTap: _selectDate,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Date',
              prefixIcon: Icon(Icons.calendar_today),
              suffixIcon: Icon(Icons.arrow_drop_down),
            ),
            child: Text(
              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Category
        DropdownButtonFormField<String>(
          value: _selectedCategory,
          decoration: const InputDecoration(
            labelText: 'Category',
            prefixIcon: Icon(Icons.category),
          ),
          hint: const Text('Select a category'),
          items: _categories.map((category) {
            return DropdownMenuItem(value: category, child: Text(category));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
        ),
        const SizedBox(height: AppTheme.spacingM),

        // Notes
        TextFormField(
          controller: _notesController,
          decoration: const InputDecoration(
            labelText: 'Notes (Optional)',
            hintText: 'Add any additional notes...',
            prefixIcon: Icon(Icons.note),
          ),
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}
