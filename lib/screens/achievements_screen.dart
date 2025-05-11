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

    int unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prestaties'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  '$unlockedCount / ${achievements.length} Prestaties Ontgrendeld',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                if (achievements.isNotEmpty)
                  LinearProgressIndicator(
                    value: unlockedCount / achievements.length,
                    backgroundColor: theme.colorScheme.surface.withAlpha(150),
                    valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
              ],
            ),
          ),
          Expanded(
            child: achievements.isEmpty
                ? const Center(child: Text('Nog geen prestaties gedefinieerd.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1 / 1.2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      return Card(
                        elevation: achievement.isUnlocked ? 5 : 2,
                        color: achievement.isUnlocked
                            ? achievement.iconColor.withAlpha(40)
                            : theme.colorScheme.surface.withAlpha(100),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: achievement.isUnlocked ? achievement.iconColor : Colors.transparent,
                            width: 1.5
                          )
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                achievement.isUnlocked ? achievement.icon : Icons.lock_outline_rounded,
                                size: 48,
                                color: achievement.isUnlocked ? achievement.iconColor : theme.iconTheme.color?.withAlpha(80),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                achievement.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: achievement.isUnlocked ? achievement.iconColor : theme.textTheme.titleMedium?.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                achievement.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: achievement.isUnlocked
                                      ? theme.textTheme.bodySmall?.color?.withAlpha(200)
                                      : theme.textTheme.bodySmall?.color?.withAlpha(120),
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (achievement.isUnlocked && achievement.unlockedTimestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    DateFormat('dd-MM-yy', 'nl_NL').format(achievement.unlockedTimestamp!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: achievement.iconColor.withAlpha(180),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}