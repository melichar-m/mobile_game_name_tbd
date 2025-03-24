import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class BackgroundPainter extends CustomPainter {
  final ui.Image backgroundImage;
  final Offset cameraPosition;
  final double scale;

  BackgroundPainter({
    required this.backgroundImage,
    required this.cameraPosition,
    this.scale = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Calculate how many tiles we need to cover the screen
    int horizontalTiles = (size.width * scale / backgroundImage.width).ceil() + 1;
    int verticalTiles = (size.height * scale / backgroundImage.height).ceil() + 1;
    
    // Calculate the offset for smooth scrolling
    double xOffset = -cameraPosition.dx % (backgroundImage.width * scale);
    double yOffset = -cameraPosition.dy % (backgroundImage.height * scale);
    
    // Draw background tiles
    for (int y = -1; y < verticalTiles; y++) {
      for (int x = -1; x < horizontalTiles; x++) {
        canvas.drawImageRect(
          backgroundImage,
          Rect.fromLTWH(0, 0, backgroundImage.width.toDouble(), backgroundImage.height.toDouble()),
          Rect.fromLTWH(
            x * backgroundImage.width * scale + xOffset,
            y * backgroundImage.height * scale + yOffset,
            backgroundImage.width * scale,
            backgroundImage.height * scale,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) {
    return oldDelegate.cameraPosition != cameraPosition;
  }
} 