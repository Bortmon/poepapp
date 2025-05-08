// lib/services/achievement_service.dart
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../providers/app_state.dart';
import '../services/rank_service.dart';

class AchievementService {
  List<Achievement> getAllAchievements() {
    return [
      Achievement(
        id: AchievementId.firstEuro,
        name: 'Eerste Euro',
        description: 'Verdien je eerste euro op de troon!',
        icon: Icons.euro_symbol,
      ),
      Achievement(
        id: AchievementId.tenSessions,
        name: 'Tien Tellers',
        description: 'Voltooi 10 succesvolle WC-sessies.',
        icon: Icons.format_list_numbered, 
      ),
      Achievement(
        id: AchievementId.nightOwl,
        name: 'Nachtelijke Denker',
        description: 'Voltooi een sessie tussen middernacht en 6 uur \'s ochtends.',
        icon: Icons.nightlight_round,
      ),
      Achievement(
        id: AchievementId.quickStop,
        name: 'Vluggertje',
        description: 'Voltooi een productieve sessie in minder dan 30 seconden.',
        icon: Icons.flash_on,
      ),
      Achievement(
        id: AchievementId.longHaul,
        name: 'Zitvlees Kampioen',
        description: 'Voltooi een sessie die langer dan 5 minuten duurt.',
        icon: Icons.chair_alt,
      ),
      Achievement(
        id: AchievementId.rankGroentje,
        name: RankService.ranks[0].name,
        description: 'Bereik de rang van ${RankService.ranks[0].name}.',
        icon: Icons.eco,
        iconColor: RankService.ranks[0].color,
      ),
      Achievement(
        id: AchievementId.rankPiraat,
        name: RankService.ranks[1].name,
        description: 'Bereik de rang van ${RankService.ranks[1].name}.',
        icon: Icons.anchor,
        iconColor: RankService.ranks[1].color,
      ),
      Achievement(
        id: AchievementId.rankKleineBoodschapper,
        name: RankService.ranks[2].name,
        description: 'Bereik de rang van ${RankService.ranks[2].name}.',
        icon: Icons.mail_outline,
        iconColor: RankService.ranks[2].color,
      ),
      Achievement(
        id: AchievementId.rankGroteBoodschapper,
        name: RankService.ranks[3].name,
        description: 'Bereik de rang van ${RankService.ranks[3].name}.',
        icon: Icons.markunread_mailbox,
        iconColor: RankService.ranks[3].color,
      ),
      Achievement(
        id: AchievementId.rankTroonMeester,
        name: RankService.ranks[4].name,
        description: 'Bereik de rang van ${RankService.ranks[4].name}.',
        icon: Icons.castle,
        iconColor: RankService.ranks[4].color,
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
        case AchievementId.firstEuro:
          conditionMet = appState.totalSessionEarnings >= 1.0;
          break;
        case AchievementId.tenSessions:
          conditionMet = appState.sessionsHistory.length >= 10;
          break;
        case AchievementId.nightOwl:
          conditionMet = appState.sessionsHistory.any((s) => s.startTime.hour >= 0 && s.startTime.hour < 6);
          break;
        case AchievementId.quickStop:
          conditionMet = appState.sessionsHistory.any((s) => s.duration.inSeconds < 30 && s.earnedAmount > 0);
          break;
        case AchievementId.longHaul:
          conditionMet = appState.sessionsHistory.any((s) => s.duration.inMinutes >= 5);
          break;
        case AchievementId.rankGroentje:
          conditionMet = appState.totalSessionEarnings >= RankService.ranks[0].minEarnings;
          break;
        case AchievementId.rankPiraat:
          conditionMet = appState.totalSessionEarnings >= RankService.ranks[1].minEarnings;
          break;
        case AchievementId.rankKleineBoodschapper:
          conditionMet = appState.totalSessionEarnings >= RankService.ranks[2].minEarnings;
          break;
        case AchievementId.rankGroteBoodschapper:
          conditionMet = appState.totalSessionEarnings >= RankService.ranks[3].minEarnings;
          break;
        case AchievementId.rankTroonMeester:
          conditionMet = appState.totalSessionEarnings >= RankService.ranks[4].minEarnings;
          break;
      }

      if (conditionMet) {
        newlyUnlocked.add(achievement.id);
      }
    }
    return newlyUnlocked;
  }
}