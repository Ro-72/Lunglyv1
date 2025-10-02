import 'package:cloud_firestore/cloud_firestore.dart';

class Treatment {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime nextDose;
  final bool isActive;
  final String userId;
  final double progress;

  Treatment({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.nextDose,
    this.isActive = true,
    required this.userId,
    this.progress = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'nextDose': nextDose,
      'isActive': isActive,
      'userId': userId,
      'progress': progress,
    };
  }

  factory Treatment.fromMap(Map<String, dynamic> map, String id) {
    return Treatment(
      id: id,
      name: map['name'],
      dosage: map['dosage'],
      frequency: map['frequency'],
      nextDose: (map['nextDose'] as Timestamp).toDate(),
      isActive: map['isActive'] ?? true,
      userId: map['userId'],
      progress: map['progress'] ?? 0.0,
    );
  }
}
