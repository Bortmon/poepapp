// lib/services/challenge_service.dart
import 'dart:math';
import '../models/challenge.dart';

class ChallengeService {
  final Random _random = Random();

  List<Challenge> getChallengeTemplates(DateTime forDate) {
    return [
      Challenge(id: "earn_0_20_today", title: "Kleine Storting", description: "Verdien vandaag minstens €0,20.", type: ChallengeType.earnAmountToday, targetValue: 0.20, unit: "€", dateAssigned: forDate),
      Challenge(id: "earn_0_50_today", title: "Flinke Boodschap", description: "Verdien vandaag minstens €0,50.", type: ChallengeType.earnAmountToday, targetValue: 0.50, unit: "€", dateAssigned: forDate),
      Challenge(id: "complete_2_sessions_today", title: "Dubbele Spoeling", description: "Voltooi vandaag 2 sessies.", type: ChallengeType.completeSessionsToday, targetValue: 2, unit: "sessies", dateAssigned: forDate),
      Challenge(id: "complete_3_sessions_today", title: "Hattrick!", description: "Voltooi vandaag 3 sessies.", type: ChallengeType.completeSessionsToday, targetValue: 3, unit: "sessies", dateAssigned: forDate),
      Challenge(id: "session_60_sec", title: "Minuutje Stilte", description: "Voltooi een sessie van precies 60 seconden.", type: ChallengeType.specificDurationSession, targetValue: 60, unit: "sec", dateAssigned: forDate),
      Challenge(id: "earn_0_10_in_one_session", title: "Tien Cent Topper", description: "Verdien minstens €0,10 in één sessie vandaag.", type: ChallengeType.earnInOneSession, targetValue: 0.10, unit: "€", dateAssigned: forDate),
    ];
  }

  Challenge? selectDailyChallenge(DateTime currentDate, List<String> completedChallengeIdsToday) {
    List<Challenge> availableChallenges = getChallengeTemplates(currentDate)
        .where((challenge) => !completedChallengeIdsToday.contains(challenge.id))
        .toList();

    if (availableChallenges.isEmpty) {
      return null;
    }
    return availableChallenges[_random.nextInt(availableChallenges.length)];
  }
}