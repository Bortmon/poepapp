// lib/models/rank.dart
import 'package:flutter/material.dart';

class Rank
{
  final String name;
  final double minEarnings;
  final double? maxEarnings;
  final String emoji;
  final Color color;

  const Rank({
    required this.name,
    required this.minEarnings,
    this.maxEarnings,
    required this.emoji,
    required this.color,
  });


  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Rank &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          minEarnings == other.minEarnings;

  @override
  int get hashCode => name.hashCode ^ minEarnings.hashCode;
}