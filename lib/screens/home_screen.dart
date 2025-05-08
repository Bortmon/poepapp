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

class HomeScreen extends StatelessWidget
{
  const HomeScreen({super.key});

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


  void _startTracking(BuildContext context, AppState appState)
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
              onPressed: ()
              {
                Navigator.of(ctx).pop();
              },
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
    final myColors = MyThemeColors.of(context)!;

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
      body: Consumer<AppState>(
        builder: (context, appState, child)
        {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _buildRankSection(context, appState),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.2 * 255).round()),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ]
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.monetization_on_outlined,
                        size: 80,
                        color: myColors.moneyColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Klaar voor je volgende sessie?',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.textTheme.bodyLarge?.color?.withAlpha((0.9 * 255).round())
                        ),
                      ),
                    ],
                  )
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_fill_outlined, size: 28),
                  label: const Text('Start Sessie'),
                  style: theme.elevatedButtonTheme.style?.copyWith(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
                    ),
                    textStyle: WidgetStateProperty.all(
                      theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      )
                    )
                  ),
                  onPressed: () => _startTracking(context, appState),
                ),
                const SizedBox(height: 40),
                _buildStatsCard(context, appState, myColors),
                const SizedBox(height: 20),
                if (appState.sessionsHistory.isNotEmpty)
                  _buildHistorySection(context, appState, myColors),

                const SizedBox(height: 24),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _navigateToStatistics(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.insights_rounded, color: theme.colorScheme.primary, size: 28),
                              const SizedBox(width: 12),
                              Text('Bekijk Statistieken', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, color: theme.iconTheme.color?.withAlpha(150)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12), 
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _navigateToLeaderboard(context), 
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.leaderboard_rounded, color: theme.colorScheme.primary, size: 28),
                              const SizedBox(width: 12),
                              Text('Leaderboard', style: theme.textTheme.titleMedium),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, color: theme.iconTheme.color?.withAlpha(150)),
                        ],
                      ),
                    ),
                  ),
                ),

                if (appState.hourlyWage <= 0 && !appState.isTracking && appState.sessionsHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
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
          );
        },
      ),
    );
  }

  Widget _buildRankSection(BuildContext context, AppState appState)
  {
    final theme = Theme.of(context);
    final Rank currentRank = appState.currentRank;
    final Rank? nextRank = appState.nextRank;
    final double progress = appState.progressToNextRank;
    final double needed = appState.earningsNeededForNextRank;

    return Card(
      elevation: 4,
      color: currentRank.color.withAlpha(50),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _navigateToAchievements(context),
        splashColor: currentRank.color.withAlpha(100),
        highlightColor: currentRank.color.withAlpha(70),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${currentRank.emoji} ${currentRank.name}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: currentRank.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Icon(Icons.touch_app_outlined, size: 20, color: currentRank.color.withAlpha(150)),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surface.withAlpha(150),
                valueColor: AlwaysStoppedAnimation<Color>(currentRank.color),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 8),
              if (nextRank != null)
                Text(
                  'Nog € ${needed.toStringAsFixed(2)} tot ${nextRank.name} ${nextRank.emoji}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(200)
                  ),
                )
              else
                Text(
                  'Hoogste rang bereikt! Gefeliciteerd!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: currentRank.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildStatsCard(BuildContext context, AppState appState, MyThemeColors myColors)
  {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jouw Verdiensten',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildStatRow(
              context,
              label: 'Deze week:',
              value: formatCurrency(appState.weeklyEarnings),
              valueColor: myColors.moneyColor,
            ),
            const SizedBox(height: 8),
            _buildStatRow(
              context,
              label: 'Totaal:',
              value: formatCurrency(appState.totalSessionEarnings),
              valueColor: myColors.moneyColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, {required String label, required String value, Color? valueColor})
  {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.titleMedium),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection(BuildContext context, AppState appState, MyThemeColors myColors)
  {
    final theme = Theme.of(context);
    List<SessionData> sortedSessions = List.from(appState.sessionsHistory);
    sortedSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0, top: 16.0),
          child: Text(
            'Recente Sessies',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: DataTable(
              columnSpacing: 16.0,
              headingRowHeight: 40,
              dataRowMinHeight: 48,
              dataRowMaxHeight: 56,
              headingTextStyle: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color?.withAlpha((0.7 * 255).round()),
              ),
              dataTextStyle: theme.textTheme.bodyMedium,
              columns: const [
                DataColumn(label: Text('Datum')),
                DataColumn(label: Text('Duur'), numeric: true),
                DataColumn(label: Text('Verdiend'), numeric: true),
              ],
              rows: sortedSessions.take(5).map((session)
              {
                return DataRow(
                  cells: [
                    DataCell(Text(DateFormat('dd-MM HH:mm', 'nl_NL').format(session.startTime))),
                    DataCell(Text(_formatDuration(session.duration))),
                    DataCell(Text(
                      formatCurrency(session.earnedAmount),
                      style: TextStyle(color: myColors.moneyColor, fontWeight: FontWeight.w500),
                    )),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration)
  {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0)
    {
      return "${twoDigits(duration.inHours)}u ${twoDigitMinutes}m";
    }
    else if (duration.inMinutes > 0)
    {
      return "${twoDigitMinutes}m ${twoDigitSeconds}s";
    }
    else
    {
      return "${twoDigitSeconds}s";
    }
  }
}