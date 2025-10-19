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
  bool _autoDetecting = true;

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
    });

    // Auto-detect edges
    await _autoDetectEdges();
  }

  Future<void> _autoDetectEdges() async {
    setState(() {
      _autoDetecting = true;
    });

    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage != null) {
        final detectedPoints = _detectDocumentEdges(originalImage);

        setState(() {
          _cropPoints = detectedPoints;
          _autoDetecting = false;
        });

        // Haptic feedback when detection completes
        HapticFeedback.lightImpact();
      }
    } catch (e) {
      print('Auto-detection error: $e');
      // Fallback to full image
      final width = _imageSize.width;
      final height = _imageSize.height;
      setState(() {
        _cropPoints = [
          Offset(width * 0.05, height * 0.05), // top-left with small margin
          Offset(width * 0.95, height * 0.05), // top-right
          Offset(width * 0.95, height * 0.95), // bottom-right
          Offset(width * 0.05, height * 0.95), // bottom-left
        ];
        _autoDetecting = false;
      });
    }
  }

  List<Offset> _detectDocumentEdges(img.Image image) {
    // Convert to grayscale
    final grayscale = img.grayscale(image);

    // Apply Gaussian blur to reduce noise
    final blurred = img.gaussianBlur(grayscale, radius: 5);

    // Edge detection using Sobel operator
    final edges = _applySobelEdgeDetection(blurred);

    // Find contours and get the largest quadrilateral
    final corners = _findLargestQuadrilateral(edges);

    return corners;
  }

  img.Image _applySobelEdgeDetection(img.Image image) {
    final result = img.Image(width: image.width, height: image.height);

    // Sobel kernels
    final sobelX = [
      [-1, 0, 1],
      [-2, 0, 2],
      [-1, 0, 1],
    ];
    final sobelY = [
      [-1, -2, -1],
      [0, 0, 0],
      [1, 2, 1],
    ];

    for (int y = 1; y < image.height - 1; y++) {
      for (int x = 1; x < image.width - 1; x++) {
        double gx = 0;
        double gy = 0;

        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = image.getPixel(x + kx, y + ky);
            final intensity = pixel.r.toDouble();
            gx += intensity * sobelX[ky + 1][kx + 1];
            gy += intensity * sobelY[ky + 1][kx + 1];
          }
        }

        final magnitude = sqrt(gx * gx + gy * gy).clamp(0, 255).toInt();
        final color = img.ColorRgba8(magnitude, magnitude, magnitude, 255);
        result.setPixel(x, y, color);
      }
    }

    return result;
  }

  List<Offset> _findLargestQuadrilateral(img.Image edges) {
    // Simplified contour detection
    // Find bright pixels (edges) and cluster them
    final width = edges.width.toDouble();
    final height = edges.height.toDouble();

    // Divide image into grid and find edge densities
    final gridSize = 20;
    final cellWidth = width / gridSize;
    final cellHeight = height / gridSize;

    double maxDensityTop = 0, maxDensityBottom = 0;
    double maxDensityLeft = 0, maxDensityRight = 0;
    int topRow = 0, bottomRow = gridSize - 1;
    int leftCol = 0, rightCol = gridSize - 1;

    // Find top edge
    for (int row = 0; row < gridSize ~/ 2; row++) {
      double density = 0;
      for (int col = 0; col < gridSize; col++) {
        density += _getEdgeDensityInCell(
          edges,
          col,
          row,
          cellWidth,
          cellHeight,
        );
      }
      if (density > maxDensityTop) {
        maxDensityTop = density;
        topRow = row;
      }
    }

    // Find bottom edge
    for (int row = gridSize - 1; row >= gridSize ~/ 2; row--) {
      double density = 0;
      for (int col = 0; col < gridSize; col++) {
        density += _getEdgeDensityInCell(
          edges,
          col,
          row,
          cellWidth,
          cellHeight,
        );
      }
      if (density > maxDensityBottom) {
        maxDensityBottom = density;
        bottomRow = row;
      }
    }

    // Find left edge
    for (int col = 0; col < gridSize ~/ 2; col++) {
      double density = 0;
      for (int row = 0; row < gridSize; row++) {
        density += _getEdgeDensityInCell(
          edges,
          col,
          row,
          cellWidth,
          cellHeight,
        );
      }
      if (density > maxDensityLeft) {
        maxDensityLeft = density;
        leftCol = col;
      }
    }

    // Find right edge
    for (int col = gridSize - 1; col >= gridSize ~/ 2; col--) {
      double density = 0;
      for (int row = 0; row < gridSize; row++) {
        density += _getEdgeDensityInCell(
          edges,
          col,
          row,
          cellWidth,
          cellHeight,
        );
      }
      if (density > maxDensityRight) {
        maxDensityRight = density;
        rightCol = col;
      }
    }

    // Calculate corner positions
    final topLeft = Offset(
      leftCol * cellWidth + cellWidth / 2,
      topRow * cellHeight + cellHeight / 2,
    );
    final topRight = Offset(
      rightCol * cellWidth + cellWidth / 2,
      topRow * cellHeight + cellHeight / 2,
    );
    final bottomRight = Offset(
      rightCol * cellWidth + cellWidth / 2,
      bottomRow * cellHeight + cellHeight / 2,
    );
    final bottomLeft = Offset(
      leftCol * cellWidth + cellWidth / 2,
      bottomRow * cellHeight + cellHeight / 2,
    );

    return [topLeft, topRight, bottomRight, bottomLeft];
  }

  double _getEdgeDensityInCell(
    img.Image edges,
    int col,
    int row,
    double cellWidth,
    double cellHeight,
  ) {
    final startX = (col * cellWidth).toInt();
    final startY = (row * cellHeight).toInt();
    final endX = min(((col + 1) * cellWidth).toInt(), edges.width);
    final endY = min(((row + 1) * cellHeight).toInt(), edges.height);

    double density = 0;
    int count = 0;

    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        final pixel = edges.getPixel(x, y);
        density += pixel.r.toDouble();
        count++;
      }
    }

    return count > 0 ? density / count : 0;
  }

  Future<String> _cropImage() async {
    if (_cropPoints.length != 4) return widget.imagePath;

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      // Load original image
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final originalImage = img.decodeImage(bytes);

      if (originalImage == null) return widget.imagePath;

      // Apply perspective transform for better quality
      final croppedImage = _perspectiveTransform(originalImage);

      // Save cropped image
      final croppedPath = widget.imagePath.replaceAll('.jpg', '_cropped.jpg');
      final croppedFile = File(croppedPath);
      await croppedFile.writeAsBytes(img.encodeJpg(croppedImage, quality: 95));

      return croppedPath;
    } catch (e) {
      print('Error cropping image: $e');
      return widget.imagePath;
    }
  }

  img.Image _perspectiveTransform(img.Image original) {
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

    // For now, simple crop (perspective transform is complex)
    // You can implement full perspective correction using matrix transformation
    final cropped = img.copyCrop(
      original,
      x: minX.toInt(),
      y: minY.toInt(),
      width: (maxX - minX).toInt(),
      height: (maxY - minY).toInt(),
    );

    // Enhance the cropped image
    return _enhanceImage(cropped);
  }

  img.Image _enhanceImage(img.Image image) {
    // Increase contrast
    final enhanced = img.contrast(image, contrast: 120);

    // Adjust brightness slightly
    final adjusted = img.adjustColor(enhanced, brightness: 1.05);

    return adjusted;
  }

  void _resetCrop() {
    HapticFeedback.selectionClick();
    setState(() {
      _autoDetecting = true;
    });
    _autoDetectEdges();
  }

  void _handleCropAndContinue() async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final croppedPath = await _cropImage();
    Navigator.pop(context); // Close loading
    Navigator.pop(context, croppedPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Auto Crop Receipt',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
        ),
        actions: [
          if (_imageLoaded && !_autoDetecting)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetCrop,
              tooltip: 'Re-detect',
            ),
        ],
      ),
      body: _imageLoaded
          ? Column(
              children: [
                if (_autoDetecting)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.blue,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Auto-detecting edges...',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
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
                                if (_autoDetecting) return;

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
                                  HapticFeedback.selectionClick();
                                  _selectedPointIndex = nearestIndex;
                                }
                              },
                              onPanUpdate: (details) {
                                if (_selectedPointIndex != null &&
                                    !_autoDetecting) {
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
                                if (_selectedPointIndex != null) {
                                  HapticFeedback.lightImpact();
                                }
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
                                  _autoDetecting,
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
                        label: 'Crop & Continue',
                        onPressed: _autoDetecting
                            ? null
                            : _handleCropAndContinue,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading image...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: onPressed != null ? Colors.blue : Colors.grey,
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
  final bool isAutoDetecting;

  CropPainter(
    this.image,
    this.cropPoints,
    this.selectedPointIndex,
    this.displaySize,
    this.scaleX,
    this.scaleY,
    this.isAutoDetecting,
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
