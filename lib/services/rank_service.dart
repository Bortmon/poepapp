// lib/services/rank_service.dart
import 'package:flutter/material.dart';
import '../models/rank.dart';

class RankService
{
  static final List<Rank> ranks = [
    const Rank(name: 'WC Groentje', minEarnings: 0, maxEarnings: 7.5, emoji: '🌱', color: Colors.lightGreen),
    const Rank(name: 'Porselein Piraat', minEarnings: 7.5, maxEarnings: 25, emoji: '🏴‍☠️', color: Colors.blueGrey),
    const Rank(name: 'Kleine Boodschapper', minEarnings: 25, maxEarnings: 75, emoji: '✉️', color: Colors.lightBlue),
    const Rank(name: 'Grote Boodschapper', minEarnings: 75, maxEarnings: 150, emoji: '📬', color: Colors.orange),
    const Rank(name: 'Keramiek Kapitein', minEarnings: 150, maxEarnings: 300, emoji: '🚢', color: Colors.teal),
    const Rank(name: 'Sanitair Sensei', minEarnings: 300, maxEarnings: 500, emoji: '🧘‍♂️', color: Colors.deepPurpleAccent),
    const Rank(name: 'Troon Meester', minEarnings: 500, emoji: '👑', color: Colors.amber),
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