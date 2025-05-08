// lib/providers/app_state.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/session_data.dart';
import '../models/rank.dart';
import '../models/session_result.dart';
import '../services/storage_service.dart';
import '../services/rank_service.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver
{
  final StorageService _storageService = StorageService();

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

  AppState()
  {
    _loadInitialData();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _loadInitialData() async
  {
    _hourlyWage = await _storageService.getHourlyWage() ?? 0.0;
    _sessionsHistory = await _storageService.getSessions();
    notifyListeners();
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
    notifyListeners();
  }

  @override
  void dispose()
  {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}