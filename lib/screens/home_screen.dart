// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:intl/intl.dart'; // Niet meer nodig als _buildHistorySection hier weg is
import '../providers/app_state.dart';
import 'settings_screen.dart';
import 'tracking_screen.dart';
import 'achievements_screen.dart';
// import 'statistics_screen.dart'; // Verwijderd als navigatiepunt
// import 'leaderboard_screen.dart'; // Verwijderd als navigatiepunt
import '../utils/currency_formatter.dart';
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
    final Rank currentRank = appState.currentRank;
    final Rank? nextRank = appState.nextRank;
    final double progress = appState.progressToNextRank;
    final double needed = appState.earningsNeededForNextRank;

    Color onRankColor = theme.colorScheme.onSurface.withAlpha((0.95 * 255).round());
    if (currentRank.color.computeLuminance() < 0.45) {
        onRankColor = Colors.white.withAlpha((0.95 * 255).round());
    }

    return Card(
      elevation: 6,
      color: currentRank.color.withAlpha(70),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToAchievements(context),
        splashColor: currentRank.color.withAlpha(120),
        highlightColor: currentRank.color.withAlpha(90),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Text(
                currentRank.emoji,
                style: TextStyle(fontSize: 38, color: currentRank.color),
              ),
              const SizedBox(height: 4),
              Text(
                currentRank.name,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: currentRank.color,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surface.withAlpha(200),
                valueColor: AlwaysStoppedAnimation<Color>(currentRank.color),
                minHeight: 14,
                borderRadius: BorderRadius.circular(7),
              ),
              const SizedBox(height: 12),
              if (nextRank != null)
                Text(
                  'Nog € ${needed.toStringAsFixed(2)} tot ${nextRank.name} ${nextRank.emoji}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: onRankColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  'Hoogste rang bereikt! Gefeliciteerd!',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: currentRank.color,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 8),
              Text(
                '(Tik voor prestaties & rang details)',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: onRankColor.withAlpha((0.75 * 255).round()),
                ),
                textAlign: TextAlign.center,
              )
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
    if (challenge != null && challenge.isCompleted) {
      challengeIcon = Icons.check_circle_rounded;
    } else if (challenge == null) {
      challengeIcon = Icons.celebration_rounded;
    }


    if (challenge == null) {
      return Card(
        elevation: 3,
        color: theme.colorScheme.surface.withAlpha(180),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(challengeIcon, color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Alle uitdagingen voor vandaag voltooid of geen beschikbaar. Kom morgen terug!",
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 4,
      color: challenge.isCompleted ? Colors.green.withAlpha(50) : theme.colorScheme.primary.withAlpha(40),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  challengeIcon,
                  color: challenge.isCompleted ? Colors.green : theme.colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Text(
                  challenge.isCompleted ? "Uitdaging Voltooid!" : "Dagelijkse Uitdaging:",
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: challenge.isCompleted ? Colors.green : theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              challenge.title,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              challenge.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withAlpha(200)
              ),
            ),
            if (!challenge.isCompleted && challenge.type != ChallengeType.specificDurationSession && challenge.type != ChallengeType.unlockAchievementToday) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: appState.currentChallengeProgress,
                backgroundColor: theme.colorScheme.surface.withAlpha(180),
                valueColor: AlwaysStoppedAnimation<Color>(
                  challenge.isCompleted ? Colors.green : theme.colorScheme.primary,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${(appState.currentChallengeProgress * 100).toStringAsFixed(0)}%',
                  style: theme.textTheme.bodySmall,
                ),
              )
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartCard(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(
              Icons.rocket_launch_rounded,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Klaar voor een snelle sessie?',
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: const Text('Snel Starten'),
              style: theme.elevatedButtonTheme.style?.copyWith(
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                ),
                textStyle: WidgetStateProperty.all(
                  theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
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
      color: theme.colorScheme.surface.withAlpha(200),
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20),
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
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}