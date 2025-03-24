import 'dart:math';
import 'package:flutter/material.dart';
import '../models/obstacle.dart';
import '../models/obstacle_type.dart';

class LevelGenerator {
  final Random random;
  final Size worldSize;
  final int minObstacles;
  final int maxObstacles;
  final double minSpacing; // Minimum space between obstacles

  LevelGenerator({
    required this.worldSize,
    this.minObstacles = 10,
    this.maxObstacles = 20,
    this.minSpacing = 100,
    Random? random,
  }) : random = random ?? Random();

  // Select a random obstacle type using weights
  ObstacleType _selectRandomObstacleType() {
    double value = random.nextDouble() * ObstacleTypes.totalWeight;
    double sum = 0;
    
    for (final type in ObstacleTypes.all) {
      sum += type.weight;
      if (value <= sum) {
        return type;
      }
    }
    
    return ObstacleTypes.all.last;
  }

  List<Obstacle> generateObstacles({required Offset playerStart}) {
    List<Obstacle> obstacles = [];
    int numObstacles = minObstacles + random.nextInt(maxObstacles - minObstacles + 1);
    
    // Create a safe zone around the player start position
    final safeZone = Rect.fromCenter(
      center: playerStart,
      width: minSpacing * 2,
      height: minSpacing * 2,
    );

    for (int i = 0; i < numObstacles; i++) {
      bool validPosition = false;
      Obstacle? newObstacle;
      
      // Try to place obstacle up to 10 times
      int attempts = 0;
      do {
        // Select random obstacle type
        final obstacleType = _selectRandomObstacleType();
        
        // Generate random position
        double x = obstacleType.size.width/2 + 
                   random.nextDouble() * (worldSize.width - obstacleType.size.width);
        double y = obstacleType.size.height/2 + 
                   random.nextDouble() * (worldSize.height - obstacleType.size.height);
        
        // Create new obstacle
        newObstacle = Obstacle(
          type: obstacleType,
          position: Offset(x, y),
        );
        
        // Check if position is valid
        validPosition = !safeZone.overlaps(newObstacle.bounds) && 
                       !_overlapsAnyObstacle(newObstacle.bounds, obstacles);
        
        attempts++;
      } while (!validPosition && attempts < 10);
      
      if (validPosition && newObstacle != null) {
        obstacles.add(newObstacle);
      }
    }
    
    return obstacles;
  }

  bool _overlapsAnyObstacle(Rect newObstacle, List<Obstacle> obstacles) {
    for (final obstacle in obstacles) {
      if (_obstaclesOverlapWithSpacing(newObstacle, obstacle.bounds)) {
        return true;
      }
    }
    return false;
  }

  bool _obstaclesOverlapWithSpacing(Rect a, Rect b) {
    // Expand rect by minSpacing to ensure minimum distance between obstacles
    final expandedA = Rect.fromLTRB(
      a.left - minSpacing,
      a.top - minSpacing,
      a.right + minSpacing,
      a.bottom + minSpacing,
    );
    return expandedA.overlaps(b);
  }
} 