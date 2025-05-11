enum ChallengeType {
  earnAmountToday,
  completeSessionsToday,
  specificDurationSession,
  unlockAchievementToday,
  earnInOneSession,
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final double targetValue;
  final String unit;
  bool isCompleted;
  DateTime dateAssigned;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    this.unit = "",
    this.isCompleted = false,
    required this.dateAssigned,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.toString(),
        'targetValue': targetValue,
        'unit': unit,
        'isCompleted': isCompleted,
        'dateAssigned': dateAssigned.toIso8601String(),
      };

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: ChallengeType.values.firstWhere((e) => e.toString() == json['type'], orElse: () => ChallengeType.earnAmountToday),
      targetValue: (json['targetValue'] as num).toDouble(),
      unit: json['unit'],
      isCompleted: json['isCompleted'],
      dateAssigned: DateTime.parse(json['dateAssigned']),
    );
  }
}