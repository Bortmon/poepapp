// lib/models/session_result.dart
import 'session_data.dart';
import 'rank.dart';

class SessionResult
{
  final SessionData sessionData;
  final bool didRankUp;
  final Rank oldRank;
  final Rank newRank; 
  final double earningsInSession;

  SessionResult({
    required this.sessionData,
    required this.didRankUp,
    required this.oldRank,
    required this.newRank,
    required this.earningsInSession,
  });
}