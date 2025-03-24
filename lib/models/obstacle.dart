import 'package:flutter/material.dart';
import 'obstacle_type.dart';

class Obstacle {
  final ObstacleType type;
  final Offset position;
  final Rect bounds;

  Obstacle({
    required this.type,
    required this.position,
  }) : bounds = Rect.fromCenter(
         center: position,
         width: type.size.width,
         height: type.size.height,
       );
} 