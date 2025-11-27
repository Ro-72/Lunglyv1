import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String name;
  final String dosage; // Dosis (ej: "500mg")
  final String frequency; // Frecuencia (ej: "Cada 8 horas")
  final String duration; // Duración (ej: "7 días")
  final String instructions; // Instrucciones adicionales

  Medication({
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.duration,
    this.instructions = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'duration': duration,
      'instructions': instructions,
    };
  }

  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      name: map['name'] ?? '',
      dosage: map['dosage'] ?? '',
      frequency: map['frequency'] ?? '',
      duration: map['duration'] ?? '',
      instructions: map['instructions'] ?? '',
    );
  }
}

class Prescription {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final DateTime createdAt;
  final List<Medication> medications;
  final String generalInstructions; // Instrucciones generales
  final DateTime? validUntil; // Fecha de vencimiento de la receta

  Prescription({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.createdAt,
    required this.medications,
    this.generalInstructions = '',
    this.validUntil,
  });

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'medications': medications.map((m) => m.toMap()).toList(),
      'generalInstructions': generalInstructions,
      'validUntil': validUntil != null ? Timestamp.fromDate(validUntil!) : null,
    };
  }

  factory Prescription.fromMap(Map<String, dynamic> map, String id) {
    return Prescription(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      medications: (map['medications'] as List<dynamic>?)
              ?.map((m) => Medication.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      generalInstructions: map['generalInstructions'] ?? '',
      validUntil: map['validUntil'] != null
          ? (map['validUntil'] as Timestamp).toDate()
          : null,
    );
  }
}
