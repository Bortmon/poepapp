// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_data.dart';

class StorageService
{
  static const String _hourlyWageKey = 'hourlyWage';
  static const String _sessionsKey = 'sessions';
  static const String _unlockedAchievementsKey = 'unlockedAchievements';

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

  Future<void> clearAllData() async
  {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hourlyWageKey);
    await prefs.remove(_sessionsKey);
    await prefs.remove(_unlockedAchievementsKey);
  }
}