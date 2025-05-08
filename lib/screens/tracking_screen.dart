// lib/screens/tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../main.dart';
import '../models/session_result.dart';
import '../models/rank.dart';
import '../models/achievement.dart'; 

class TrackingScreen extends StatefulWidget
{
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen>
{
  late ConfettiController _confettiController;
  late ConfettiController _achievementConfettiController;


  @override
  void initState()
  {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _achievementConfettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose()
  {
    _confettiController.dispose();
    _achievementConfettiController.dispose();
    super.dispose();
  }

  String _formatDurationForPopup(Duration duration)
  {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    List<String> parts = [];
    if (hours > 0) parts.add("${hours}u");
    if (minutes > 0) parts.add("${twoDigits(minutes)}m");
    if (seconds > 0 || parts.isEmpty) parts.add("${twoDigits(seconds)}s");

    return parts.join(" ");
  }

  Future<void> _showAchievementUnlockedPopup(BuildContext context, Achievement achievement) async {
    final theme = Theme.of(context);
    _achievementConfettiController.play();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AlertDialog(
              backgroundColor: achievement.iconColor.withAlpha(150),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              title: Center(
                child: Text(
                  'PRESTATIE ONTGRENDELD!',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(achievement.icon, size: 60, color: Colors.white),
                  const SizedBox(height: 16),
                  Text(
                    achievement.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    achievement.description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withAlpha(220)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: achievement.iconColor,
                  ),
                  child: const Text('Cool!', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _achievementConfettiController,
                blastDirectionality: BlastDirectionality.explosive,
                particleDrag: 0.05,
                emissionFrequency: 0.05,
                numberOfParticles: 20,
                gravity: 0.05,
                shouldLoop: false,
                colors: const [Colors.yellow, Colors.white, Colors.amber],
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _showSessionSummaryPopup(BuildContext context, SessionResult result) async
  {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext)
      {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
          contentPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
          actionsPadding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 16.0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sessie Voltooid!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Text('🚽✅', style: TextStyle(fontSize: 28)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.monetization_on_outlined, color: myColors.moneyColor, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${formatCurrency(result.earningsInSession)} verdiend',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: myColors.moneyColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 36),
                  child: Text(
                    'Duur: ${_formatDurationForPopup(result.sessionData.duration)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withAlpha(180)
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Jouw Rang:',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(result.newRank.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      result.newRank.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: result.newRank.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (appState.nextRank != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: appState.progressToNextRank,
                      backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
                      valueColor: AlwaysStoppedAnimation<Color>(result.newRank.color),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Nog € ${appState.earningsNeededForNextRank.toStringAsFixed(2)} tot ${appState.nextRank!.name} ${appState.nextRank!.emoji}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                       color: theme.textTheme.bodyMedium?.color?.withAlpha(200)
                    ),
                  ),
                ] else ...[
                   Text(
                    'Hoogste rang bereikt! Fantastisch!',
                    style: theme.textTheme.titleMedium?.copyWith(color: result.newRank.color, fontWeight: FontWeight.bold),
                  ),
                ]
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(120, 44),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              child: const Text('Oké', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: ()
              {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showRankUpPopup(BuildContext context, Rank newRank, Rank oldRank) async
  {
    final theme = Theme.of(context);
    _confettiController.play();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext)
      {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            AlertDialog(
              backgroundColor: newRank.color.withAlpha(200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24.0)),
              contentPadding: const EdgeInsets.all(24.0),
              title: Center(child: Text('RANG GESTEGEN!', style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(oldRank.emoji, style: const TextStyle(fontSize: 36)),
                            Text(oldRank.name, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white70)),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_rounded, size: 30, color: Colors.white),
                        Column(
                          children: [
                            Text(newRank.emoji, style: TextStyle(fontSize: 52, color: newRank.color.computeLuminance() > 0.5 ? Colors.black87: Colors.white)),
                            Text(newRank.name, style: theme.textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Gefeliciteerd!',
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Je bent nu een echte ${newRank.name}!',
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white.withAlpha(220)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: newRank.color,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                    child: const Text('Fantastisch!'),
                    onPressed: ()
                    {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 30,
                gravity: 0.3,
                emissionFrequency: 0.05,
                colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessie Actief'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Consumer<AppState>(
            builder: (context, consumerAppState, child)
            {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Je verdient nu:',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withAlpha((0.8 * 255).round())
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: myColors.moneyColor?.withAlpha((0.1 * 255).round()),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      formatCurrency(consumerAppState.currentEarnings),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: myColors.moneyColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined, size: 28),
                    label: const Text('Stop Sessie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                      textStyle: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      )
                    ),
                    onPressed: () async
                    {
                      SessionResult? result = await appState.stopTracking();
                      List<Achievement> newlyUnlocked = appState.newlyUnlockedAchievementsToShow;

                      if (result != null && mounted)
                      {
                        await _showSessionSummaryPopup(context, result);
                        if (result.didRankUp && mounted)
                        {
                          await _showRankUpPopup(context, result.newRank, result.oldRank);
                        }
                      }
                      if (mounted && newlyUnlocked.isNotEmpty) {
                        for (var ach in newlyUnlocked) {
                           await _showAchievementUnlockedPopup(context, ach);
                        }
                      }
                      if (mounted)
                      {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}