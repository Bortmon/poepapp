// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import 'settings_screen.dart';
import 'tracking_screen.dart';
import 'achievements_screen.dart';
import 'statistics_screen.dart';
import 'leaderboard_screen.dart';
import '../utils/currency_formatter.dart';
import '../models/session_data.dart';
import '../models/rank.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget { // Verander naar StatefulWidget voor Trivia animatie
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _triviaAnimationController;
  late Animation<double> _triviaFadeAnimation;
  String _displayedTrivia = "";
  Key _triviaKey = UniqueKey(); // Om de widget te forceren opnieuw te bouwen

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

    // Initialiseer trivia direct
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
      appState.refreshTrivia(); // Ververs de data in AppState
      setState(() {
        _displayedTrivia = appState.currentToiletTrivia; // Update lokale state voor animatie
        _triviaKey = UniqueKey(); // Forceer rebuild van de Text widget
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

  void _navigateToStatistics(BuildContext context)
  {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatisticsScreen()),
    );
  }

  void _navigateToLeaderboard(BuildContext context)
  {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
    );
  }

  void _startSession(BuildContext context, AppState appState, {bool quickStart = false})
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
    final appState = Provider.of<AppState>(context); // listen: true hier is ok voor trivia update

    // Update displayedTrivia als het verandert in AppState en de animatie niet loopt
    // Dit is voor de allereerste keer laden als de initState trivia nog leeg was.
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
            _buildRankCard(context, appState),
            const SizedBox(height: 24),
            _buildQuickStartCard(context, appState),
            const SizedBox(height: 24),
            _buildToiletTriviaCard(context, appState),
            const SizedBox(height: 24), // Consistentere spacing
            _buildNavigationCards(context),

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

    Color onRankColor = theme.colorScheme.onSurface.withOpacity(0.95); // Iets minder opacity voor betere leesbaarheid
    if (currentRank.color.computeLuminance() < 0.45) { // Drempel iets lager voor donkere kleuren
        onRankColor = Colors.white.withOpacity(0.95);
    }

    return Card(
      elevation: 6,
      color: currentRank.color.withAlpha(70), // Iets meer kleur in achtergrond
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
                style: TextStyle(fontSize: 38, color: currentRank.color), // Emoji in volle rangkleur
              ),
              const SizedBox(height: 4),
              Text(
                currentRank.name,
                style: theme.textTheme.headlineMedium?.copyWith( // Groter lettertype
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
                  style: theme.textTheme.bodyLarge?.copyWith( // Iets groter
                    color: onRankColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                )
              else
                Text(
                  'Hoogste rang bereikt! Gefeliciteerd!',
                  style: theme.textTheme.bodyLarge?.copyWith( // Iets groter
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
                  color: onRankColor.withOpacity(0.75),
                ),
                textAlign: TextAlign.center,
              )
            ],
          ),
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
              Icons.rocket_launch_outlined,
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
              onPressed: () => _startSession(context, appState, quickStart: true),
            ),
            const SizedBox(height: 12),
            OutlinedButton( // Veranderd naar OutlinedButton
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: theme.colorScheme.primary.withAlpha(150)),
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              ),
              child: const Text('Sessie aanpassen / Uurloon checken'),
              onPressed: () => _startSession(context, appState, quickStart: false),
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
                  onPressed: () => _refreshTriviaUI(appState), // Gebruik de nieuwe methode
                  tooltip: 'Nieuwe trivia',
                  visualDensity: VisualDensity.compact,
                )
              ],
            ),
            const SizedBox(height: 8),
            FadeTransition( // Animatie voor de tekst
              key: _triviaKey, // Key om rebuild te forceren
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

  Widget _buildNavigationCards(BuildContext context) {
    final theme = Theme.of(context);
    Widget navItem(String title, IconData icon, VoidCallback onTap) {
      return Expanded(
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: onTap,
            child: Container( // Container voor gradient
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surface.withAlpha(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 8.0), // Meer verticale padding
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: theme.colorScheme.primary, size: 36), // Iets groter icoon
                    const SizedBox(height: 10),
                    Text(title, style: theme.textTheme.bodyLarge, textAlign: TextAlign.center), // Iets grotere tekst
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          navItem('Statistieken', Icons.insights_rounded, () => _navigateToStatistics(context)),
          const SizedBox(width: 16), // Iets meer ruimte
          navItem('Leaderboard', Icons.leaderboard_rounded, () => _navigateToLeaderboard(context)),
        ],
      ),
    );
  }
}