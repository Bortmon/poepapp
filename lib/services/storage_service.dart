// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_data.dart';
import '../models/challenge.dart';

class StorageService
{
  static const String _hourlyWageKey = 'hourlyWage';
  static const String _sessionsKey = 'sessions';
  static const String _unlockedAchievementsKey = 'unlockedAchievements';
  static const String _currentDailyChallengeKey = 'currentDailyChallenge';
  static const String _completedDailyChallengeIdsKey = 'completedDailyChallengeIds';
  static const String _lastChallengeDateKey = 'lastChallengeDate';


  Future<void> saveHourlyWage(double wage) async
  {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_hourlyWageKey, wage);
  }

  Future<double?> getHourlyWage() async
  {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_hourlyWageKey);
  }

  Future<void> saveSessions(List<SessionData> sessions) async
  {
    final prefs = await SharedPreferences.getInstance();
    List<String> sessionsJson = sessions.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_sessionsKey, sessionsJson);
  }

  Future<List<SessionData>> getSessions() async
  {
    final prefs = await SharedPreferences.getInstance();
    List<String>? sessionsJson = prefs.getStringList(_sessionsKey);
    if (sessionsJson == null)
    {
      return [];
    }
    return sessionsJson.map((s) => SessionData.fromJson(jsonDecode(s))).toList();
  }

  Future<void> saveUnlockedAchievementIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_unlockedAchievementsKey, ids);
  }

  Future<List<String>> getUnlockedAchievementIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_unlockedAchievementsKey) ?? [];
  }

  Future<void> saveCurrentDailyChallenge(Challenge? challenge) async {
    final prefs = await SharedPreferences.getInstance();
    if (challenge == null) {
      await prefs.remove(_currentDailyChallengeKey);
    } else {
      await prefs.setString(_currentDailyChallengeKey, jsonEncode(challenge.toJson()));
    }
  }

  Future<Challenge?> getCurrentDailyChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    String? challengeJson = prefs.getString(_currentDailyChallengeKey);
    if (challengeJson == null) return null;
    try {
      return Challenge.fromJson(jsonDecode(challengeJson));
    } catch (e) {
      await prefs.remove(_currentDailyChallengeKey); 
      return null;
    }
  }

  Future<void> saveCompletedDailyChallengeIds(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedDailyChallengeIdsKey, ids);
  }

  Future<List<String>> getCompletedDailyChallengeIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_completedDailyChallengeIdsKey) ?? [];
  }

   Future<void> saveLastChallengeDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastChallengeDateKey, date.toIso8601String().substring(0, 10));
  }

  Future<String?> getLastChallengeDateString() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastChallengeDateKey);
  }


  Future<void> clearAllData() async
  {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hourlyWageKey);
    await prefs.remove(_sessionsKey);
    await prefs.remove(_unlockedAchievementsKey);
    await prefs.remove(_currentDailyChallengeKey);
    await prefs.remove(_completedDailyChallengeIdsKey);
    await prefs.remove(_lastChallengeDateKey);
  }
}