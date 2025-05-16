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
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                if (achievements.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: unlockedCount / achievements.length,
                      backgroundColor: theme.colorScheme.surface.withAlpha(150),
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      minHeight: 10,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: achievements.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emoji_events_outlined, size: 80, color: theme.iconTheme.color?.withAlpha(100)),
                          const SizedBox(height: 16),
                          Text(
                            "Begin je WC Avontuur!",
                            style: theme.textTheme.headlineSmall?.copyWith(color: theme.textTheme.headlineSmall?.color?.withAlpha(180)),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ontgrendel prestaties door de app te gebruiken en je verdiensten te maximaliseren.",
                            style: theme.textTheme.bodyLarge?.copyWith(color: theme.textTheme.bodyLarge?.color?.withAlpha(200)),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.9,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: achievements.length,
                    itemBuilder: (context, index) {
                      final achievement = achievements[index];
                      bool isUnlocked = achievement.isUnlocked;
                      Color cardColor = isUnlocked ? achievement.iconColor.withAlpha(40) : theme.colorScheme.surface.withAlpha(100);
                      Color iconColor = isUnlocked ? achievement.iconColor : theme.iconTheme.color!.withAlpha(80);
                      Color textColor = isUnlocked ? achievement.iconColor : theme.colorScheme.onSurface;

                      return Card(
                        elevation: isUnlocked ? 4 : 1,
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isUnlocked ? achievement.iconColor.withAlpha(150) : Colors.transparent,
                            width: 1.5
                          )
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Icon(
                                isUnlocked ? achievement.icon : Icons.lock_outline_rounded,
                                size: 52,
                                color: iconColor,
                              ),
                              Column(
                                children: [
                                  Text(
                                    achievement.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    achievement.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: textColor.withAlpha(isUnlocked ? 200 : 150),
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                              if (isUnlocked && achievement.unlockedTimestamp != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6.0),
                                  child: Text(
                                    DateFormat('dd-MM-yy', 'nl_NL').format(achievement.unlockedTimestamp!),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: textColor.withAlpha(180),
                                    ),
                                  ),
                                ) 
                              else if (!isUnlocked)
                                const SizedBox(height: 14)
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