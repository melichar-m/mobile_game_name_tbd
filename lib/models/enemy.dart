import 'package:flutter/material.dart';
import 'dart:math' as math;

enum EnemyType {
  basic,    // Basic red triangle enemy
  fast,     // Small, fast-moving enemy
  tank,     // Large, slow-moving enemy
}

class Enemy {
  final EnemyType type;
  Offset position;
  double speed;
  double size;
  Color color;
  double health;
  bool isAlive;

  Enemy({
    required this.type,
    required this.position,
    this.isAlive = true,
  }) : speed = _getSpeedForType(type),
       size = _getSizeForType(type),
       color = _getColorForType(type),
       health = _getHealthForType(type) {
    print('Created ${type.name} enemy with speed: $speed');
  }

  static double _getSpeedForType(EnemyType type) {
    switch (type) {
      case EnemyType.basic:
        return 100.0;  // Increased from 3.0
      case EnemyType.fast:
        return 150.0;  // Increased from 5.0
      case EnemyType.tank:
        return 50.0;   // Increased from 1.5
    }
  }

  static double getSizeForType(EnemyType type) {
    switch (type) {
      case EnemyType.basic:
        return 30.0;
      case EnemyType.fast:
        return 20.0;
      case EnemyType.tank:
        return 50.0;
    }
  }

  static Color _getColorForType(EnemyType type) {
    switch (type) {
      case EnemyType.basic:
        return Colors.red;
      case EnemyType.fast:
        return Colors.yellow;
      case EnemyType.tank:
        return Colors.purple;
    }
  }

  static double _getHealthForType(EnemyType type) {
    switch (type) {
      case EnemyType.basic:
        return 100.0;
      case EnemyType.fast:
        return 50.0;
      case EnemyType.tank:
        return 200.0;
    }
  }

  void moveTowardsPlayer(Offset playerPosition, double deltaTime) {
    // Calculate direction to player
    final dx = playerPosition.dx - position.dx;
    final dy = playerPosition.dy - position.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    
    if (distance > 0) {
      // Calculate movement
      final moveX = (dx / distance) * speed * deltaTime;
      final moveY = (dy / distance) * speed * deltaTime;
      
      // Update position
      position = Offset(
        position.dx + moveX,
        position.dy + moveY,
      );

      // Debug movement occasionally (every ~1 second)
      if (DateTime.now().millisecondsSinceEpoch % 1000 < 16) {
        print('${type.name} enemy moving: dx=$moveX, dy=$moveY, distance=$distance');
      }
    }
  }

  void takeDamage(double amount) {
    health -= amount;
    if (health <= 0) {
      isAlive = false;
    }
  }

  Rect get bounds => Rect.fromCircle(
    center: position,
    radius: size / 2,
  );
} 