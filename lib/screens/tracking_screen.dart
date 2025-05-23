// lib/screens/tracking_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../main.dart';
import '../models/session_result.dart';
import '../models/rank.dart';
import '../models/achievement.dart';
import '../models/challenge.dart';

class TrackingScreen extends StatefulWidget
{
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> with TickerProviderStateMixin
{
  late ConfettiController _confettiController;
  late ConfettiController _achievementConfettiController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;


  @override
  void initState()
  {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _achievementConfettiController = ConfettiController(duration: const Duration(seconds: 1));

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _pulseController.reverse();
      }
    });
  }

  @override
  void dispose()
  {
    _confettiController.dispose();
    _achievementConfettiController.dispose();
    _pulseController.dispose();
    super.dispose();
  }


  Future<void> _showAchievementUnlockedPopup(BuildContext context, Achievement achievement) async {
    final theme = Theme.of(context);
    _achievementConfettiController.play();

    Color popupBackgroundColor = achievement.iconColor.computeLuminance() > 0.5
        ? achievement.iconColor.withBlue(max(0, achievement.iconColor.blue - 50)).withGreen(max(0, achievement.iconColor.green - 50)).withRed(max(0, achievement.iconColor.red - 50))
        : Color.alphaBlend(achievement.iconColor.withAlpha((0.4 * 255).round()), theme.colorScheme.surface);

    if (popupBackgroundColor.computeLuminance() > 0.65) {
        popupBackgroundColor = HSLColor.fromColor(popupBackgroundColor).withLightness(0.25).toColor();
    }
    if (ThemeData.estimateBrightnessForColor(popupBackgroundColor) == Brightness.light) {
        popupBackgroundColor = theme.colorScheme.surface;
    }


    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AlertDialog(
              backgroundColor: popupBackgroundColor,
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
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withAlpha(230)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: popupBackgroundColor,
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
                colors: const [
                    Colors.yellow, Colors.white, Colors.amber
                ],
              ),
            ),
          ],
        );
      },
    );
  }


  Future<void> _showSessionSummaryPopup(BuildContext context, SessionResult result, double progressBeforeSession, double progressAfterSession) async
  {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context, listen: false);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext)
      {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
          contentPadding: const EdgeInsets.fromLTRB(20.0, 10.0, 20.0, 16.0),
          actionsPadding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 16.0),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Sessie Voltooid!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const Text('🚽✅', style: TextStyle(fontSize: 28)),
            ],
          ),
          content: SessionSummaryDialogContent(
            result: result,
            appState: appState,
            progressBeforeSession: progressBeforeSession,
            progressAfterSession: progressAfterSession,
            vsync: this,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(140, 48),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
              ),
              child: const Text('Oké'),
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
                colors: const [
                  Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showChallengeCompletedPopup(BuildContext context, Challenge challenge) async {
    final theme = Theme.of(context);
    _achievementConfettiController.play();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return Stack(
          alignment: Alignment.center,
          children: [
            AlertDialog(
              backgroundColor: Colors.green[700]?.withAlpha(220),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
              title: Center(
                child: Text(
                  'UITDAGING VOLTOOID!',
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
                  const Icon(Icons.star_rounded, size: 60, color: Colors.yellowAccent),
                  const SizedBox(height: 16),
                  Text(
                    challenge.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.description,
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white.withAlpha(230)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: <Widget>[
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.green[800],
                  ),
                  child: const Text('Lekker Bezig!', style: TextStyle(fontWeight: FontWeight.bold)),
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
                numberOfParticles: 25,
                gravity: 0.1,
                shouldLoop: false,
                colors: const [Colors.greenAccent, Colors.lightGreenAccent, Colors.white],
              ),
            ),
          ],
        );
      },
    );
  }


  void _confirmAndCancelSession(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sessie Annuleren?'),
        content: const Text('Weet je zeker dat je de huidige sessie wilt annuleren? Je verdiensten voor deze sessie gaan verloren.'),
        actions: [
          TextButton(
            child: const Text('Nee, doorgaan'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Ja, Annuleren'),
            onPressed: () {
              Navigator.of(ctx).pop();
              appState.cancelCurrentSession();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Sessie geannuleerd.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: const EdgeInsets.all(10),
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;
    final appState = Provider.of<AppState>(context, listen: false);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) {
        if (didPop) return;
        _confirmAndCancelSession(context, appState);
      },
      child: Scaffold(
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
                if (consumerAppState.isTracking) {
                  _pulseController.forward(from:0.0);
                }
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
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: myColors.moneyColor?.withAlpha((0.1 * 255).round()),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          formatCurrencyLiveTracker(consumerAppState.currentEarnings),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: myColors.moneyColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
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
                        double progressBefore = appState.progressToNextRank;
                        SessionResult? result = await appState.stopTracking();
                        double progressAfter = appState.progressToNextRank;
                        List<Achievement> newlyUnlockedAchievements = appState.newlyUnlockedAchievementsToShow;
                        List<Challenge> newlyCompletedChallenges = appState.newlyCompletedChallengesToShow;

                        if (result != null && mounted)
                        {
                          await _showSessionSummaryPopup(context, result, progressBefore, progressAfter);
                          if (result.didRankUp && mounted)
                          {
                            await _showRankUpPopup(context, result.newRank, result.oldRank);
                          }
                        }
                        if (mounted && newlyUnlockedAchievements.isNotEmpty) {
                          for (var ach in newlyUnlockedAchievements) {
                             await _showAchievementUnlockedPopup(context, ach);
                          }
                        }
                        if (mounted && newlyCompletedChallenges.isNotEmpty) {
                          for (var chal in newlyCompletedChallenges) {
                             await _showChallengeCompletedPopup(context, chal);
                          }
                        }
                        if (mounted)
                        {
                          Navigator.of(context).pop();
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      icon: Icon(Icons.cancel_outlined, color: theme.textTheme.bodySmall?.color?.withAlpha(180)),
                      label: Text(
                        'Sessie Annuleren',
                        style: TextStyle(color: theme.textTheme.bodySmall?.color?.withAlpha(200)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: theme.dividerColor.withAlpha(100)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      onPressed: () {
                        _confirmAndCancelSession(context, appState);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SessionSummaryDialogContent extends StatefulWidget {
  final SessionResult result;
  final AppState appState;
  final double progressBeforeSession;
  final double progressAfterSession;
  final TickerProvider vsync;

  const SessionSummaryDialogContent({
    super.key,
    required this.result,
    required this.appState,
    required this.progressBeforeSession,
    required this.progressAfterSession,
    required this.vsync,
  });

  @override
  State<SessionSummaryDialogContent> createState() => _SessionSummaryDialogContentState();
}

class _SessionSummaryDialogContentState extends State<SessionSummaryDialogContent> {
  late AnimationController _progressAnimationController;
  late Animation<double> _progressAnimation;
  late AnimationController _xpGainController;
  late Animation<double> _xpGainAnimation;
  bool _showXPGain = false;

  @override
  void initState() {
    super.initState();
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: widget.vsync,
    );

    _progressAnimation = Tween<double>(
      begin: widget.progressBeforeSession,
      end: widget.progressAfterSession,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    _xpGainController = AnimationController(
      duration: const Duration(milliseconds: 8000),
      vsync: widget.vsync,
    );
    _xpGainAnimation = CurvedAnimation(parent: _xpGainController, curve: Curves.easeOutBack);


    _progressAnimationController.forward().whenComplete(() {
      if (widget.result.earningsInSession > 0) {
        setState(() {
          _showXPGain = true;
        });
        _xpGainController.forward();
      }
    });
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _xpGainController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return "${hours}u ${twoDigits(minutes)}m ${twoDigits(seconds)}s";
    if (minutes > 0) return "${twoDigits(minutes)}m ${twoDigits(seconds)}s";
    return "${twoDigits(seconds)}s";
  }

  Widget _buildSectionCard({required List<Widget> children, Color? cardColor, EdgeInsetsGeometry? padding}) {
    return Card(
      elevation: 2,
      color: cardColor ?? Theme.of(context).colorScheme.surface.withAlpha(150),
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 8),

            _buildSectionCard(
              cardColor: myColors.moneyColor?.withAlpha(30),
              children: [
                Text(
                  'Sessie Resultaat',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: myColors.moneyColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.monetization_on_outlined, color: myColors.moneyColor, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      formatCurrencyStandard(widget.result.earningsInSession),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: myColors.moneyColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Duur: ${_formatDuration(widget.result.sessionData.duration)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(200)
                  ),
                  textAlign: TextAlign.center,
                ),
              ]
            ),

            _buildSectionCard(
              cardColor: widget.result.newRank.color.withAlpha(30),
              padding: const EdgeInsets.symmetric(horizontal:16, vertical: 20),
              children: [
                Text(
                  'Rang Progressie',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: widget.result.newRank.color),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(widget.result.newRank.emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                    Text(
                      widget.result.newRank.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: widget.result.newRank.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (widget.appState.nextRank != null) ...[
                  Stack(
                    alignment: Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progressAnimation.value,
                                backgroundColor: widget.result.newRank.color.withAlpha(70),
                                valueColor: AlwaysStoppedAnimation<Color>(widget.result.newRank.color),
                                minHeight: 22,
                              ),
                            );
                          },
                        ),
                      ),
                      if (_showXPGain && widget.result.earningsInSession > 0)
                        Positioned(
                          left: 0,
                          bottom: 25,
                          child: AnimatedBuilder(
                            animation: _xpGainController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(
                                  (MediaQuery.of(context).size.width * 0.7 * widget.progressBeforeSession) * _xpGainAnimation.value,
                                  -30 * _xpGainAnimation.value
                                ),
                                child: FadeTransition(
                                  opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                                    CurvedAnimation(parent: _xpGainController, curve: const Interval(0.5, 1.0))
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: myColors.moneyColor,
                                      borderRadius: BorderRadius.circular(6),
                                      boxShadow: [
                                          BoxShadow(
                                              color: Colors.black.withOpacity(0.4),
                                              blurRadius: 4,
                                              offset: const Offset(0,2),
                                          )
                                      ]
                                    ),
                                    child: Text(
                                      '+${formatCurrencyStandard(widget.result.earningsInSession)} XP',
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              );
                            }
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Nog € ${widget.appState.earningsNeededForNextRank.toStringAsFixed(2)} tot ${widget.appState.nextRank!.name} ${widget.appState.nextRank!.emoji}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withAlpha(220)
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                    Text(
                    'Hoogste rang bereikt! Fantastisch!',
                    style: theme.textTheme.titleMedium?.copyWith(color: widget.result.newRank.color, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ]
              ]
            ),
          ],
        ),
      ),
    );
  }
}