// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../main.dart';
import '../models/session_data.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  String _formatDurationPopup(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return "${hours}u ${twoDigits(minutes)}m ${twoDigits(seconds)}s";
    if (minutes > 0) return "${twoDigits(minutes)}m ${twoDigits(seconds)}s";
    return "${twoDigits(seconds)}s";
  }

  Future<void> _showUserDetailPopup(BuildContext context, Map<String, dynamic> userData) async {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;

    String name = userData['userName'] ?? 'Anoniem';
    String rankEmoji = userData['currentRankEmoji'] ?? '❓';
    String rankName = userData['currentRankName'] ?? 'Onbekend';
    String userStatus = userData['userStatus'] ?? '';
    List<dynamic> rawRecentSessions = userData['recentSessions'] ?? [];
    List<SessionData> recentSessions = rawRecentSessions
        .map((sessionMap) => SessionData.fromJson(Map<String, dynamic>.from(sessionMap)))
        .toList();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0), // Bredere dialog
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          title: Row(
            children: [
              Text(rankEmoji, style: const TextStyle(fontSize: 32)), // Iets grotere emoji
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Container( // Container om breedte te sturen
            width: MediaQuery.of(context).size.width * 0.85, // Bijv. 85% van schermbreedte
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text("Rang: $rankName", style: theme.textTheme.titleMedium?.copyWith(color: theme.textTheme.titleMedium?.color?.withAlpha(220))),
                  if (userStatus.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, size: 16, color: theme.iconTheme.color?.withAlpha(180)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '"$userStatus"',
                            style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: theme.textTheme.bodyMedium?.color?.withAlpha(200)),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text("Recente Sessies:", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  if (recentSessions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withAlpha(20), // Subtiele achtergrond
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text("Nog geen recente sessies beschikbaar.", style: TextStyle(fontStyle: FontStyle.italic)),
                      ),
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: recentSessions.map((session) {
                        String durationText = _formatDurationPopup(session.duration);
                        if (session.duration.inSeconds == 0 && session.duration.inMilliseconds > 0) {
                          durationText = "<1s";
                        } else if (session.duration.inSeconds == 0) {
                          durationText = "0s";
                        }
                        return Container( // Blok voor elke sessie
                          margin: const EdgeInsets.symmetric(vertical: 4.0),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withAlpha(25), // Grijzig transparant blok
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  DateFormat('dd-MM-yy HH:mm', 'nl_NL').format(session.startTime),
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  durationText,
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formatCurrencyStandard(session.earnedAmount),
                                  style: theme.textTheme.bodyMedium?.copyWith(color: myColors.moneyColor, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Sluiten', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Widget _buildRankIndicator(BuildContext context, int rank, bool isCurrentUser) {
    final theme = Theme.of(context);
    Color rankColor = theme.textTheme.titleLarge?.color ?? theme.colorScheme.onSurface;
    String prefix = '';

    if (isCurrentUser) {
      rankColor = theme.colorScheme.primary;
    }

    if (rank == 1) {
      prefix = '👑 ';
      if (!isCurrentUser) rankColor = Colors.amber[600]!;
    } else if (rank == 2) {
      if (!isCurrentUser) rankColor = Colors.grey[400]!;
    } else if (rank == 3) {
      if (!isCurrentUser) rankColor = Colors.brown[300]!;
    }

    return Text(
      '$prefix$rank.',
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: rank <= 3 ? FontWeight.bold : FontWeight.normal,
        color: rankColor,
        fontSize: (theme.textTheme.titleLarge?.fontSize ?? 20) * (rank == 1 ? 1.0 : 0.95),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String? currentUserId = Provider.of<AppState>(context, listen: false).currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Top Poepende Helden 🏆'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('leaderboardEntries')
            .orderBy('totalEarnings', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Fout: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Nog geen helden op het leaderboard!'));
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String name = data['userName'] ?? 'Anoniem';
              double earnings = (data['totalEarnings'] ?? 0.0).toDouble();
              String rankEmoji = data['currentRankEmoji'] ?? '❓';
              String rankName = data['currentRankName'] ?? 'Onbekend';
              String entryUserId = data['userId'] ?? '';

              bool isCurrentUser = currentUserId != null && entryUserId == currentUserId;
              int displayRank = index + 1;

              List<BoxShadow>? cardShadows;
              Color? cardBorderColor;
              double cardBorderWidth = 0;

              if (displayRank == 1) {
                cardBorderColor = Colors.amber[700];
                cardBorderWidth = 2.0;
                cardShadows = [
                  BoxShadow(
                    color: Colors.amber.withAlpha(80),
                    blurRadius: 12.0,
                    spreadRadius: 1.0,
                  ),
                ];
              } else if (displayRank == 2) {
                cardBorderColor = Colors.grey[500];
                cardBorderWidth = 1.5;
                cardShadows = [
                  BoxShadow(
                    color: Colors.grey.withAlpha(60),
                    blurRadius: 8.0,
                    spreadRadius: 0.5,
                  ),
                ];
              } else if (displayRank == 3) {
                cardBorderColor = Colors.brown[400];
                cardBorderWidth = 1.5;
                cardShadows = [
                  BoxShadow(
                    color: Colors.brown.withAlpha(50),
                    blurRadius: 6.0,
                  ),
                ];
              }
              if (isCurrentUser && cardBorderColor == null) {
                  cardBorderColor = theme.colorScheme.primary;
                  cardBorderWidth = 1.5;
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: cardBorderColor != null
                      ? BorderSide(color: cardBorderColor, width: cardBorderWidth)
                      : (isCurrentUser ? BorderSide(color: theme.colorScheme.primary, width: 1.5) : BorderSide.none),
                ),
                child: InkWell(
                  onTap: () {
                    _showUserDetailPopup(context, data);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isCurrentUser ? theme.colorScheme.primary.withAlpha(40) : theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: cardShadows,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: _buildRankIndicator(context, displayRank, isCurrentUser),
                      title: Text(
                        '$rankEmoji $name',
                        style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isCurrentUser ? theme.colorScheme.primary : theme.textTheme.titleMedium?.color
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('Rang: $rankName', style: theme.textTheme.bodySmall),
                      trailing: Text(
                        formatCurrencyStandard(earnings),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).extension<MyThemeColors>()!.moneyColor,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 4),
          );
        },
      ),
    );
  }
}