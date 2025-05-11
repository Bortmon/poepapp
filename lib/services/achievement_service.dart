// lib/services/achievement_service.dart
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../providers/app_state.dart';
import '../services/rank_service.dart';

class AchievementService {
  List<Achievement> getAllAchievements() {
    return [
      Achievement(
        id: AchievementId.firstFlush,
        name: 'Eerste Spoeling',
        description: 'Verdien je eerste euro op de troon!',
        icon: Icons.water_drop_outlined,
      ),
      Achievement(
        id: AchievementId.rollDone,
        name: 'Rol Volbracht',
        description: 'Voltooi 15 succesvolle WC-sessies.',
        icon: Icons.all_inclusive,
      ),
      Achievement(
        id: AchievementId.nightlyNeed,
        name: 'Nachtelijke Noodzaak',
        description: 'Voltooi een sessie tussen 00:00 en 06:00.',
        icon: Icons.nightlight_round,
      ),
      Achievement(
        id: AchievementId.lightningVisit,
        name: 'Bliksembezoek',
        description: 'Voltooi een productieve sessie in minder dan 40 seconden.',
        icon: Icons.flash_on,
      ),
      Achievement(
        id: AchievementId.theThinker,
        name: 'De Denker',
        description: 'Voltooi een sessie die langer dan 8 minuten duurt.',
        icon: Icons.self_improvement,
      ),
      Achievement(
        id: AchievementId.profitableWeek,
        name: 'Winstgevende Week',
        description: 'Verdien €15 in één week.',
        icon: Icons.calendar_view_week_outlined,
        iconColor: Colors.green,
      ),
      Achievement(
        id: AchievementId.goldenHaul,
        name: 'Gouden Greep',
        description: 'Verdien €75 totaal.',
        icon: Icons.emoji_events_outlined,
        iconColor: Colors.orangeAccent,
      ),
      Achievement(
        id: AchievementId.sanitarySenseiAchieved,
        name: 'Sanitair Sensei Status',
        description: 'Bereik de rang van Sanitair Sensei.',
        icon: RankService.ranks.firstWhere((r) => r.name == 'Sanitair Sensei').emoji == '🧘‍♂️' ? Icons.spa_outlined : Icons.star_border_purple500_outlined, // Conditioneel icoon
        iconColor: RankService.ranks.firstWhere((r) => r.name == 'Sanitair Sensei').color,
      ),
      Achievement(
        id: AchievementId.weekendWarriorWC,
        name: 'Weekend Warrior (WC Editie)',
        description: 'Voltooi 7 sessies in één weekend (Za & Zo).',
        icon: Icons.weekend_outlined,
      ),
      Achievement(
        id: AchievementId.morningRitualExpert,
        name: 'Ochtendritueel Expert',
        description: 'Voltooi 3 sessies vóór 09:00 op verschillende dagen.',
        icon: Icons.wb_sunny_outlined,
      ),
      Achievement(
        id: AchievementId.jackpotSession,
        name: 'Jackpot!',
        description: 'Verdien meer dan €1.00 in één enkele sessie.',
        icon: Icons.celebration_outlined,
        iconColor: Colors.redAccent,
      ),
      Achievement(
        id: AchievementId.theCollector,
        name: 'De Collectioneur',
        description: 'Ontgrendel 10 verschillende prestaties.',
        icon: Icons.collections_bookmark_outlined,
      ),
      Achievement(
        id: AchievementId.theRegular,
        name: 'De Regelmatige',
        description: 'Voltooi minstens één sessie per dag, 5 dagen op rij. (Binnenkort!)',
        icon: Icons.event_repeat_outlined,
        iconColor: Colors.grey,
      ),
      Achievement(
        id: AchievementId.theEfficient,
        name: 'De Efficiënte',
        description: 'Gemiddelde sessieduur onder 2 minuten na 10 sessies. (Binnenkort!)',
        icon: Icons.speed_outlined,
        iconColor: Colors.grey,
      ),
    ];
  }

  List<AchievementId> checkAchievements(AppState appState, List<AchievementId> currentlyUnlockedIds) {
    List<AchievementId> newlyUnlocked = [];
    List<Achievement> allAchievements = getAllAchievements();

    for (var achievement in allAchievements) {
      if (currentlyUnlockedIds.contains(achievement.id)) {
        continue;
      }

      bool conditionMet = false;
      switch (achievement.id) {
        case AchievementId.firstFlush:
          conditionMet = appState.totalSessionEarnings >= 1.0;
          break;
        case AchievementId.rollDone:
          conditionMet = appState.sessionsHistory.length >= 15;
          break;
        case AchievementId.nightlyNeed:
          conditionMet = appState.sessionsHistory.any((s) => s.startTime.hour >= 0 && s.startTime.hour < 6);
          break;
        case AchievementId.lightningVisit:
          conditionMet = appState.sessionsHistory.any((s) => s.duration.inSeconds < 40 && s.earnedAmount > 0);
          break;
        case AchievementId.theThinker:
          conditionMet = appState.sessionsHistory.any((s) => s.duration.inMinutes >= 8);
          break;
        case AchievementId.profitableWeek:
          conditionMet = appState.weeklyEarnings >= 15.0;
          break;
        case AchievementId.goldenHaul:
          conditionMet = appState.totalSessionEarnings >= 75.0;
          break;
        case AchievementId.sanitarySenseiAchieved:
          conditionMet = appState.currentRank.name == 'Sanitair Sensei' || appState.currentRank.minEarnings >= RankService.ranks.firstWhere((r) => r.name == 'Sanitair Sensei').minEarnings;
          break;
        case AchievementId.weekendWarriorWC:
          int weekendSessions = appState.sessionsHistory.where((s) => s.startTime.weekday == DateTime.saturday || s.startTime.weekday == DateTime.sunday).length;
          conditionMet = weekendSessions >= 7;
          break;
        case AchievementId.morningRitualExpert:
          var morningSessionsByDay = appState.sessionsHistory
              .where((s) => s.startTime.hour < 9)
              .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
              .toSet();
          conditionMet = morningSessionsByDay.length >= 3;
          break;
        case AchievementId.jackpotSession:
          conditionMet = appState.sessionsHistory.any((s) => s.earnedAmount >= 1.0);
          break;
        case AchievementId.theCollector:
          conditionMet = currentlyUnlockedIds.length + newlyUnlocked.length >= 9; // 9 + deze = 10
          break;
        case AchievementId.theRegular:
        case AchievementId.theEfficient:
          conditionMet = false; // Nog niet geïmplementeerd
          break;
      }

      if (conditionMet) {
        newlyUnlocked.add(achievement.id);
      }
    }
    return newlyUnlocked;
  }
}