// lib/models/session_data.dart
import 'package:flutter/foundation.dart';

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
    DateTime parsedStartTime;
    DateTime parsedEndTime;
    double parsedEarnedAmount;

    try
    {
      if (json['startTime'] == null) {
        debugPrint("!!! SessionData.fromJson: startTime is null in json: $json");
        parsedStartTime = DateTime.now();
      } else {
        parsedStartTime = DateTime.parse(json['startTime'] as String);
      }
    }
    catch (e)
    {
      debugPrint("!!! Fout bij parsen startTime: ${json['startTime']} - $e. Json: $json");
      parsedStartTime = DateTime.now();
    }

    try
    {
      if (json['endTime'] == null) {
        debugPrint("!!! SessionData.fromJson: endTime is null in json: $json");
        parsedEndTime = DateTime.now();
      } else {
        parsedEndTime = DateTime.parse(json['endTime'] as String);
      }
    }
    catch (e)
    {
      debugPrint("!!! Fout bij parsen endTime: ${json['endTime']} - $e. Json: $json");
      parsedEndTime = DateTime.now();
    }

    try
    {
      if (json['earnedAmount'] == null) {
        debugPrint("!!! SessionData.fromJson: earnedAmount is null in json: $json");
        parsedEarnedAmount = 0.0;
      } else if (json['earnedAmount'] is int) {
        parsedEarnedAmount = (json['earnedAmount'] as int).toDouble();
      } else if (json['earnedAmount'] is double) {
        parsedEarnedAmount = json['earnedAmount'] as double;
      } else {
        try {
          parsedEarnedAmount = double.parse(json['earnedAmount'].toString());
        } catch (parseError) {
          debugPrint("!!! SessionData.fromJson: earnedAmount kon niet geparsed worden naar double: ${json['earnedAmount']} - $parseError. Json: $json");
          parsedEarnedAmount = 0.0;
        }
      }
    }
    catch (e)
    {
      debugPrint("!!! Algemene fout bij parsen earnedAmount: ${json['earnedAmount']} - $e. Json: $json");
      parsedEarnedAmount = 0.0;
    }

    return SessionData(
      startTime: parsedStartTime,
      endTime: parsedEndTime,
      earnedAmount: parsedEarnedAmount,
    );
  }
}