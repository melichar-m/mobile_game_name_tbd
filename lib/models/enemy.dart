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
       health = _getHealthForType(type);

  static double _getSpeedForType(EnemyType type) {
    switch (type) {
      case EnemyType.basic:
        return 3.0;
      case EnemyType.fast:
        return 5.0;
      case EnemyType.tank:
        return 1.5;
    }
  }

  static double _getSizeForType(EnemyType type) {
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
      // Normalize and apply speed with deltaTime
      position = Offset(
        position.dx + (dx / distance) * speed * deltaTime,
        position.dy + (dy / distance) * speed * deltaTime,
      );
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