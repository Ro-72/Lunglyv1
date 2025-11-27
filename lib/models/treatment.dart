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
  final bool isPrescription; // Si es una receta médica
  final bool prescriptionActivated; // Si la receta fue activada por el paciente

  // Configuración compartida para todos los medicamentos
  final bool useSharedSettings; // Si todos comparten frecuencia y duración
  final String? sharedFrequency; // Frecuencia compartida (si useSharedSettings = true)
  final int? sharedDurationDays; // Duración compartida en días (si useSharedSettings = true)

  Treatment({
    required this.id,
    required this.name,
    this.description = '',
    required this.medications,
    this.isActive = true,
    required this.userId,
    this.progress = 0.0,
    DateTime? createdAt,
    this.isPrescription = false,
    this.prescriptionActivated = false,
    this.useSharedSettings = false,
    this.sharedFrequency,
    this.sharedDurationDays,
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
      'isPrescription': isPrescription,
      'prescriptionActivated': prescriptionActivated,
      'useSharedSettings': useSharedSettings,
      'sharedFrequency': sharedFrequency,
      'sharedDurationDays': sharedDurationDays,
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
      isPrescription: map['isPrescription'] ?? false,
      prescriptionActivated: map['prescriptionActivated'] ?? false,
      useSharedSettings: map['useSharedSettings'] ?? false,
      sharedFrequency: map['sharedFrequency'],
      sharedDurationDays: map['sharedDurationDays'],
    );
  }

  Treatment copyWith({
    String? name,
    String? description,
    List<Medication>? medications,
    bool? isActive,
    double? progress,
    bool? isPrescription,
    bool? prescriptionActivated,
    bool? useSharedSettings,
    String? sharedFrequency,
    int? sharedDurationDays,
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
      isPrescription: isPrescription ?? this.isPrescription,
      prescriptionActivated: prescriptionActivated ?? this.prescriptionActivated,
      useSharedSettings: useSharedSettings ?? this.useSharedSettings,
      sharedFrequency: sharedFrequency ?? this.sharedFrequency,
      sharedDurationDays: sharedDurationDays ?? this.sharedDurationDays,
    );
  }
}
