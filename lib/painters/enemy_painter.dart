import 'package:flutter/material.dart';
import '../models/enemy.dart';
import 'dart:math' as math;

class EnemyPainter extends CustomPainter {
  final List<Enemy> enemies;
  final Offset cameraPosition;

  EnemyPainter({
    required this.enemies,
    required this.cameraPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final enemy in enemies) {
      if (!enemy.isAlive) continue;

      // Convert world position to screen position
      final screenPos = Offset(
        enemy.position.dx - cameraPosition.dx,
        enemy.position.dy - cameraPosition.dy,
      );

      final paint = Paint()
        ..color = enemy.color
        ..style = PaintingStyle.fill;

      // Draw different shapes based on enemy type
      switch (enemy.type) {
        case EnemyType.basic:
          _drawTriangle(canvas, screenPos, enemy.size, paint);
          break;
        case EnemyType.fast:
          canvas.drawCircle(screenPos, enemy.size / 2, paint);
          break;
        case EnemyType.tank:
          canvas.drawRect(
            Rect.fromCenter(
              center: screenPos,
              width: enemy.size,
              height: enemy.size,
            ),
            paint,
          );
          break;
      }

      // Draw health bar
      _drawHealthBar(canvas, screenPos, enemy);
    }
  }

  void _drawTriangle(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final halfSize = size / 2;
    
    path.moveTo(center.dx, center.dy - halfSize); // Top
    path.lineTo(center.dx - halfSize, center.dy + halfSize); // Bottom left
    path.lineTo(center.dx + halfSize, center.dy + halfSize); // Bottom right
    path.close();
    
    canvas.drawPath(path, paint);
  }

  void _drawHealthBar(Canvas canvas, Offset position, Enemy enemy) {
    const healthBarWidth = 40.0;
    const healthBarHeight = 4.0;
    const healthBarOffset = 8.0;

    final healthBarY = position.dy - enemy.size/2 - healthBarOffset;
    final healthPercentage = enemy.health / _getMaxHealth(enemy.type);

    // Background (grey)
    canvas.drawRect(
      Rect.fromLTWH(
        position.dx - healthBarWidth/2,
        healthBarY,
        healthBarWidth,
        healthBarHeight,
      ),
      Paint()..color = Colors.grey,
    );

    // Health (green to red based on percentage)
    canvas.drawRect(
      Rect.fromLTWH(
        position.dx - healthBarWidth/2,
        healthBarY,
        healthBarWidth * healthPercentage,
        healthBarHeight,
      ),
      Paint()..color = Color.lerp(
        Colors.red,
        Colors.green,
        healthPercentage,
      )!,
    );
  }

  double _getMaxHealth(EnemyType type) {
    switch (type) {
      case EnemyType.basic:
        return 100.0;
      case EnemyType.fast:
        return 50.0;
      case EnemyType.tank:
        return 200.0;
    }
  }

  @override
  bool shouldRepaint(EnemyPainter oldDelegate) {
    return true; // Always repaint since enemies are moving
  }
} 