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
  final bool isCompleted;
  final DateTime? lastDose;

  Treatment({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.nextDose,
    this.isActive = true,
    required this.userId,
    this.progress = 0.0,
    this.isCompleted = false,
    this.lastDose,
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
      'isCompleted': isCompleted,
      'lastDose': lastDose,
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
      isCompleted: map['isCompleted'] ?? false,
      lastDose: map['lastDose'] != null ? (map['lastDose'] as Timestamp).toDate() : null,
    );
  }

  Treatment copyWith({
    bool? isCompleted,
    DateTime? nextDose,
    DateTime? lastDose,
  }) {
    return Treatment(
      id: id,
      name: name,
      dosage: dosage,
      frequency: frequency,
      nextDose: nextDose ?? this.nextDose,
      isActive: isActive,
      userId: userId,
      progress: progress,
      isCompleted: isCompleted ?? this.isCompleted,
      lastDose: lastDose ?? this.lastDose,
    );
  }
}
