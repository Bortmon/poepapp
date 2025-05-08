// lib/providers/app_state.dart
import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; // Importeer fl_chart
import '../models/session_data.dart';
import '../models/rank.dart';
import '../models/session_result.dart';
import '../models/achievement.dart';
import '../services/storage_service.dart';
import '../services/rank_service.dart';
import '../services/achievement_service.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver
{
  final StorageService _storageService = StorageService();
  final AchievementService _achievementService = AchievementService();
  List<Achievement> _allAchievements = [];
  List<AchievementId> _unlockedAchievementIds = [];
  final List<Achievement> _newlyUnlockedAchievementsBuffer = [];


  double _hourlyWage = 0.0;
  bool _isTracking = false;
  double _currentEarnings = 0.0;
  DateTime? _sessionStartTime;
  Timer? _timer;
  List<SessionData> _sessionsHistory = [];

  double get hourlyWage => _hourlyWage;
  bool get isTracking => _isTracking;
  double get currentEarnings => _currentEarnings;
  List<SessionData> get sessionsHistory => _sessionsHistory;
  List<Achievement> get allAchievements => _allAchievements;
  List<Achievement> get newlyUnlockedAchievementsToShow {
    final buffer = List<Achievement>.from(_newlyUnlockedAchievementsBuffer);
    _newlyUnlockedAchievementsBuffer.clear();
    return buffer;
  }


  AppState()
  {
    _initializeAchievements();
    _loadInitialData();
    WidgetsBinding.instance.addObserver(this);
  }

  void _initializeAchievements() {
    _allAchievements = _achievementService.getAllAchievements();
  }

  Future<void> _loadInitialData() async
  {
    _hourlyWage = await _storageService.getHourlyWage() ?? 0.0;
    _sessionsHistory = await _storageService.getSessions();
    List<String> storedIds = await _storageService.getUnlockedAchievementIds();
    _unlockedAchievementIds = storedIds.map((idStr) => AchievementId.values.firstWhere((e) => e.toString() == idStr)).toList();
    _updateAchievementsStatus();
    _checkForNewAchievements(isInitialLoad: true);
    notifyListeners();
  }

  void _updateAchievementsStatus() {
    for (var ach in _allAchievements) {
      if (_unlockedAchievementIds.contains(ach.id)) {
        ach.isUnlocked = true;
      }
    }
  }

  Future<void> _checkForNewAchievements({bool isInitialLoad = false}) async {
    List<AchievementId> newlyUnlockedIds = _achievementService.checkAchievements(this, _unlockedAchievementIds);
    if (newlyUnlockedIds.isNotEmpty) {
      for (var id in newlyUnlockedIds) {
        _unlockedAchievementIds.add(id);
        Achievement? unlockedAch = _allAchievements.firstWhere((ach) => ach.id == id, orElse: () => _achievementService.getAllAchievements().firstWhere((a) => a.id == id));
        unlockedAch.isUnlocked = true;
        unlockedAch.unlockedTimestamp = DateTime.now();
        if (!isInitialLoad) {
          _newlyUnlockedAchievementsBuffer.add(unlockedAch);
        }
      }
      await _storageService.saveUnlockedAchievementIds(_unlockedAchievementIds.map((id) => id.toString()).toList());
      notifyListeners();
    }
  }


  double get totalSessionEarnings
  {
    if (_sessionsHistory.isEmpty) return 0.0;
    return _sessionsHistory.fold(0.0, (sum, session) => sum + session.earnedAmount);
  }

  Rank get currentRank
  {
    return RankService.getRankForEarnings(totalSessionEarnings);
  }

  Rank? get nextRank
  {
    return RankService.getNextRank(currentRank);
  }

  double get earningsNeededForNextRank
  {
    final nr = nextRank;
    if (nr == null) return 0.0;
    double needed = nr.minEarnings - totalSessionEarnings;
    return needed < 0 ? 0.0 : needed;
  }

  double get progressToNextRank
  {
    final cr = currentRank;
    final nr = nextRank;
    if (nr == null) return 1.0;

    double earningsInCurrentRank = totalSessionEarnings - cr.minEarnings;
    double totalEarningsForRankSpan = nr.minEarnings - cr.minEarnings;

    if (totalEarningsForRankSpan <= 0) return 1.0;
    double progress = earningsInCurrentRank / totalEarningsForRankSpan;
    return progress.clamp(0.0, 1.0);
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state)
  {
    super.didChangeAppLifecycleState(state);
    _handleLifecycleState(state);
  }

  void _handleLifecycleState(AppLifecycleState state)
  {
    switch (state)
    {
      case AppLifecycleState.resumed:
        if (_isTracking && _sessionStartTime != null)
        {
          final durationInSeconds = DateTime.now().difference(_sessionStartTime!).inSeconds;
          _currentEarnings = (durationInSeconds / 3600.0) * _hourlyWage;
          if (_timer == null || !_timer!.isActive)
          {
             _startPeriodicTimerUpdates();
          }
          notifyListeners();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  Future<void> setHourlyWage(double wage) async
  {
    _hourlyWage = wage;
    await _storageService.saveHourlyWage(wage);
    notifyListeners();
  }

  void _startPeriodicTimerUpdates()
  {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer)
    {
      if (_sessionStartTime != null && _isTracking)
      {
        final now = DateTime.now();
        final durationInSeconds = now.difference(_sessionStartTime!).inSeconds;
        _currentEarnings = (durationInSeconds / 3600.0) * _hourlyWage;
        notifyListeners();
      }
      else
      {
        timer.cancel();
      }
    });
  }

  void startTracking()
  {
    if (_hourlyWage <= 0)
    {
      return;
    }
    _isTracking = true;
    _sessionStartTime = DateTime.now();
    _currentEarnings = 0.0;

    _startPeriodicTimerUpdates();
    notifyListeners();
  }

  Future<SessionResult?> stopTracking() async
  {
    _timer?.cancel();
    _isTracking = false;
    SessionData? completedSessionData;
    SessionResult? sessionResult;

    Rank rankBeforeSession = currentRank;

    if (_sessionStartTime != null)
    {
      final endTime = DateTime.now();
      final durationInSeconds = endTime.difference(_sessionStartTime!).inSeconds;
      final finalEarningsInSession = (durationInSeconds / 3600.0) * _hourlyWage;

      completedSessionData = SessionData(
        startTime: _sessionStartTime!,
        endTime: endTime,
        earnedAmount: finalEarningsInSession,
      );
      _sessionsHistory.add(completedSessionData);
      await _storageService.saveSessions(_sessionsHistory);
      _currentEarnings = finalEarningsInSession;

      Rank rankAfterSession = currentRank;
      bool didRankUp = rankAfterSession != rankBeforeSession && rankAfterSession.minEarnings > rankBeforeSession.minEarnings;

      sessionResult = SessionResult(
        sessionData: completedSessionData,
        didRankUp: didRankUp,
        oldRank: rankBeforeSession,
        newRank: rankAfterSession,
        earningsInSession: finalEarningsInSession,
      );
      await _checkForNewAchievements();
    }
    _sessionStartTime = null;
    notifyListeners();
    return sessionResult;
  }

  double get weeklyEarnings
  {
    DateTime now = DateTime.now();
    DateTime startOfWeek = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    return _sessionsHistory
        .where((session) => session.startTime.isAfter(startOfWeek) || session.startTime.isAtSameMomentAs(startOfWeek))
        .fold(0.0, (sum, session) => sum + session.earnedAmount);
  }

  Future<void> resetAllData() async
  {
    if (_isTracking)
    {
      _timer?.cancel();
      _isTracking = false;
      _sessionStartTime = null;
    }
    await _storageService.clearAllData();
    _hourlyWage = 0.0;
    _sessionsHistory = [];
    _currentEarnings = 0.0;
    _unlockedAchievementIds = [];
    _initializeAchievements();
    _newlyUnlockedAchievementsBuffer.clear();
    notifyListeners();
  }

  @override
  void dispose()
  {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  Duration get averageSessionDuration {
    if (_sessionsHistory.isEmpty) return Duration.zero;
    int totalSeconds = _sessionsHistory.fold(0, (sum, s) => sum + s.duration.inSeconds);
    return Duration(seconds: (totalSeconds / _sessionsHistory.length).round());
  }

  double get averageEarningsPerSession {
    if (_sessionsHistory.isEmpty) return 0.0;
    return totalSessionEarnings / _sessionsHistory.length;
  }

  SessionData? get longestSession {
    if (_sessionsHistory.isEmpty) return null;
    return _sessionsHistory.reduce((curr, next) => curr.duration > next.duration ? curr : next);
  }

  SessionData? get shortestProductiveSession {
    if (_sessionsHistory.isEmpty) return null;
    List<SessionData> productiveSessions = _sessionsHistory.where((s) => s.earnedAmount > 0).toList();
    if (productiveSessions.isEmpty) return null;
    return productiveSessions.reduce((curr, next) => curr.duration < next.duration ? curr : next);
  }

  String get mostProductiveDayOfWeek {
    if (_sessionsHistory.isEmpty) return "N.v.t.";
    var groupedByDay = groupBy(_sessionsHistory, (SessionData s) => s.startTime.weekday);
    var summedByDay = groupedByDay.map((day, sessions) => MapEntry(day, sessions.fold(0.0, (sum, s) => sum + s.earnedAmount)));
    if (summedByDay.isEmpty) return "N.v.t.";
    var mostProductive = summedByDay.entries.reduce((curr, next) => curr.value > next.value ? curr : next);
    List<String> days = ["Ma", "Di", "Wo", "Do", "Vr", "Za", "Zo"];
    return days[mostProductive.key - 1];
  }

  String get mostProductiveHourOfDay {
    if (_sessionsHistory.isEmpty) return "N.v.t.";
    var groupedByHour = groupBy(_sessionsHistory, (SessionData s) => s.startTime.hour);
    var summedByHour = groupedByHour.map((hour, sessions) => MapEntry(hour, sessions.fold(0.0, (sum, s) => sum + s.earnedAmount)));
    if (summedByHour.isEmpty) return "N.v.t.";
    var mostProductive = summedByHour.entries.reduce((curr, next) => curr.value > next.value ? curr : next);
    return "${mostProductive.key.toString().padLeft(2, '0')}:00 - ${ (mostProductive.key + 1).toString().padLeft(2, '0')}:00";
  }

  List<FlSpot> get earningsOverTimeSpots {
    if (_sessionsHistory.isEmpty) return [];
    List<FlSpot> spots = [];
    double cumulativeEarnings = 0;
    for (int i = 0; i < _sessionsHistory.length; i++) {
      cumulativeEarnings += _sessionsHistory[i].earnedAmount;
      spots.add(FlSpot(i.toDouble(), cumulativeEarnings));
    }
    return spots;
  }

  Map<String, double> get earningsPerDay {
    if (_sessionsHistory.isEmpty) return {};
    Map<String, double> dailyTotals = {};
    var sortedSessions = List<SessionData>.from(_sessionsHistory)..sort((a,b) => a.startTime.compareTo(b.startTime));

    for (var session in sortedSessions) {
      String dayKey = DateFormat('dd-MM').format(session.startTime);
      dailyTotals.update(dayKey, (value) => value + session.earnedAmount, ifAbsent: () => session.earnedAmount);
    }
    return dailyTotals;
  }

  List<PieChartSectionData> get durationPieChartSections {
    if (_sessionsHistory.isEmpty) return [];

    int cat1 = 0; // < 1 min
    int cat2 = 0; // 1-3 min
    int cat3 = 0; // > 3 min

    for (var session in _sessionsHistory) {
      if (session.duration.inMinutes < 1) {
        cat1++;
      } else if (session.duration.inMinutes <= 3) {
        cat2++;
      } else {
        cat3++;
      }
    }
    double total = (cat1 + cat2 + cat3).toDouble();
    if (total == 0) return [];

    return [
      PieChartSectionData(
        color: Colors.lightBlueAccent,
        value: cat1.toDouble(),
        title: '${(cat1 / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 2)])
      ),
      PieChartSectionData(
        color: Colors.orangeAccent,
        value: cat2.toDouble(),
        title: '${(cat2 / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 2)])
      ),
      PieChartSectionData(
        color: Colors.pinkAccent,
        value: cat3.toDouble(),
        title: '${(cat3 / total * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(color: Colors.black, blurRadius: 2)])
      ),
    ];
  }
}