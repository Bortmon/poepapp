// lib/screens/leaderboard_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/currency_formatter.dart';
import '../main.dart'; 

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

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

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String name = data['userName'] ?? 'Anoniem';
              double earnings = (data['totalEarnings'] ?? 0.0).toDouble();
              String rankEmoji = data['currentRankEmoji'] ?? '❓';
              String rankName = data['currentRankName'] ?? 'Onbekend';
              String entryUserId = data['userId'] ?? '';

              bool isCurrentUser = currentUserId != null && entryUserId == currentUserId;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isCurrentUser ? theme.colorScheme.primary.withAlpha(50) : theme.cardTheme.color,
                elevation: isCurrentUser ? 6 : 2,
                child: ListTile(
                  leading: Text(
                    '${index + 1}.',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser ? theme.colorScheme.primary : theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  title: Text(
                    '$rankEmoji $name',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('Rang: $rankName'),
                  trailing: Text(
                    formatCurrency(earnings),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).extension<MyThemeColors>()!.moneyColor,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}