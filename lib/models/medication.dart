import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime nextDose;
  final DateTime? lastDose;
  final bool isCompleted;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.nextDose,
    this.lastDose,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'nextDose': nextDose,
      'lastDose': lastDose,
      'isCompleted': isCompleted,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? 'Diario',
      nextDose: map['nextDose'] is Timestamp
          ? (map['nextDose'] as Timestamp).toDate()
          : map['nextDose'] as DateTime,
      lastDose: map['lastDose'] != null
          ? (map['lastDose'] is Timestamp
              ? (map['lastDose'] as Timestamp).toDate()
              : map['lastDose'] as DateTime)
          : null,
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Medication copyWith({
    String? id,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? nextDose,
    DateTime? lastDose,
    bool? isCompleted,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      nextDose: nextDose ?? this.nextDose,
      lastDose: lastDose ?? this.lastDose,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
