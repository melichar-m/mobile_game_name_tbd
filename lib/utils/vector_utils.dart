import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Normalizes an Offset to have a length of 1
Offset normalizeOffset(Offset offset) {
  double length = math.sqrt(offset.dx * offset.dx + offset.dy * offset.dy);
  if (length == 0) return const Offset(0, 0);
  return Offset(offset.dx / length, offset.dy / length);
} 