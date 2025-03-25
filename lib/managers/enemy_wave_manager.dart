import 'dart:math';
import 'package:flutter/material.dart';
import '../models/enemy.dart';

class EnemyWaveManager {
  final Random _random = Random();
  final Size screenSize;
  final double worldWidth;
  final double worldHeight;
  
  List<Enemy> enemies = [];
  int currentWave = 0;
  int enemiesRemainingInWave = 0;
  double spawnTimer = 0;
  static const double spawnInterval = 1.0; // Seconds between enemy spawns
  
  EnemyWaveManager({
    required this.screenSize,
    required this.worldWidth,
    required this.worldHeight,
  });

  void update(double deltaTime, Offset playerPosition) {
    // Update existing enemies
    for (final enemy in enemies) {
      if (!enemy.isAlive) continue;
      enemy.moveTowardsPlayer(playerPosition, deltaTime);
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
    
    // Spawn position on the edge of the world
    final spawnPosition = _getRandomSpawnPosition();
    
    final enemy = Enemy(
      type: type,
      position: spawnPosition,
    );
    
    print('Spawned ${enemy.type} enemy at ${enemy.position}');
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