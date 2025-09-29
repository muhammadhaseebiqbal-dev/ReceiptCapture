import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image/image.dart' as img;

class AdvancedCropScreen extends StatefulWidget {
  final String imagePath;

  const AdvancedCropScreen({Key? key, required this.imagePath})
    : super(key: key);

  @override
  State<AdvancedCropScreen> createState() => _AdvancedCropScreenState();
}

class _AdvancedCropScreenState extends State<AdvancedCropScreen> {
  late ui.Image _image;
  late Size _imageSize;
  bool _imageLoaded = false;

  // Crop points (top-left, top-right, bottom-right, bottom-left)
  List<Offset> _cropPoints = [];
  int? _selectedPointIndex;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final file = File(widget.imagePath);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();

    setState(() {
      _image = frame.image;
      _imageSize = Size(_image.width.toDouble(), _image.height.toDouble());
      _imageLoaded = true;

      // Initialize crop points to full image
      final width = _imageSize.width;
      final height = _imageSize.height;
      _cropPoints = [
        const Offset(0, 0), // top-left
        Offset(width, 0), // top-right
        Offset(width, height), // bottom-right
        Offset(0, height), // bottom-left
      ];
    });
  }



  Future<String> _cropImage() async {
    if (_cropPoints.length != 4) return widget.imagePath;

    try {
      // Load original image
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return widget.imagePath;

      // Get the crop area bounds
      final minX = _cropPoints
          .map((p) => p.dx)
          .reduce(min)
          .clamp(0, _imageSize.width);
      final maxX = _cropPoints
          .map((p) => p.dx)
          .reduce(max)
          .clamp(0, _imageSize.width);
      final minY = _cropPoints
          .map((p) => p.dy)
          .reduce(min)
          .clamp(0, _imageSize.height);
      final maxY = _cropPoints
          .map((p) => p.dy)
          .reduce(max)
          .clamp(0, _imageSize.height);

      // Crop the image
      final croppedImage = img.copyCrop(
        originalImage,
        x: minX.toInt(),
        y: minY.toInt(),
        width: (maxX - minX).toInt(),
        height: (maxY - minY).toInt(),
      );

      // Save cropped image
      final croppedPath = widget.imagePath.replaceAll('.jpg', '_cropped.jpg');
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

      return croppedPath;
    } catch (e) {
      print('Error cropping image: $e');
      return widget.imagePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Crop Receipt',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _imageLoaded
          ? Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Calculate the display size to fit the image in the container
                        final screenSize = Size(
                          constraints.maxWidth,
                          constraints.maxHeight,
                        );
                        final imageAspectRatio =
                            _imageSize.width / _imageSize.height;
                        final screenAspectRatio =
                            screenSize.width / screenSize.height;

                        Size displaySize;
                        if (imageAspectRatio > screenAspectRatio) {
                          // Image is wider than screen
                          displaySize = Size(
                            screenSize.width,
                            screenSize.width / imageAspectRatio,
                          );
                        } else {
                          // Image is taller than screen
                          displaySize = Size(
                            screenSize.height * imageAspectRatio,
                            screenSize.height,
                          );
                        }

                        final scaleX = displaySize.width / _imageSize.width;
                        final scaleY = displaySize.height / _imageSize.height;

                        return Center(
                          child: Container(
                            width: displaySize.width,
                            height: displaySize.height,
                            child: GestureDetector(
                              onPanStart: (details) {
                                final localPosition = details.localPosition;

                                // Find the nearest crop point (scale back to display coordinates)
                                double minDistance = double.infinity;
                                int nearestIndex = -1;

                                for (int i = 0; i < _cropPoints.length; i++) {
                                  final scaledPoint = Offset(
                                    _cropPoints[i].dx * scaleX,
                                    _cropPoints[i].dy * scaleY,
                                  );
                                  final distance =
                                      (localPosition - scaledPoint).distance;
                                  if (distance < minDistance && distance < 50) {
                                    minDistance = distance;
                                    nearestIndex = i;
                                  }
                                }

                                if (nearestIndex != -1) {
                                  _selectedPointIndex = nearestIndex;
                                }
                              },
                              onPanUpdate: (details) {
                                if (_selectedPointIndex != null) {
                                  final localPosition = details.localPosition;

                                  // Convert back to image coordinates
                                  final imageX = (localPosition.dx / scaleX)
                                      .clamp(0.0, _imageSize.width);
                                  final imageY = (localPosition.dy / scaleY)
                                      .clamp(0.0, _imageSize.height);

                                  setState(() {
                                    _cropPoints[_selectedPointIndex!] = Offset(
                                      imageX,
                                      imageY,
                                    );
                                  });
                                }
                              },
                              onPanEnd: (details) {
                                _selectedPointIndex = null;
                              },
                              child: CustomPaint(
                                painter: CropPainter(
                                  _image,
                                  _cropPoints,
                                  _selectedPointIndex,
                                  displaySize,
                                  scaleX,
                                  scaleY,
                                ),
                                size: displaySize,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionButton(
                        icon: Icons.check,
                        label: 'Next',
                        onPressed: () async {
                          // Show loading
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          final croppedPath = await _cropImage();
                          Navigator.pop(context); // Close loading
                          Navigator.pop(context, croppedPath);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}

class CropPainter extends CustomPainter {
  final ui.Image image;
  final List<Offset> cropPoints;
  final int? selectedPointIndex;
  final Size displaySize;
  final double scaleX;
  final double scaleY;

  CropPainter(
    this.image,
    this.cropPoints,
    this.selectedPointIndex,
    this.displaySize,
    this.scaleX,
    this.scaleY,
  );

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the image scaled to fit the display size
    final paint = Paint();
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(image, srcRect, dstRect, paint);

    if (cropPoints.length == 4) {
      // Convert crop points to display coordinates
      final scaledCropPoints = cropPoints
          .map((point) => Offset(point.dx * scaleX, point.dy * scaleY))
          .toList();

      // Draw overlay (darken areas outside crop)
      final overlayPaint = Paint()..color = Colors.black.withOpacity(0.5);

      // Draw full overlay first
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        overlayPaint,
      );

      // Create crop path in display coordinates
      final cropPath = Path();
      if (scaledCropPoints.isNotEmpty) {
        cropPath.moveTo(scaledCropPoints[0].dx, scaledCropPoints[0].dy);
        for (int i = 1; i < scaledCropPoints.length; i++) {
          cropPath.lineTo(scaledCropPoints[i].dx, scaledCropPoints[i].dy);
        }
        cropPath.close();
      }

      // Clear the crop area to show the original image
      canvas.save();
      canvas.clipPath(cropPath);
      canvas.drawImageRect(image, srcRect, dstRect, Paint());
      canvas.restore();

      // Draw crop lines
      final linePaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;

      canvas.drawPath(cropPath, linePaint);

      // Draw corner points
      for (int i = 0; i < scaledCropPoints.length; i++) {
        final pointPaint = Paint()
          ..color = selectedPointIndex == i ? Colors.red : Colors.blue
          ..style = PaintingStyle.fill;

        canvas.drawCircle(scaledCropPoints[i], 15, pointPaint);

        // Draw white border
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

        canvas.drawCircle(scaledCropPoints[i], 15, borderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
