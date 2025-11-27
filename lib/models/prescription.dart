import 'package:cloud_firestore/cloud_firestore.dart';

class Prescription {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final DateTime createdAt;
  final List<Map<String, dynamic>> medications;
  final String generalInstructions;
  final DateTime? validUntil;

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
      'id': id,
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'medications': medications,
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
      medications: List<Map<String, dynamic>>.from(map['medications'] as List? ?? []),
      generalInstructions: map['generalInstructions'] ?? '',
      validUntil: map['validUntil'] != null
          ? (map['validUntil'] as Timestamp).toDate()
          : null,
    );
  }
}
