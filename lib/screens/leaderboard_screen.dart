// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../main.dart';
import '../models/session_data.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {

  String _formatDurationPopup(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) return "${hours}u ${twoDigits(minutes)}m ${twoDigits(seconds)}s";
    if (minutes > 0) return "${twoDigits(minutes)}m ${twoDigits(seconds)}s";
    return "${twoDigits(seconds)}s";
  }

  Future<void> _showUserDetailPopup(BuildContext context, Map<String, dynamic> userData, int totalUserSessions) async {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;

    String name = userData['userName'] ?? 'Anoniem';
    String rankEmoji = userData['currentRankEmoji'] ?? '❓';
    String rankName = userData['currentRankName'] ?? 'Onbekend';
    String userStatus = userData['userStatus'] ?? '';
    double totalEarnings = (userData['totalEarnings'] ?? 0.0).toDouble();
    List<dynamic> rawRecentSessions = userData['recentSessions'] ?? [];
    List<SessionData> recentSessions = rawRecentSessions
        .map((sessionMap) => SessionData.fromJson(Map<String, dynamic>.from(sessionMap)))
        .toList();

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          titlePadding: const EdgeInsets.all(0),
          contentPadding: const EdgeInsets.all(0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withAlpha(50),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16.0),
                topRight: Radius.circular(16.0),
              ),
            ),
            child: Row(
              children: [
                Text(rankEmoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(child: Text("Rang: $rankName", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600))),
                  if (userStatus.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.format_quote_rounded, size: 20, color: theme.iconTheme.color?.withAlpha(180)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              userStatus,
                              style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: theme.textTheme.bodyMedium?.color?.withAlpha(220)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text("Totaal Verdiend", style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withAlpha(180))),
                          Text(formatCurrencyStandard(totalEarnings), style: theme.textTheme.titleLarge?.copyWith(color: myColors.moneyColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        children: [
                          Text("Sessies", style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withAlpha(180))),
                          Text(totalUserSessions.toString(), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  Text("Recente Sessies:", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (recentSessions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text("Nog geen recente sessies beschikbaar.", style: TextStyle(fontStyle: FontStyle.italic)),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentSessions.length,
                      itemBuilder: (ctx, i) {
                        final session = recentSessions[i];
                        String durationText = _formatDurationPopup(session.duration);
                        if (session.duration.inSeconds == 0 && session.duration.inMilliseconds > 0) {
                          durationText = "<1s";
                        } else if (session.duration.inSeconds == 0) {
                          durationText = "0s";
                        }
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  DateFormat('dd-MM-yy HH:mm', 'nl_NL').format(session.startTime),
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  durationText,
                                  style: theme.textTheme.bodySmall,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  formatCurrencyStandard(session.earnedAmount),
                                  style: theme.textTheme.bodySmall?.copyWith(color: myColors.moneyColor, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      separatorBuilder: (context, index) => const Divider(height: 1, thickness: 0.5),
                    ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Sluiten'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }


  Widget _buildPodiumItem(BuildContext context, Map<String, dynamic> userData, int rank, int totalUserSessions, {required bool isCenter}) {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;
    String name = userData['userName'] ?? 'Anoniem';
    double earnings = (userData['totalEarnings'] ?? 0.0).toDouble();
    String rankEmoji = userData['currentRankEmoji'] ?? '❓';

    double elevation = isCenter ? 8 : 6;
    Color podiumColor = Colors.grey[800]!;
    String rankTextPrefix = '';
    double avatarSize = isCenter ? 50 : 40;
    TextStyle nameStyle = theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold);
    EdgeInsets padding = isCenter ? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0) : const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0);


    if (rank == 1) {
      podiumColor = Colors.amber[700]!;
      rankTextPrefix = '🥇 ';
      nameStyle = theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold, color: Colors.amber[700]);
    } else if (rank == 2) {
      podiumColor = Colors.grey[500]!;
      rankTextPrefix = '🥈 ';
      nameStyle = theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: Colors.grey[300]);
    } else if (rank == 3) {
      podiumColor = const Color(0xFFCD7F32);
      rankTextPrefix = '🥉 ';
      nameStyle = theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFFE0A46F));
    }

    return Card(
      elevation: elevation,
      color: podiumColor.withAlpha(40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: podiumColor, width: 1.5),
      ),
      margin: EdgeInsets.only(
        bottom: isCenter ? 0 : 20,
      ),
      child: InkWell(
        onTap: () => _showUserDetailPopup(context, userData, totalUserSessions),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(rankTextPrefix, style: TextStyle(fontSize: avatarSize * 0.4)),
              Text(rankEmoji, style: TextStyle(fontSize: avatarSize * 0.7)),
              const SizedBox(height: 6),
              Text(name, style: nameStyle, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, maxLines: 1),
              Text(formatCurrencyStandard(earnings), style: theme.textTheme.bodyMedium?.copyWith(color: myColors.moneyColor, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, Map<String, dynamic> userData, int rank, bool isCurrentUser, int totalUserSessions) {
    final theme = Theme.of(context);
    final myColors = MyThemeColors.of(context)!;
    String name = userData['userName'] ?? 'Anoniem';
    double earnings = (userData['totalEarnings'] ?? 0.0).toDouble();
    String rankEmoji = userData['currentRankEmoji'] ?? '❓';
    String rankName = userData['currentRankName'] ?? 'Onbekend';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      color: isCurrentUser ? theme.colorScheme.primary.withAlpha(40) : theme.cardTheme.color,
      elevation: isCurrentUser ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
        side: isCurrentUser ? BorderSide(color: theme.colorScheme.primary, width: 1.5) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _showUserDetailPopup(context, userData, totalUserSessions),
        borderRadius: BorderRadius.circular(10.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  '$rank.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: isCurrentUser ? theme.colorScheme.primary : theme.textTheme.bodySmall?.color,
                    fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              Text(rankEmoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(rankName, style: theme.textTheme.bodySmall?.copyWith(color: theme.textTheme.bodySmall?.color?.withAlpha(180))),
                  ],
                ),
              ),
              Text(
                formatCurrencyStandard(earnings),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: myColors.moneyColor),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = Provider.of<AppState>(context);
    final myColors = MyThemeColors.of(context)!;


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
          if (snapshot.hasError) return Center(child: Text('Fout: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline_rounded, size: 70, color: theme.iconTheme.color?.withAlpha(100)),
                    const SizedBox(height: 16),
                    Text(
                      'Het leaderboard is nog leeg!',
                      style: theme.textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Voltooi wat sessies om de eerste held te worden.',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          int currentUserRank = -1;
          Map<String, dynamic>? currentUserData;
          String? currentUserId = appState.currentUserId;

          List<Map<String, dynamic>> allUsersData = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

          for (int i = 0; i < allUsersData.length; i++) {
            if (allUsersData[i]['userId'] == currentUserId) {
              currentUserRank = i + 1;
              currentUserData = allUsersData[i];
              break;
            }
          }

          List<Map<String, dynamic>> top3 = allUsersData.take(3).toList();
          List<Map<String, dynamic>> restOfTheList = allUsersData.length > 3 ? allUsersData.sublist(3) : [];


          return Column(
            children: [
              if (top3.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 20.0, bottom: 12.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        flex: 3,
                        child: top3.length > 1
                            ? _buildPodiumItem(context, top3[1], 2, (top3[1]['sessionsHistoryCount'] ?? 0).toInt(), isCenter: false)
                            : const SizedBox(),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 4,
                        child: top3.isNotEmpty
                            ? _buildPodiumItem(context, top3[0], 1, (top3[0]['sessionsHistoryCount'] ?? 0).toInt(), isCenter: true)
                            : const SizedBox(),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        flex: 3,
                        child: top3.length > 2
                            ? _buildPodiumItem(context, top3[2], 3, (top3[2]['sessionsHistoryCount'] ?? 0).toInt(), isCenter: false)
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ),
              const Divider(height: 24, thickness: 0.5, indent: 16, endIndent: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                  itemCount: restOfTheList.length,
                  itemBuilder: (context, index) {
                    final data = restOfTheList[index];
                    final displayRank = index + 4;
                    final bool isCurrentUser = currentUserId != null && data['userId'] == currentUserId;
                    final int totalUserSessions = (data['sessionsHistoryCount'] ?? 0).toInt();
                    return _buildListItem(context, data, displayRank, isCurrentUser, totalUserSessions);
                  },
                ),
              ),
              if (currentUserRank > 3 && currentUserData != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal:16, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5))
                  ),
                  child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Jouw Positie: #$currentUserRank", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                      Text(formatCurrencyStandard((currentUserData['totalEarnings'] ?? 0.0).toDouble()), style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: myColors.moneyColor)),
                    ],
                  ),
                )
            ],
          );
        },
      ),
    );
  }
}