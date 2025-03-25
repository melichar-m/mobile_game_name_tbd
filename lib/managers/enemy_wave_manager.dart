import 'dart:math';  // For Random class
import 'dart:math' as math;  // For math functions
import 'package:flutter/material.dart';
import '../models/enemy.dart';
import '../models/obstacle.dart';

class EnemyWaveManager {
  final Random _random = Random();
  final Size screenSize;
  final double worldWidth;
  final double worldHeight;
  final List<Obstacle> obstacles;
  
  List<Enemy> enemies = [];
  int currentWave = 0;
  int enemiesRemainingInWave = 0;
  double spawnTimer = 0;
  static const double spawnInterval = 1.0; // Seconds between enemy spawns
  static const double maxEnemyOverlap = 0.1; // 10% overlap allowed
  
  EnemyWaveManager({
    required this.screenSize,
    required this.worldWidth,
    required this.worldHeight,
    required this.obstacles,
  });

  // Helper method to check if a position collides with any obstacle
  bool checkCollision(Offset position, double size) {
    final enemyRect = Rect.fromCircle(
      center: position,
      radius: size / 2,
    );

    for (final obstacle in obstacles) {
      if (enemyRect.overlaps(obstacle.bounds)) {
        return true;
      }
    }
    return false;
  }

  // Helper method to check if an enemy would overlap too much with other enemies
  bool checkEnemyOverlap(Offset position, double size, Enemy excludeEnemy) {
    final testRadius = size / 2;
    
    for (final other in enemies) {
      if (other == excludeEnemy) continue;
      
      // Calculate distance between centers
      final dx = position.dx - other.position.dx;
      final dy = position.dy - other.position.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      
      // Calculate minimum allowed distance (90% of combined radii)
      final minDistance = (testRadius + other.size / 2) * (1.0 - maxEnemyOverlap);
      
      if (distance < minDistance) {
        return true; // Too much overlap
      }
    }
    return false;
  }

  // Helper method to get adjusted movement vector when colliding
  Offset getAdjustedMovement(Enemy enemy, Offset movement) {
    final newPos = enemy.position + movement;
    
    // Check obstacle collisions
    if (!checkCollision(newPos, enemy.size)) {
      // Check enemy overlaps
      if (!checkEnemyOverlap(newPos, enemy.size, enemy)) {
        return movement;
      }
    }

    // Try 8 different directions if direct movement isn't possible
    final directions = [
      movement,                                    // Original direction
      Offset(movement.dx, 0),                     // Horizontal only
      Offset(0, movement.dy),                     // Vertical only
      Offset(movement.dx * 0.7, movement.dy * 0.7), // Diagonal at 70%
      Offset(-movement.dy, movement.dx),          // 90 degrees right
      Offset(movement.dy, -movement.dx),          // 90 degrees left
      Offset(-movement.dx * 0.7, movement.dy * 0.7), // 45 degrees right
      Offset(movement.dx * 0.7, -movement.dy * 0.7), // 45 degrees left
    ];

    // Try each direction
    for (final dir in directions) {
      final testPos = enemy.position + dir;
      if (!checkCollision(testPos, enemy.size) && 
          !checkEnemyOverlap(testPos, enemy.size, enemy)) {
        return dir;
      }
    }

    // If no direction works, stay in place
    return Offset.zero;
  }

  void update(double deltaTime, Offset playerPosition) {
    // Update existing enemies
    for (final enemy in enemies) {
      if (!enemy.isAlive) continue;
      
      // Calculate direction to player
      final dx = playerPosition.dx - enemy.position.dx;
      final dy = playerPosition.dy - enemy.position.dy;
      final distance = math.sqrt(dx * dx + dy * dy);
      
      if (distance > 0) {
        // Calculate intended movement
        final moveX = (dx / distance) * enemy.speed * deltaTime;
        final moveY = (dy / distance) * enemy.speed * deltaTime;
        final intendedMovement = Offset(moveX, moveY);
        
        // Get adjusted movement that accounts for collisions
        final actualMovement = getAdjustedMovement(enemy, intendedMovement);
        
        // Update enemy position
        enemy.position += actualMovement;

        // Debug movement occasionally
        if (DateTime.now().millisecondsSinceEpoch % 1000 < 16) {
          print('${enemy.type.name} enemy moving: intended=$intendedMovement, actual=$actualMovement');
        }
      }
    }
    
    // Remove dead enemies
    enemies.removeWhere((enemy) => !enemy.isAlive);
    
    // Spawn new enemies if needed
    if (enemiesRemainingInWave > 0) {
      spawnTimer += deltaTime;
      if (spawnTimer >= spawnInterval) {
        spawnTimer = 0;
        _spawnEnemy();
        enemiesRemainingInWave--;
        print('Spawned enemy. Remaining: $enemiesRemainingInWave');
      }
    }
  }
  
  void startNextWave() {
    currentWave++;
    print('Starting wave $currentWave');
    enemiesRemainingInWave = _calculateEnemiesForWave(currentWave);
    spawnTimer = spawnInterval; // Spawn first enemy immediately
  }
  
  int _calculateEnemiesForWave(int wave) {
    // Start with 3 enemies on wave 1, add 2 more each wave
    return 3 + ((wave - 1) * 2);
  }
  
  void _spawnEnemy() {
    // Determine enemy type based on wave number and randomness
    EnemyType type;
    final roll = _random.nextDouble();
    
    if (currentWave >= 5 && roll < 0.2) {
      type = EnemyType.tank;
    } else if (currentWave >= 3 && roll < 0.4) {
      type = EnemyType.fast;
    } else {
      type = EnemyType.basic;
    }
    
    // Keep trying to spawn until we find a valid position
    Offset spawnPosition;
    double size = Enemy.getSizeForType(type);
    int attempts = 0;
    const maxAttempts = 100;
    
    do {
      spawnPosition = _getRandomSpawnPosition();
      attempts++;
      if (attempts >= maxAttempts) {
        print('Failed to find valid spawn position after $maxAttempts attempts');
        return;
      }
    } while (checkCollision(spawnPosition, size) || 
             checkEnemyOverlap(spawnPosition, size, null));
    
    final enemy = Enemy(
      type: type,
      position: spawnPosition,
    );
    
    print('Spawned ${enemy.type.name} enemy at ${enemy.position}');
    enemies.add(enemy);
  }
  
  Offset _getRandomSpawnPosition() {
    // Randomly choose which edge to spawn from
    final edge = _random.nextInt(4);
    double x, y;
    
    switch (edge) {
      case 0: // Top
        x = _random.nextDouble() * worldWidth;
        y = 0;
        break;
      case 1: // Right
        x = worldWidth;
        y = _random.nextDouble() * worldHeight;
        break;
      case 2: // Bottom
        x = _random.nextDouble() * worldWidth;
        y = worldHeight;
        break;
      default: // Left
        x = 0;
        y = _random.nextDouble() * worldHeight;
        break;
    }
    
    return Offset(x, y);
  }
} 