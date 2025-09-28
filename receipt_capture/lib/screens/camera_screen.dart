import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

import '../features/receipt/bloc/receipt_bloc.dart';
import '../features/receipt/bloc/receipt_state.dart';
import '../shared/theme/app_theme.dart';
import '../shared/widgets/loading_indicator.dart';
import 'receipt_form_screen.dart';
import 'advanced_crop_screen.dart';
import 'receipt_details_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }
      }
    } catch (e) {
      print('Camera initialization error: $e');
    }
  }

  Future<void> _captureImage() async {
    if (!_isCameraInitialized || _cameraController == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not initialized'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    try {
      final XFile image = await _cameraController!.takePicture();

      if (mounted) {
        // Navigate to advanced crop screen
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => AdvancedCropScreen(imagePath: image.path),
              ),
            )
            .then((croppedPath) {
              if (croppedPath != null && mounted) {
                // Navigate to receipt details screen with cropped image
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ReceiptDetailsScreen(imagePath: croppedPath),
                  ),
                );
              }
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null && mounted) {
        // Navigate to advanced crop screen with selected image
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => AdvancedCropScreen(imagePath: image.path),
              ),
            )
            .then((croppedPath) {
              if (croppedPath != null && mounted) {
                // Navigate to receipt details screen with cropped image
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        ReceiptDetailsScreen(imagePath: croppedPath),
                  ),
                );
              }
            });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController != null && _isCameraInitialized) {
      try {
        if (_isFlashOn) {
          await _cameraController!.setFlashMode(FlashMode.off);
        } else {
          await _cameraController!.setFlashMode(FlashMode.torch);
        }
        setState(() {
          _isFlashOn = !_isFlashOn;
        });
      } catch (e) {
        print('Flash toggle error: $e');
      }
    }
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Capture Receipt',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
      body: BlocListener<ReceiptBloc, ReceiptState>(
        listener: (context, state) {
          if (state.status == ReceiptStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          } else if (state.capturedImagePath.isNotEmpty) {
            // Navigate to receipt form with captured image
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReceiptFormScreen(
                  imagePath: state.capturedImagePath,
                  croppedImagePath: state.croppedImagePath.isNotEmpty
                      ? state.croppedImagePath
                      : null,
                ),
              ),
            );
          }
        },
        child: BlocBuilder<ReceiptBloc, ReceiptState>(
          builder: (context, state) {
            if (state.status == ReceiptStatus.capturing) {
              return const LoadingIndicator(message: 'Capturing image...');
            }

            return Stack(
              children: [
                // Camera preview
                if (_isCameraInitialized && _cameraController != null)
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: _cameraController!.value.aspectRatio,
                      child: CameraPreview(_cameraController!),
                    ),
                  )
                else
                  const Positioned.fill(
                    child: Center(
                      child: LoadingIndicator(
                        message: 'Initializing camera...',
                      ),
                    ),
                  ),

                // Camera overlay with receipt guide
                Positioned.fill(
                  child: CustomPaint(painter: ReceiptOverlayPainter()),
                ),

                // Bottom controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingM,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Gallery button
                          _buildControlButton(
                            icon: Icons.photo_library_outlined,
                            label: 'Gallery',
                            onPressed: _pickFromGallery,
                          ),

                          // Capture button
                          GestureDetector(
                            onTap: _captureImage,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 4,
                                    ),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Capture',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Instructions
                Positioned(
                  top: 120,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.spacingM),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long, color: Colors.white, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          'Align receipt within the frame',
                          style: AppTheme.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Ensure all corners are visible',
                          style: AppTheme.bodySmall.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ReceiptOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint overlayPaint = Paint()..color = Colors.black.withOpacity(0.3);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint cornerPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    // Receipt frame dimensions
    const double margin = 32.0;
    final Rect receiptRect = Rect.fromLTRB(
      margin,
      size.height * 0.15,
      size.width - margin,
      size.height * 0.75,
    );

    // Draw overlay (darken everything except the receipt area)
    final Path overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(receiptRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);

    // Draw receipt frame border
    canvas.drawRect(receiptRect, borderPaint);

    // Draw corner indicators
    const double cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(
      Offset(receiptRect.left, receiptRect.top),
      Offset(receiptRect.left + cornerLength, receiptRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(receiptRect.left, receiptRect.top),
      Offset(receiptRect.left, receiptRect.top + cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(receiptRect.right, receiptRect.top),
      Offset(receiptRect.right - cornerLength, receiptRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(receiptRect.right, receiptRect.top),
      Offset(receiptRect.right, receiptRect.top + cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(receiptRect.left, receiptRect.bottom),
      Offset(receiptRect.left + cornerLength, receiptRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(receiptRect.left, receiptRect.bottom),
      Offset(receiptRect.left, receiptRect.bottom - cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(receiptRect.right, receiptRect.bottom),
      Offset(receiptRect.right - cornerLength, receiptRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(receiptRect.right, receiptRect.bottom),
      Offset(receiptRect.right, receiptRect.bottom - cornerLength),
      cornerPaint,
    );

    // Draw center crosshairs
    final Paint crosshairPaint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final Offset center = receiptRect.center;
    const double crosshairLength = 20.0;

    canvas.drawLine(
      Offset(center.dx - crosshairLength, center.dy),
      Offset(center.dx + crosshairLength, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairLength),
      Offset(center.dx, center.dy + crosshairLength),
      crosshairPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
