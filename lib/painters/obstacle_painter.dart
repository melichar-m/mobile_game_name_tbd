import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../models/obstacle.dart';

class ObstaclePainter extends CustomPainter {
  final Offset cameraPosition;
  final List<Obstacle> obstacles;
  final Map<String, ui.Image> images;

  ObstaclePainter({
    required this.cameraPosition,
    required this.obstacles,
    required this.images,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // Draw each obstacle relative to camera position
    for (final obstacle in obstacles) {
      final screenRect = Rect.fromLTWH(
        obstacle.bounds.left - cameraPosition.dx,
        obstacle.bounds.top - cameraPosition.dy,
        obstacle.bounds.width,
        obstacle.bounds.height,
      );
      
      // Draw the obstacle image if available, otherwise draw a placeholder
      final image = images[obstacle.type.id];
      if (image != null) {
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          screenRect,
          paint,
        );
      } else {
        // Fallback to a colored rectangle if image is not loaded
        canvas.drawRect(
          screenRect,
          Paint()
            ..color = Colors.grey[800]!
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          screenRect,
          Paint()
            ..color = Colors.grey[600]!
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(ObstaclePainter oldDelegate) {
    return oldDelegate.cameraPosition != cameraPosition;
  }
} 