import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String name;
  final String dosage;
  final String frequency;
  final int durationDays; // Duración en días del tratamiento
  final DateTime startDate; // Fecha de inicio
  final DateTime nextDose;
  final DateTime? lastDose;
  final bool isCompleted;

  Medication({
    required this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    DateTime? startDate,
    required this.nextDose,
    this.lastDose,
    this.isCompleted = false,
  }) : startDate = startDate ?? DateTime.now();

  // Calcula la fecha de finalización del medicamento
  DateTime get endDate => startDate.add(Duration(days: durationDays));

  // Verifica si el medicamento ha expirado
  bool get isExpired => DateTime.now().isAfter(endDate);

  // Días restantes del tratamiento
  int get daysRemaining {
    final remaining = endDate.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'durationDays': durationDays,
      'startDate': startDate,
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
      durationDays: map['durationDays'] ?? 30,
      startDate: map['startDate'] != null
          ? (map['startDate'] is Timestamp
              ? (map['startDate'] as Timestamp).toDate()
              : map['startDate'] as DateTime)
          : DateTime.now(),
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
    int? durationDays,
    DateTime? startDate,
    DateTime? nextDose,
    DateTime? lastDose,
    bool? isCompleted,
  }) {
    return Medication(
      id: id ?? this.id,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      durationDays: durationDays ?? this.durationDays,
      startDate: startDate ?? this.startDate,
      nextDose: nextDose ?? this.nextDose,
      lastDose: lastDose ?? this.lastDose,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
