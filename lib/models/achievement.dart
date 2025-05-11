// lib/models/achievement.dart
import 'package:flutter/material.dart';

enum AchievementId {
  firstFlush,
  rollDone,
  nightlyNeed,
  lightningVisit,
  theThinker,
  profitableWeek,
  goldenHaul,
  sanitarySenseiAchieved,
  weekendWarriorWC,
  morningRitualExpert,
  jackpotSession,
  theRegular,
  theEfficient,
  theCollector
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