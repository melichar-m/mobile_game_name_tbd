import 'dart:math';
import 'package:flutter/material.dart';
import '../models/enemy.dart';

class EnemyWaveManager {
  final Random _random = Random();
  final Size screenSize;
  final double worldWidth;
  final double worldHeight;
  final List<Obstacle> obstacles;  // Add obstacles list
  
  List<Enemy> enemies = [];
  int currentWave = 0;
  int enemiesRemainingInWave = 0;
  double spawnTimer = 0;
  static const double spawnInterval = 1.0; // Seconds between enemy spawns
  
  EnemyWaveManager({
    required this.screenSize,
    required this.worldWidth,
    required this.worldHeight,
    required this.obstacles,  // Add obstacles parameter
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

  // Helper method to get adjusted movement vector when colliding
  Offset getAdjustedMovement(Offset currentPos, Offset movement, double size) {
    // Try the full movement first
    Offset newPos = currentPos + movement;
    if (!checkCollision(newPos, size)) {
      return movement;
    }

    // If collision occurs, try horizontal movement only
    Offset horizontalMove = Offset(movement.dx, 0);
    if (!checkCollision(currentPos + horizontalMove, size)) {
      return horizontalMove;
    }

    // If horizontal collision occurs, try vertical movement only
    Offset verticalMove = Offset(0, movement.dy);
    if (!checkCollision(currentPos + verticalMove, size)) {
      return verticalMove;
    }

    // If both directions cause collision, return zero movement
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
        final actualMovement = getAdjustedMovement(
          enemy.position,
          intendedMovement,
          enemy.size,
        );
        
        // Update enemy position
        enemy.position += actualMovement;

        // Debug movement occasionally (every ~1 second)
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
    do {
      spawnPosition = _getRandomSpawnPosition();
    } while (checkCollision(spawnPosition, size));
    
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