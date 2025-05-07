// lib/screens/tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../main.dart';
import '../models/session_data.dart';

class TrackingScreen extends StatelessWidget
{
  const TrackingScreen({super.key});

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

  Future<void> _showSessionSummaryPopup(BuildContext context, SessionData sessionData) async
  {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext)
      {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Row(
            children: [
              Text('Sessie Voltooid! ', style: theme.textTheme.headlineSmall),
              const Text('💩🎉', style: TextStyle(fontSize: 24)),
            ],
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Goed bezig!',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyLarge,
                    children: <TextSpan>[
                      const TextSpan(text: 'Je hebt '),
                      TextSpan(
                        text: formatCurrency(sessionData.earnedAmount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: myColors.moneyColor,
                          fontSize: (theme.textTheme.bodyLarge?.fontSize ?? 16) * 1.1,
                        ),
                      ),
                      const TextSpan(text: ' verdiend.'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Duur: ${_formatDurationForPopup(sessionData.duration)}',
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Top!', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16)),
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
                      color: theme.textTheme.bodyLarge?.color?.withAlpha((0.8 * 255).round()) // withAlpha
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: myColors.moneyColor?.withAlpha((0.1 * 255).round()), // withAlpha
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
                      SessionData? completedSession = await appState.stopTracking();
                      if (completedSession != null && context.mounted)
                      {
                        await _showSessionSummaryPopup(context, completedSession);
                      }
                      if (context.mounted)
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