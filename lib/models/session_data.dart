// lib/models/session_data.dart
class SessionData
{
  final DateTime startTime;
  final DateTime endTime;
  final double earnedAmount;

  SessionData({
    required this.startTime,
    required this.endTime,
    required this.earnedAmount,
  });

  Duration get duration => endTime.difference(startTime);

  Map<String, dynamic> toJson() =>
  {
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'earnedAmount': earnedAmount,
  };

  factory SessionData.fromJson(Map<String, dynamic> json)
  {
    return SessionData(
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      earnedAmount: json['earnedAmount'],
    );
  }
}