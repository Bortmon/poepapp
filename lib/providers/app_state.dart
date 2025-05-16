// lib/providers/app_state.dart
import 'dart:async';
import 'dart:math';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/session_data.dart';
import '../models/rank.dart';
import '../models/session_result.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';
import '../services/storage_service.dart';
import '../services/rank_service.dart';
import '../services/achievement_service.dart';
import '../services/challenge_service.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver
{
  final StorageService _storageService = StorageService();
  final AchievementService _achievementService = AchievementService();
  final ChallengeService _challengeService = ChallengeService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const int _currentDataVersion = 1;

  List<Achievement> _allAchievements = [];
  List<AchievementId> _unlockedAchievementIds = [];
  final List<Achievement> _newlyUnlockedAchievementsBuffer = [];
  final List<Challenge> _newlyCompletedChallengesBuffer = [];

  String? _currentUserId;
  String _userName = "Anonieme Held";
  String _userStatus = "";


  double _hourlyWage = 0.0;
  bool _isTracking = false;
  double _currentEarnings = 0.0;
  DateTime? _sessionStartTime;
  Timer? _timer;
  List<SessionData> _sessionsHistory = [];

  Challenge? _currentDailyChallenge;
  List<String> _completedDailyChallengeIdsForToday = [];
  double _currentChallengeProgress = 0.0;
  int _dailyChallengeStreak = 0;
  bool _anyChallengeEverCompleted = false;

  bool _isInitialized = false;
  Completer<void> _initCompleter = Completer<void>();


  final List<String> _toiletTrivia = [
    "De gemiddelde persoon brengt ongeveer 3 maanden van zijn leven door op het toilet.",
    "Koning George II van Groot-Brittannië stierf op het toilet in 1760.",
    "Het eerste patent voor toiletpapier werd verleend in 1891.",
    "Er zijn meer mobiele telefoons dan toiletten in India.",
    "De duurste wc-rol ter wereld is gemaakt van 24-karaats goud.",
    "In Zuid-Korea is er een themapark gewijd aan toiletten.",
    "Romeinen gebruikten een gedeelde spons op een stok als toiletpapier.",
    "De uitvinder van het moderne spoeltoilet was Sir John Harington in 1596.",
    "Gemiddeld gebruikt een persoon 57 velletjes toiletpapier per dag.",
    "Het Witte Huis heeft 35 badkamers.",
    "Angst voor openbare toiletten heet parcopresis.",
    "De eerste gescheiden toiletten voor mannen en vrouwen verschenen in Parijs in 1739."
  ];
  String _currentTrivia = "";


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
  List<Challenge> get newlyCompletedChallengesToShow {
    final buffer = List<Challenge>.from(_newlyCompletedChallengesBuffer);
    _newlyCompletedChallengesBuffer.clear();
    return buffer;
  }
  String get userName => _userName;
  String? get currentUserId => _currentUserId;
  String get currentToiletTrivia => _currentTrivia;
  String get userStatus => _userStatus;
  Challenge? get currentDailyChallenge => _currentDailyChallenge;
  double get currentChallengeProgress => _currentChallengeProgress;
  int get dailyChallengeStreak => _dailyChallengeStreak;
  bool get anyChallengeEverCompleted => _anyChallengeEverCompleted;
  bool get isInitialized => _isInitialized;
  Future<void> get initializationComplete => _initCompleter.future;


  AppState()
  {
    _initialize();
  }

  Future<void> _initialize() async {
    if (_initCompleter.isCompleted) {
      _initCompleter = Completer<void>();
    }
    
    await _checkAndMigrateData();
    _initializeAchievements();
    await _loadInitialData();
    await _initializeUser();
    await _loadOrAssignDailyChallenge();
    _selectRandomTrivia();
    WidgetsBinding.instance.addObserver(this);
    
    _isInitialized = true;
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
    notifyListeners();
  }


  Future<void> _checkAndMigrateData() async {
    final prefs = await SharedPreferences.getInstance();
    int storedVersion = prefs.getInt('dataVersion') ?? 0;

    if (storedVersion < _currentDataVersion) {
      debugPrint("Data migratie nodig: van v$storedVersion naar v$_currentDataVersion");

      if (storedVersion < 1) {
      }

      await prefs.setInt('dataVersion', _currentDataVersion);
      debugPrint("Data migratie voltooid. Nieuwe dataVersion: $_currentDataVersion");
    }
  }


  void _selectRandomTrivia() {
    if (_toiletTrivia.isNotEmpty) {
      final random = Random();
      _currentTrivia = _toiletTrivia[random.nextInt(_toiletTrivia.length)];
    }
  }

  void refreshTrivia() {
    _selectRandomTrivia();
    notifyListeners();
  }


  void _initializeAchievements() {
    _allAchievements = _achievementService.getAllAchievements();
  }

  Future<void> _loadInitialData() async
  {
    _hourlyWage = await _storageService.getHourlyWage() ?? 0.0;
    _sessionsHistory = await _storageService.getSessions();
    List<String> storedIds = await _storageService.getUnlockedAchievementIds();
    _unlockedAchievementIds = storedIds.map((idStr) => AchievementId.values.firstWhere((e) => e.toString() == idStr, orElse: () => AchievementId.firstFlush )).toList();
    _updateAchievementsStatus();

    final prefs = await SharedPreferences.getInstance();
    _dailyChallengeStreak = prefs.getInt('dailyChallengeStreak') ?? 0;
    _anyChallengeEverCompleted = prefs.getBool('anyChallengeEverCompleted') ?? false;

    _checkForNewAchievements(isInitialLoad: true);
  }

  Future<void> _initializeUser() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId = prefs.getString('appUserId');
    if (_currentUserId == null) {
      _currentUserId = const Uuid().v4();
      await prefs.setString('appUserId', _currentUserId!);
    }
    _userName = prefs.getString('userName') ?? "Anonieme Held";
    _userStatus = prefs.getString('userStatus') ?? "";
  }

  Future<void> _loadOrAssignDailyChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    final todayString = DateTime.now().toIso8601String().substring(0, 10);
    String? lastChallengeDateString = await _storageService.getLastChallengeDateString();
    String? lastCompletedChallengeDateString = prefs.getString('lastCompletedChallengeDate');


    if (lastChallengeDateString != todayString) {
      _completedDailyChallengeIdsForToday = [];
      await _storageService.saveCompletedDailyChallengeIds([]);
      _currentDailyChallenge = _challengeService.selectDailyChallenge(DateTime.now(), _completedDailyChallengeIdsForToday);
      await _storageService.saveCurrentDailyChallenge(_currentDailyChallenge);
      await _storageService.saveLastChallengeDate(DateTime.now());

      if (lastCompletedChallengeDateString != null) {
        DateTime lastCompletedDate = DateTime.parse(lastCompletedChallengeDateString);
        DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
        DateTime dayBeforeYesterday = DateTime.now().subtract(const Duration(days: 2));

        bool wasYesterday = lastCompletedDate.year == yesterday.year &&
                            lastCompletedDate.month == yesterday.month &&
                            lastCompletedDate.day == yesterday.day;

        bool wasDayBeforeYesterdayAndYesterdayChallengeWasSkipped =
            (lastCompletedDate.year == dayBeforeYesterday.year &&
             lastCompletedDate.month == dayBeforeYesterday.month &&
             lastCompletedDate.day == dayBeforeYesterday.day) &&
            (lastChallengeDateString == DateTime(yesterday.year, yesterday.month, yesterday.day).toIso8601String().substring(0,10));


        if (!wasYesterday && !wasDayBeforeYesterdayAndYesterdayChallengeWasSkipped) {
          _dailyChallengeStreak = 0;
          await prefs.setInt('dailyChallengeStreak', _dailyChallengeStreak);
        }
      } else {
         _dailyChallengeStreak = 0;
         await prefs.setInt('dailyChallengeStreak', _dailyChallengeStreak);
      }


    } else {
      _currentDailyChallenge = await _storageService.getCurrentDailyChallenge();
      _completedDailyChallengeIdsForToday = await _storageService.getCompletedDailyChallengeIds();
      if (_currentDailyChallenge == null && _challengeService.getChallengeTemplates(DateTime.now()).where((c) => !_completedDailyChallengeIdsForToday.contains(c.id)).isNotEmpty) {
        _currentDailyChallenge = _challengeService.selectDailyChallenge(DateTime.now(), _completedDailyChallengeIdsForToday);
        await _storageService.saveCurrentDailyChallenge(_currentDailyChallenge);
      }
    }
    _updateChallengeProgress();
  }

  void _updateChallengeProgress() {
    if (_currentDailyChallenge == null || _currentDailyChallenge!.isCompleted) {
      _currentChallengeProgress = _currentDailyChallenge?.isCompleted == true ? 1.0 : 0.0;
      return;
    }

    DateTime today = DateTime.now();
    DateTime todayStart = DateTime(today.year, today.month, today.day);
    List<SessionData> todaySessions = _sessionsHistory.where((s) => s.startTime.isAfter(todayStart) || s.startTime.isAtSameMomentAs(todayStart)).toList();

    double progressValue = 0;

    switch (_currentDailyChallenge!.type) {
      case ChallengeType.earnAmountToday:
        double earnedToday = todaySessions.fold(0.0, (prev, s) => prev + s.earnedAmount);
        progressValue = earnedToday / _currentDailyChallenge!.targetValue;
        break;
      case ChallengeType.completeSessionsToday:
        progressValue = todaySessions.length / _currentDailyChallenge!.targetValue;
        break;
      case ChallengeType.earnInOneSession:
        double maxEarnedInOneSessionToday = 0;
        if (todaySessions.isNotEmpty) {
            maxEarnedInOneSessionToday = todaySessions.map((s)=>s.earnedAmount).reduce(max);
        }
        progressValue = maxEarnedInOneSessionToday / _currentDailyChallenge!.targetValue;
        break;
      case ChallengeType.specificDurationSession:
        bool achieved = todaySessions.any((s) => s.duration.inSeconds == _currentDailyChallenge!.targetValue.toInt());
        progressValue = achieved ? 1.0 : 0.0;
        break;
      case ChallengeType.unlockAchievementToday:
        progressValue = 0.0;
        break;
    }
    _currentChallengeProgress = progressValue.clamp(0.0, 1.0);
  }

  Future<void> _checkChallengeCompletion(SessionData? lastSession) async {
    if (_currentDailyChallenge == null || _currentDailyChallenge!.isCompleted) return;

    _updateChallengeProgress();

    bool challengeNowCompleted = false;
    if (_currentChallengeProgress >= 1.0) {
        if (_currentDailyChallenge!.type == ChallengeType.earnAmountToday ||
            _currentDailyChallenge!.type == ChallengeType.completeSessionsToday ||
            _currentDailyChallenge!.type == ChallengeType.earnInOneSession) {
            challengeNowCompleted = true;
        }
    }
    if (_currentDailyChallenge!.type == ChallengeType.specificDurationSession && lastSession != null) {
        if (lastSession.duration.inSeconds == _currentDailyChallenge!.targetValue.toInt()) {
            challengeNowCompleted = true;
        }
    }

    if (challengeNowCompleted) {
      Challenge justCompletedChallenge = _currentDailyChallenge!;
      justCompletedChallenge.isCompleted = true;

      HapticFeedback.heavyImpact();
      _completedDailyChallengeIdsForToday.add(justCompletedChallenge.id);
      await _storageService.saveCurrentDailyChallenge(justCompletedChallenge);
      await _storageService.saveCompletedDailyChallengeIds(_completedDailyChallengeIdsForToday);

      _newlyCompletedChallengesBuffer.add(justCompletedChallenge);

      _anyChallengeEverCompleted = true;
      _dailyChallengeStreak++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('anyChallengeEverCompleted', _anyChallengeEverCompleted);
      await prefs.setInt('dailyChallengeStreak', _dailyChallengeStreak);
      await prefs.setString('lastCompletedChallengeDate', DateTime.now().toIso8601String().substring(0,10));


      Challenge? nextChallenge = _challengeService.selectDailyChallenge(DateTime.now(), _completedDailyChallengeIdsForToday);
      _currentDailyChallenge = nextChallenge;
      await _storageService.saveCurrentDailyChallenge(_currentDailyChallenge);

      _updateChallengeProgress();
      notifyListeners();
    }
  }


  Future<void> setUserName(String name) async {
    _userName = name.trim().isEmpty ? "Anonieme Held" : name.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _userName);
    await _updateLeaderboardEntry();
    notifyListeners();
  }

  Future<void> setUserStatus(String status) async {
    _userStatus = status.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userStatus', _userStatus);
    await _updateLeaderboardEntry();
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
        if (!_unlockedAchievementIds.contains(id)) {
            _unlockedAchievementIds.add(id);
            Achievement? unlockedAch = _allAchievements.firstWhere((ach) => ach.id == id, orElse: () => _achievementService.getAllAchievements().firstWhere((a) => a.id == id));
            unlockedAch.isUnlocked = true;
            unlockedAch.unlockedTimestamp = DateTime.now();
            if (!isInitialLoad) {
            HapticFeedback.mediumImpact();
            _newlyUnlockedAchievementsBuffer.add(unlockedAch);
            }
        }
      }
      await _storageService.saveUnlockedAchievementIds(_unlockedAchievementIds.map((id) => id.toString()).toList());
      notifyListeners();
    }
  }


  double get totalSessionEarnings
  {
    if (_sessionsHistory.isEmpty) return 0.0;
    return _sessionsHistory.fold(0.0, (currentTotal, session) => currentTotal + session.earnedAmount);
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
    if (state == AppLifecycleState.resumed) {
      _loadOrAssignDailyChallenge();
    }
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
        HapticFeedback.lightImpact();
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
    HapticFeedback.mediumImpact();
    _startPeriodicTimerUpdates();
    notifyListeners();
  }

  void cancelCurrentSession() {
    if (_isTracking) {
      _timer?.cancel();
      _isTracking = false;
      _sessionStartTime = null;
      _currentEarnings = 0.0;
      HapticFeedback.heavyImpact();
      notifyListeners();
    }
  }

  Future<void> _updateLeaderboardEntry({bool isReset = false}) async {
    if (_currentUserId == null) return;

    Rank userRank = currentRank;

    List<Map<String, dynamic>> recentSessionsForFirestore = [];
    if (!isReset && _sessionsHistory.isNotEmpty) {
        recentSessionsForFirestore = _sessionsHistory
            .sorted((a, b) => b.startTime.compareTo(a.startTime))
            .take(5)
            .map((session) => session.toJson())
            .toList();
    }

    Map<String, dynamic> leaderboardData = {
      'userId': _currentUserId,
      'userName': _userName,
      'totalEarnings': isReset ? 0.0 : totalSessionEarnings,
      'currentRankName': userRank.name,
      'currentRankEmoji': userRank.emoji,
      'lastUpdated': FieldValue.serverTimestamp(),
      'recentSessions': recentSessionsForFirestore,
      'userStatus': _userStatus,
    };

    try {
      await _firestore
          .collection('leaderboardEntries')
          .doc(_currentUserId)
          .set(leaderboardData, SetOptions(merge: true));
      debugPrint("Leaderboard entry bijgewerkt (isReset: $isReset) voor $_currentUserId.");
    } catch (e, s) {
      debugPrint("Fout bij bijwerken leaderboard: $e");
      debugPrint("Stacktrace: $s");
    }
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
      HapticFeedback.mediumImpact();
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
      if (didRankUp) {
        HapticFeedback.heavyImpact();
      }

      sessionResult = SessionResult(
        sessionData: completedSessionData,
        didRankUp: didRankUp,
        oldRank: rankBeforeSession,
        newRank: rankAfterSession,
        earningsInSession: finalEarningsInSession,
      );
      await _checkForNewAchievements();
      await _checkChallengeCompletion(completedSessionData);
      await _updateLeaderboardEntry();
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
        .fold(0.0, (currentTotal, session) => currentTotal + session.earnedAmount);
  }

  double get earningsToday {
    DateTime today = DateTime.now();
    DateTime startOfToday = DateTime(today.year, today.month, today.day);
    return _sessionsHistory
        .where((session) => session.startTime.isAfter(startOfToday) || session.startTime.isAtSameMomentAs(startOfToday))
        .fold(0.0, (currentTotal, session) => currentTotal + session.earnedAmount);
  }

  Future<void> deleteSession(SessionData sessionToDelete) async {
    _sessionsHistory.removeWhere((session) =>
        session.startTime == sessionToDelete.startTime &&
        session.endTime == sessionToDelete.endTime &&
        session.earnedAmount == sessionToDelete.earnedAmount
    );
    await _storageService.saveSessions(_sessionsHistory);
    _unlockedAchievementIds.clear();
    for (var ach in _allAchievements) {
        ach.isUnlocked = false;
        ach.unlockedTimestamp = null;
    }
    await _checkForNewAchievements(isInitialLoad: true);
    await _updateLeaderboardEntry();
    await _loadOrAssignDailyChallenge();
    notifyListeners();
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
    _selectRandomTrivia();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userName');
    await prefs.remove('userStatus');
    await prefs.remove('dataVersion');
    await prefs.remove('dailyChallengeStreak');
    await prefs.remove('anyChallengeEverCompleted');
    await prefs.remove('lastCompletedChallengeDate');

    _userName = "Anonieme Held";
    _userStatus = "";
    _dailyChallengeStreak = 0;
    _anyChallengeEverCompleted = false;

    await _updateLeaderboardEntry(isReset: true);
    await _loadOrAssignDailyChallenge();


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
    int totalSeconds = _sessionsHistory.fold(0, (currentTotal, s) => currentTotal + s.duration.inSeconds);
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
    var summedByDay = groupedByDay.map((day, sessions) => MapEntry(day, sessions.fold(0.0, (currentTotal, s) => currentTotal + s.earnedAmount)));
    if (summedByDay.isEmpty) return "N.v.t.";
    var mostProductive = summedByDay.entries.reduce((curr, next) => curr.value > next.value ? curr : next);
    List<String> days = ["Ma", "Di", "Wo", "Do", "Vr", "Za", "Zo"];
    return days[mostProductive.key - 1];
  }

  String get mostProductiveHourOfDay {
    if (_sessionsHistory.isEmpty) return "N.v.t.";
    var groupedByHour = groupBy(_sessionsHistory, (SessionData s) => s.startTime.hour);
    var summedByHour = groupedByHour.map((hour, sessions) => MapEntry(hour, sessions.fold(0.0, (currentTotal, s) => currentTotal + s.earnedAmount)));
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

    int cat1 = 0;
    int cat2 = 0;
    int cat3 = 0;

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