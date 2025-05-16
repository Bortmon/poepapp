// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import 'settings_screen.dart';
import 'tracking_screen.dart';
import 'achievements_screen.dart';
import '../models/rank.dart';
import '../models/challenge.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _triviaAnimationController;
  late Animation<double> _triviaFadeAnimation;
  String _displayedTrivia = "";
  Key _triviaKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _triviaAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _triviaFadeAnimation = CurvedAnimation(
      parent: _triviaAnimationController,
      curve: Curves.easeInOut,
    );

    final appState = Provider.of<AppState>(context, listen: false);
    _displayedTrivia = appState.currentToiletTrivia;
    if (_displayedTrivia.isNotEmpty) {
      _triviaAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _triviaAnimationController.dispose();
    super.dispose();
  }

  void _refreshTriviaUI(AppState appState) {
    _triviaAnimationController.reverse().then((_) {
      appState.refreshTrivia();
      setState(() {
        _displayedTrivia = appState.currentToiletTrivia;
        _triviaKey = UniqueKey();
      });
      _triviaAnimationController.forward();
    });
  }


  void _navigateToSettings(BuildContext context)
  {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  void _navigateToAchievements(BuildContext context)
  {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AchievementsScreen()),
    );
  }

  void _startSession(BuildContext context, AppState appState)
  {
    if (appState.hourlyWage <= 0)
    {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Uurloon Vereist'),
          content: const Text('Stel eerst je uurloon in via de instellingen.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Annuleren'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('Naar Instellingen'),
              onPressed: ()
              {
                Navigator.of(ctx).pop();
                _navigateToSettings(context);
              },
            ),
          ],
        ),
      );
    }
    else
    {
      appState.startTracking();
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TrackingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);

    if (_displayedTrivia.isEmpty && appState.currentToiletTrivia.isNotEmpty && !_triviaAnimationController.isAnimating) {
        _displayedTrivia = appState.currentToiletTrivia;
        _triviaAnimationController.forward();
    }


    return Scaffold(
      appBar: AppBar(
        title: const Text('WC Geld Tracker'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: theme.colorScheme.primary),
            onPressed: () => _navigateToSettings(context),
            tooltip: 'Instellingen',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildDailyChallengeCard(context, appState),
            const SizedBox(height: 24),
            _buildQuickStartCard(context, appState),
            const SizedBox(height: 24),
            _buildRankCard(context, appState),
            const SizedBox(height: 24),
            _buildToiletTriviaCard(context, appState),

            if (appState.hourlyWage <= 0 && !appState.isTracking && appState.sessionsHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Card(
                  color: theme.colorScheme.primary.withAlpha((0.1 * 255).round()),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: theme.colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Stel je uurloon in via de instellingen (rechtsboven) om te beginnen!",
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;
    final Rank currentRank = appState.currentRank;
    final Rank? nextRank = appState.nextRank;
    final double progress = appState.progressToNextRank;
    final double needed = appState.earningsNeededForNextRank;

    Color onRankColor = Colors.white.withOpacity(0.95);
    if (currentRank.color.computeLuminance() < 0.45 && currentRank.color != Colors.transparent) {
        onRankColor = Colors.white.withOpacity(0.95);
    } else if (currentRank.color.computeLuminance() > 0.6) {
        onRankColor = theme.colorScheme.surface.withOpacity(0.95);
    }


    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToAchievements(context),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                myColors.rankCardGradientStart ?? currentRank.color.withAlpha(180),
                myColors.rankCardGradientEnd ?? currentRank.color.withAlpha(220),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 24), 
                  Column(
                    children: [
                       Text(
                        currentRank.emoji,
                        style: TextStyle(fontSize: 36, color: onRankColor),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentRank.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onRankColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  Icon(Icons.info_outline_rounded, size: 20, color: onRankColor.withOpacity(0.7)),
                ],
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(7),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withAlpha(50),
                  valueColor: AlwaysStoppedAnimation<Color>(onRankColor.withOpacity(0.8)),
                  minHeight: 14,
                ),
              ),
              const SizedBox(height: 12),
              if (nextRank != null)
                Text(
                  'Nog € ${needed.toStringAsFixed(2)} tot ${nextRank.name} ${nextRank.emoji}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onRankColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  'Hoogste rang bereikt! Gefeliciteerd!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: onRankColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyChallengeCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final Challenge? challenge = appState.currentDailyChallenge;

    IconData challengeIcon = Icons.flag_rounded;
    Color challengeColor = theme.colorScheme.primary;
    String challengeStatusText = "Dagelijkse Uitdaging:";

    if (challenge != null && challenge.isCompleted) {
      challengeIcon = Icons.check_circle_rounded;
      challengeColor = Colors.green;
      challengeStatusText = "Uitdaging Voltooid!";
    } else if (challenge == null) {
      challengeIcon = Icons.celebration_rounded;
      challengeStatusText = "Top Prestatie!";
    }

    return Card(
      elevation: 3,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(challengeIcon, color: challengeColor, size: 28),
                const SizedBox(width: 10),
                Text(
                  challengeStatusText,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: challengeColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (challenge != null) ...[
              Text(
                challenge.title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                challenge.description,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(200)),
              ),
              if (!challenge.isCompleted && challenge.type != ChallengeType.specificDurationSession && challenge.type != ChallengeType.unlockAchievementToday) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: appState.currentChallengeProgress,
                          backgroundColor: theme.colorScheme.onSurface.withAlpha(50),
                          valueColor: AlwaysStoppedAnimation<Color>(challengeColor),
                          minHeight: 10, // Iets dikker
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(appState.currentChallengeProgress * 100).toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(color: challengeColor, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
              if (challenge.isCompleted)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Center(
                    child: Text(
                      "Goed gedaan! 🎉",
                      style: theme.textTheme.titleMedium?.copyWith(color: Colors.green[600], fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ] else ...[
               Text(
                  "Alle uitdagingen voor vandaag voltooid of geen beschikbaar. Kom morgen terug!",
                  style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurface),
                ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              size: 52,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Klaar voor een snelle sessie?',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 30),
              label: const Text('Snel Starten'),
              style: theme.elevatedButtonTheme.style?.copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 36),
                ),
                textStyle: WidgetStateProperty.all(
                  theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onPrimary)
                )
              ),
              onPressed: () => _startSession(context, appState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToiletTriviaCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🚽 Toilet Trivia',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded, size: 22, color: theme.colorScheme.primary),
                  onPressed: () => _refreshTriviaUI(appState),
                  tooltip: 'Nieuwe trivia',
                  visualDensity: VisualDensity.compact,
                )
              ],
            ),
            const SizedBox(height: 8),
            FadeTransition(
              key: _triviaKey,
              opacity: _triviaFadeAnimation,
              child: Text(
                _displayedTrivia.isNotEmpty ? _displayedTrivia : "Even geduld voor een wijs weetje...",
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withAlpha(220)),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}