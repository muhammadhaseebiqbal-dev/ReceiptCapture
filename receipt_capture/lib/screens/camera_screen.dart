import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _showInstructions = true;
  late AnimationController _scannerAnimationController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerAnimationController.dispose();
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  void _disposeCamera() {
    if (_cameraController != null) {
      _cameraController!.dispose();
      _cameraController = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Dispose existing controller if any
      _disposeCamera();

      final cameras = await availableCameras();
      if (cameras.isNotEmpty && mounted) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high, // Balanced for performance and OCR detection
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );

        await _cameraController!.initialize();

        // Enhance auto-detect engine by setting optimal focus & exposure
        try {
          await _cameraController!.setFocusMode(FocusMode.auto);
          await _cameraController!.setExposureMode(ExposureMode.auto);
        } catch (_) {}

        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });

          // Hide instructions after 1 second delay
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                _showInstructions = false;
              });
            }
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
      // Add haptic feedback when capturing
      HapticFeedback.mediumImpact();

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

                // Camera overlay with receipt guide (Animated auto-detect engine UI)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _scannerAnimationController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: ReceiptOverlayPainter(
                          animationValue: _scannerAnimationController.value,
                        ),
                      );
                    },
                  ),
                ),

                // Bottom controls
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingL,
                      vertical: AppTheme.spacingXL,
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
                      child: SizedBox(
                        height: 120,
                        child: Stack(
                          children: [
                            // Gallery button - Left side
                            Positioned(
                              left: 20,
                              top: 20,
                              child: _buildControlButton(
                                icon: Icons.photo_library_outlined,
                                label: 'Gallery',
                                onPressed: _pickFromGallery,
                              ),
                            ),

                            // Capture button - Perfectly centered
                            Positioned.fill(
                              child: Center(
                                child: GestureDetector(
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
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Capture',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Instructions with auto-hide
                if (_showInstructions)
                  Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: AnimatedOpacity(
                      opacity: _showInstructions ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        padding: const EdgeInsets.all(AppTheme.spacingM),
                        margin: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingL,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(AppTheme.radiusM),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: 32,
                            ),
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
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class   ReceiptOverlayPainter extends CustomPainter {
  final double animationValue;

  ReceiptOverlayPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // Determine the scanning area
    final double margin = size.width * 0.1;
    final Rect scanRect = Rect.fromLTRB(
      margin,
      margin * 3,
      size.width - margin,
      size.height - margin * 3.5,
    );

    // Dim the surrounding area
    final Paint darkOverlay = Paint()
      ..color = Colors.black.withOpacity(0.55);
    final Path backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final Path scanAreaPath = Path()..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));
    canvas.drawPath(
      Path.combine(PathOperation.difference, backgroundPath, scanAreaPath),
      darkOverlay,
    );

    // Draw the active auto-detect bounding box corners
    final Paint edgePaint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0;

    const double cornerLength = 30.0;
    
    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLength)
        ..lineTo(scanRect.left, scanRect.top)
        ..lineTo(scanRect.left + cornerLength, scanRect.top),
      edgePaint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top + cornerLength),
      edgePaint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLength)
        ..lineTo(scanRect.left, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLength, scanRect.bottom),
      edgePaint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLength, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom - cornerLength),
      edgePaint,
    );

    // Draw scanning laser
    final Paint laserPaint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final double laserY = scanRect.top + (scanRect.height * animationValue);
    canvas.drawLine(
      Offset(scanRect.left + 5, laserY),
      Offset(scanRect.right - 5, laserY),
      laserPaint,
    );

    // Draw a subtle glow for the laser
    final Paint laserGlow = Paint()
      ..color = Colors.greenAccent.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final Path glowPath = Path()
      ..addOval(Rect.fromLTRB(
        scanRect.left + 5,
        laserY - 10,
        scanRect.right - 5,
        laserY + 2,
      ));
    
    canvas.drawPath(glowPath, laserGlow);
  }

  @override
  bool shouldRepaint(covariant ReceiptOverlayPainter oldDelegate) {
    return oldDelegate.animationValue != this.animationValue;
  }
}
