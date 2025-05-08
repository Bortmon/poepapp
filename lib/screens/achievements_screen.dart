// lib/screens/achievements_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../models/achievement.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final theme = Theme.of(context);
    List<Achievement> achievements = List.from(appState.allAchievements);
    achievements.sort((a, b) {
      if (a.isUnlocked && !b.isUnlocked) return -1;
      if (!a.isUnlocked && b.isUnlocked) return 1;
      return a.name.compareTo(b.name);
    });


    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestaties'),
      ),
      body: achievements.isEmpty
          ? const Center(child: Text('Nog geen prestaties gedefinieerd.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return Card(
                  elevation: achievement.isUnlocked ? 4 : 1,
                  color: achievement.isUnlocked
                      ? achievement.iconColor.withAlpha(50)
                      : theme.colorScheme.surface.withAlpha(150),
                  child: ListTile(
                    leading: Icon(
                      achievement.isUnlocked ? achievement.icon : Icons.lock_outline,
                      size: 36,
                      color: achievement.isUnlocked ? achievement.iconColor : theme.iconTheme.color?.withAlpha(100),
                    ),
                    title: Text(
                      achievement.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: achievement.isUnlocked ? achievement.iconColor : theme.textTheme.titleMedium?.color,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          achievement.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: achievement.isUnlocked
                                ? theme.textTheme.bodySmall?.color?.withAlpha(200)
                                : theme.textTheme.bodySmall?.color?.withAlpha(120),
                          ),
                        ),
                        if (achievement.isUnlocked && achievement.unlockedTimestamp != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Ontgrendeld: ${DateFormat('dd-MM-yyyy HH:mm', 'nl_NL').format(achievement.unlockedTimestamp!)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                                color: achievement.iconColor.withAlpha(180),
                              ),
                            ),
                          ),
                      ],
                    ),
                    trailing: achievement.isUnlocked
                        ? Icon(Icons.check_circle, color: Colors.greenAccent[700], size: 28)
                        : null,
                  ),
                );
              },
            ),
    );
  }
}