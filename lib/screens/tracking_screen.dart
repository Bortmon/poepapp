// lib/screens/tracking_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../main.dart';

class TrackingScreen extends StatelessWidget
{
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessie Actief'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Consumer<AppState>(
            builder: (context, appState, child)
            {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Je verdient nu:',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8)
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: myColors.moneyColor?.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      formatCurrency(appState.currentEarnings),
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
                    onPressed: ()
                    {
                      appState.stopTracking();
                      Navigator.of(context).pop();
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