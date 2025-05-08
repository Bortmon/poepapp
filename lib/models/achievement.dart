// lib/models/achievement.dart
import 'package:flutter/material.dart';

enum AchievementId {
  firstEuro,
  tenSessions,
  nightOwl,
  quickStop,
  longHaul,
  rankGroentje,
  rankPiraat,
  rankKleineBoodschapper,
  rankGroteBoodschapper,
  rankTroonMeester
}

class Achievement {
  final AchievementId id;
  final String name;
  final String description;
  final IconData icon;
  final Color iconColor;
  bool isUnlocked;
  DateTime? unlockedTimestamp;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.iconColor = Colors.amber,
    this.isUnlocked = false,
    this.unlockedTimestamp,
  });
}