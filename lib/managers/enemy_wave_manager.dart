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
      }
    }
    
    // Start new wave if current one is complete
    if (enemiesRemainingInWave == 0 && enemies.isEmpty) {
      startNextWave();
    }
  }
  
  void startNextWave() {
    currentWave++;
    enemiesRemainingInWave = _calculateEnemiesForWave(currentWave);
    spawnTimer = spawnInterval; // Spawn first enemy immediately
  }
  
  int _calculateEnemiesForWave(int wave) {
    return wave * 3; // Increase enemies by 3 each wave
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
    
    enemies.add(Enemy(
      type: type,
      position: spawnPosition,
    ));
  }
  
  Offset _getRandomSpawnPosition() {
    // Randomly choose which edge to spawn from
    final edge = _random.nextInt(4);
    
    switch (edge) {
      case 0: // Top
        return Offset(
          _random.nextDouble() * worldWidth,
          0,
        );
      case 1: // Right
        return Offset(
          worldWidth,
          _random.nextDouble() * worldHeight,
        );
      case 2: // Bottom
        return Offset(
          _random.nextDouble() * worldWidth,
          worldHeight,
        );
      default: // Left
        return Offset(
          0,
          _random.nextDouble() * worldHeight,
        );
    }
  }
} 