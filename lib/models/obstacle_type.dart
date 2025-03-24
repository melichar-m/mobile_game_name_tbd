import 'package:flutter/material.dart';

class ObstacleType {
  final String id;
  final String assetPath;
  final Size size;
  final double weight; // Probability weight for spawning

  const ObstacleType({
    required this.id,
    required this.assetPath,
    required this.size,
    this.weight = 1.0,
  });
}

// Define all available obstacle types
class ObstacleTypes {
  static const tree = ObstacleType(
    id: 'tree',
    assetPath: 'assets/images/obstacles/tree.png',
    size: Size(100, 100),
    weight: 2.0,
  );

  static const rock = ObstacleType(
    id: 'rock',
    assetPath: 'assets/images/obstacles/rock.png',
    size: Size(80, 80),
    weight: 1.5,
  );

  static const bush = ObstacleType(
    id: 'bush',
    assetPath: 'assets/images/obstacles/bush.png',
    size: Size(60, 60),
    weight: 1.0,
  );

  // List of all available obstacles
  static const List<ObstacleType> all = [
    tree,
    rock,
    bush,
  ];

  // Total weight of all obstacles (used for weighted random selection)
  static final double totalWeight = all.fold(0.0, (sum, type) => sum + type.weight);
} 