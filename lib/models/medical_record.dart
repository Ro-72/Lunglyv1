import 'package:cloud_firestore/cloud_firestore.dart';

class MedicalRecord {
  final String id;
  final String appointmentId;
  final String patientId;
  final String doctorId;
  final DateTime createdAt;
  final String diagnosis; // Diagnóstico
  final String symptoms; // Síntomas
  final String treatment; // Tratamiento
  final String notes; // Notas adicionales
  final Map<String, dynamic>? vitalSigns; // Signos vitales (presión, temperatura, etc.)
  final List<String>? attachments; // URLs de archivos adjuntos (estudios, imágenes, etc.)

  MedicalRecord({
    required this.id,
    required this.appointmentId,
    required this.patientId,
    required this.doctorId,
    required this.createdAt,
    required this.diagnosis,
    required this.symptoms,
    required this.treatment,
    this.notes = '',
    this.vitalSigns,
    this.attachments,
  });

  Map<String, dynamic> toMap() {
    return {
      'appointmentId': appointmentId,
      'patientId': patientId,
      'doctorId': doctorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'diagnosis': diagnosis,
      'symptoms': symptoms,
      'treatment': treatment,
      'notes': notes,
      'vitalSigns': vitalSigns,
      'attachments': attachments,
    };
  }

  factory MedicalRecord.fromMap(Map<String, dynamic> map, String id) {
    return MedicalRecord(
      id: id,
      appointmentId: map['appointmentId'] ?? '',
      patientId: map['patientId'] ?? '',
      doctorId: map['doctorId'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      diagnosis: map['diagnosis'] ?? '',
      symptoms: map['symptoms'] ?? '',
      treatment: map['treatment'] ?? '',
      notes: map['notes'] ?? '',
      vitalSigns: map['vitalSigns'] as Map<String, dynamic>?,
      attachments: map['attachments'] != null
          ? List<String>.from(map['attachments'])
          : null,
    );
  }
}
