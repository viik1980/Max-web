import 'package:intl/intl.dart';

Map<String, dynamic> calculatePlan({
  required double remainingKm,
  required double avgSpeed,
  required int available9h,
  required int available10h,
  bool comfortMode = true,
  DateTime? startTime,
}) {
  final now = startTime ?? DateTime.now();
  // compute remaining hours digit-by-digit safe (simple double here)
  double remainingHours = 0.0;
  if (avgSpeed > 0) {
    remainingHours = remainingKm / avgSpeed;
  }

  double totalDriven = 0.0;
  double continuous = 0.0;
  DateTime cursor = now;
  final steps = <Map<String, dynamic>>[];
  final warnings = <String>[];

  while (remainingHours > 0.0001) {
    double canDrive = 4.5 - continuous;
    if (canDrive <= 1e-6) {
      // add mandatory break
      steps.add({
        'action': 'break',
        'duration_minutes': 45,
        'start_time': cursor.toUtc().toIso8601String()
      });
      cursor = cursor.add(Duration(minutes: 45));
      continuous = 0.0;
      continue;
    }

    double driveNow = remainingHours < canDrive ? remainingHours : canDrive;

    if (totalDriven + driveNow > 9.0) {
      if (available10h > 0 && totalDriven + driveNow <= 10.0) {
        available10h -= 1;
      } else {
        double allowed = 9.0 - totalDriven;
        if (allowed <= 1e-6) {
          warnings.add('Daily driving limit reached; recommend daily rest.');
          break;
        } else {
          driveNow = allowed;
        }
      }
    }

    // comfort mode: avoid main night window (23-05) by shifting small segments if possible
    if (comfortMode) {
      final hour = cursor.toLocal().hour;
      if (hour >= 23 || hour < 5) {
        // insert a rest-of-night recommendation if driving would fall into long night period
        warnings.add('Planned driving starts in night hours; consider delaying to daytime for comfort.');
      }
    }

    final distance = (driveNow * avgSpeed);
    steps.add({
      'action': 'drive',
      'duration_minutes': (driveNow * 60).round(),
      'distance_km': distance.round(),
      'start_time': cursor.toUtc().toIso8601String()
    });

    cursor = cursor.add(Duration(minutes: (driveNow * 60).round()));
    remainingHours -= driveNow;
    totalDriven += driveNow;
    continuous += driveNow;

    if (continuous >= 4.5 - 1e-6) {
      steps.add({
        'action': 'break',
        'duration_minutes': 45,
        'start_time': cursor.toUtc().toIso8601String()
      });
      cursor = cursor.add(Duration(minutes: 45));
      continuous = 0.0;
    }
  }

  return {
    'total_driving_hours': double.parse(totalDriven.toStringAsFixed(2)),
    'next_break_after_hours': continuous > 0 ? double.parse((4.5 - continuous).toStringAsFixed(2)) : 4.5,
    'recommended_break_minutes': 45,
    'steps': steps,
    'warnings': warnings,
  };
}