import 'package:flutter/material.dart';

class ObstaclePainter extends CustomPainter {
  final Offset cameraPosition;
  final List<Rect> obstacles;

  ObstaclePainter({
    required this.cameraPosition,
    required this.obstacles,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[800]!
      ..style = PaintingStyle.fill;

    // Draw each obstacle relative to camera position
    for (final obstacle in obstacles) {
      final screenRect = Rect.fromLTWH(
        obstacle.left - cameraPosition.dx,
        obstacle.top - cameraPosition.dy,
        obstacle.width,
        obstacle.height,
      );
      
      // Draw the obstacle
      canvas.drawRect(screenRect, paint);
      
      // Draw border
      canvas.drawRect(
        screenRect,
        Paint()
          ..color = Colors.grey[600]!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(ObstaclePainter oldDelegate) {
    return oldDelegate.cameraPosition != cameraPosition;
  }
} 