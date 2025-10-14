import 'package:cloud_firestore/cloud_firestore.dart';
import 'medication.dart';

class Treatment {
  final String id;
  final String name; // Nombre del tratamiento (ej: "Tratamiento para Asma")
  final String description; // Descripción del tratamiento
  final List<Medication> medications; // Lista de medicamentos
  final bool isActive;
  final String userId;
  final double progress;
  final DateTime createdAt;

  Treatment({
    required this.id,
    required this.name,
    this.description = '',
    required this.medications,
    this.isActive = true,
    required this.userId,
    this.progress = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'medications': medications.map((med) => med.toMap()).toList(),
      'isActive': isActive,
      'userId': userId,
      'progress': progress,
      'createdAt': createdAt,
    };
  }

  factory Treatment.fromMap(Map<String, dynamic> map, String id) {
    return Treatment(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      medications: (map['medications'] as List<dynamic>?)
              ?.map((medMap) => Medication.fromMap(medMap as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: map['isActive'] ?? true,
      userId: map['userId'] ?? '',
      progress: (map['progress'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Treatment copyWith({
    String? name,
    String? description,
    List<Medication>? medications,
    bool? isActive,
    double? progress,
  }) {
    return Treatment(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      medications: medications ?? this.medications,
      isActive: isActive ?? this.isActive,
      userId: userId,
      progress: progress ?? this.progress,
      createdAt: createdAt,
    );
  }
}
