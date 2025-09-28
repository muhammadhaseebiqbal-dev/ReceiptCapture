import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class SimpleCropScreen extends StatefulWidget {
  final String imagePath;

  const SimpleCropScreen({super.key, required this.imagePath});

  @override
  State<SimpleCropScreen> createState() => _SimpleCropScreenState();
}

class _SimpleCropScreenState extends State<SimpleCropScreen> {
  final GlobalKey _cropKey = GlobalKey();
  late Size _screenSize;
  Offset _cropOffset = Offset.zero;
  Size _cropSize = const Size(300, 400);
  bool _isImageLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    setState(() {
      _isImageLoaded = true;
    });
  }

  Future<String?> _cropImage() async {
    try {
      // Get the render object
      final RenderRepaintBoundary boundary =
          _cropKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData == null) return null;

      // Save the cropped image
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'receipt_cropped_$timestamp.jpg';
      final filePath = path.join(
        directory.path,
        'receipts',
        'cropped',
        fileName,
      );

      // Ensure directory exists
      await Directory(path.dirname(filePath)).create(recursive: true);

      final File file = File(filePath);
      await file.writeAsBytes(byteData.buffer.asUint8List());

      return filePath;
    } catch (e) {
      print('Error cropping image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Crop Receipt'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () async {
              final croppedPath = await _cropImage();
              if (mounted) {
                Navigator.pop(context, croppedPath);
              }
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isImageLoaded
          ? LayoutBuilder(
              builder: (context, constraints) {
                _screenSize = Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(
                  children: [
                    // Background image
                    Positioned.fill(
                      child: Image.file(
                        File(widget.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),

                    // Crop overlay
                    Positioned.fill(
                      child: CustomPaint(
                        painter: CropOverlayPainter(
                          cropRect: Rect.fromLTWH(
                            _cropOffset.dx,
                            _cropOffset.dy,
                            _cropSize.width,
                            _cropSize.height,
                          ),
                        ),
                      ),
                    ),

                    // Draggable crop area
                    Positioned(
                      left: _cropOffset.dx,
                      top: _cropOffset.dy,
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _cropOffset = Offset(
                              (_cropOffset.dx + details.delta.dx).clamp(
                                0,
                                _screenSize.width - _cropSize.width,
                              ),
                              (_cropOffset.dy + details.delta.dy).clamp(
                                0,
                                _screenSize.height - _cropSize.height,
                              ),
                            );
                          });
                        },
                        child: RepaintBoundary(
                          key: _cropKey,
                          child: Container(
                            width: _cropSize.width,
                            height: _cropSize.height,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: ClipRect(
                              child: OverflowBox(
                                alignment: Alignment.topLeft,
                                child: Transform.translate(
                                  offset: -_cropOffset,
                                  child: Image.file(
                                    File(widget.imagePath),
                                    fit: BoxFit.contain,
                                    width: _screenSize.width,
                                    height: _screenSize.height,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Corner handles for resizing
                    ...List.generate(4, (index) {
                      late Offset handlePosition;
                      switch (index) {
                        case 0: // Top-left
                          handlePosition = _cropOffset;
                          break;
                        case 1: // Top-right
                          handlePosition = Offset(
                            _cropOffset.dx + _cropSize.width,
                            _cropOffset.dy,
                          );
                          break;
                        case 2: // Bottom-left
                          handlePosition = Offset(
                            _cropOffset.dx,
                            _cropOffset.dy + _cropSize.height,
                          );
                          break;
                        case 3: // Bottom-right
                          handlePosition = Offset(
                            _cropOffset.dx + _cropSize.width,
                            _cropOffset.dy + _cropSize.height,
                          );
                          break;
                      }

                      return Positioned(
                        left: handlePosition.dx - 8,
                        top: handlePosition.dy - 8,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              switch (index) {
                                case 0: // Top-left
                                  _cropOffset = Offset(
                                    (_cropOffset.dx + details.delta.dx).clamp(
                                      0,
                                      _cropOffset.dx + _cropSize.width - 100,
                                    ),
                                    (_cropOffset.dy + details.delta.dy).clamp(
                                      0,
                                      _cropOffset.dy + _cropSize.height - 100,
                                    ),
                                  );
                                  _cropSize = Size(
                                    (_cropSize.width - details.delta.dx).clamp(
                                      100,
                                      400,
                                    ),
                                    (_cropSize.height - details.delta.dy).clamp(
                                      100,
                                      500,
                                    ),
                                  );
                                  break;
                                case 3: // Bottom-right
                                  _cropSize = Size(
                                    (_cropSize.width + details.delta.dx).clamp(
                                      100,
                                      400,
                                    ),
                                    (_cropSize.height + details.delta.dy).clamp(
                                      100,
                                      500,
                                    ),
                                  );
                                  break;
                              }
                            });
                          },
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              },
            )
          : const Center(child: CircularProgressIndicator()),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.black,
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context, null); // Cancel
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    // Reset to center
                    _cropOffset = Offset(
                      (_screenSize.width - _cropSize.width) / 2,
                      (_screenSize.height - _cropSize.height) / 2,
                    );
                  });
                },
                icon: const Icon(Icons.center_focus_strong),
                label: const Text('Center'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CropOverlayPainter extends CustomPainter {
  final Rect cropRect;

  CropOverlayPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);

    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw overlay
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(cropRect)
        ..fillType = PathFillType.evenOdd,
      overlayPaint,
    );

    // Draw crop border
    canvas.drawRect(cropRect, borderPaint);

    // Draw corner indicators
    final cornerSize = 20.0;
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top),
      Offset(cropRect.left + cornerSize, cropRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.top),
      Offset(cropRect.left, cropRect.top + cornerSize),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(cropRect.right, cropRect.top),
      Offset(cropRect.right - cornerSize, cropRect.top),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.right, cropRect.top),
      Offset(cropRect.right, cropRect.top + cornerSize),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cropRect.left, cropRect.bottom),
      Offset(cropRect.left + cornerSize, cropRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.left, cropRect.bottom),
      Offset(cropRect.left, cropRect.bottom - cornerSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(cropRect.right, cropRect.bottom),
      Offset(cropRect.right - cornerSize, cropRect.bottom),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(cropRect.right, cropRect.bottom),
      Offset(cropRect.right, cropRect.bottom - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
