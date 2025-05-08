// lib/services/rank_service.dart
import 'package:flutter/material.dart';
import '../models/rank.dart';

class RankService
{
  static final List<Rank> ranks = [
    const Rank(name: 'WC Groentje', minEarnings: 0, maxEarnings: 5, emoji: '🌱', color: Colors.lightGreen),
    const Rank(name: 'Porselein Piraat', minEarnings: 5, maxEarnings: 15, emoji: '🏴‍☠️', color: Colors.blueGrey),
    const Rank(name: 'Kleine Boodschapper', minEarnings: 15, maxEarnings: 35, emoji: '✉️', color: Colors.lightBlue),
    const Rank(name: 'Grote Boodschapper', minEarnings: 35, maxEarnings: 75, emoji: '📬', color: Colors.orange),
    const Rank(name: 'Troon Meester', minEarnings: 75, emoji: '👑', color: Colors.amber),
  ];

  static Rank getRankForEarnings(double totalEarnings)
  {
    for (int i = ranks.length - 1; i >= 0; i--)
    {
      if (totalEarnings >= ranks[i].minEarnings)
      {
        return ranks[i];
      }
    }
    return ranks.first;
  }

  static Rank? getNextRank(Rank currentRank)
  {
    int currentIndex = ranks.indexWhere((rank) => rank.name == currentRank.name);
    if (currentIndex != -1 && currentIndex < ranks.length - 1)
    {
      return ranks[currentIndex + 1];
    }
    return null;
  }
}