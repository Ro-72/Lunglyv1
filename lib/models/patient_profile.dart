import 'package:cloud_firestore/cloud_firestore.dart';

class PatientProfile {
  final String id;
  final String userId;
  final double height; // in cm
  final double weight; // in kg
  final double imc;
  final List<String> medicalConditions;
  final List<String> allergies;
  final DateTime updatedAt;

  PatientProfile({
    required this.id,
    required this.userId,
    required this.height,
    required this.weight,
    required this.imc,
    required this.medicalConditions,
    required this.allergies,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'height': height,
      'weight': weight,
      'imc': imc,
      'medicalConditions': medicalConditions,
      'allergies': allergies,
      'updatedAt': updatedAt,
    };
  }

  factory PatientProfile.fromMap(Map<String, dynamic> map, String id) {
    return PatientProfile(
      id: id,
      userId: map['userId'],
      height: map['height']?.toDouble() ?? 0.0,
      weight: map['weight']?.toDouble() ?? 0.0,
      imc: map['imc']?.toDouble() ?? 0.0,
      medicalConditions: List<String>.from(map['medicalConditions'] ?? []),
      allergies: List<String>.from(map['allergies'] ?? []),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }
}
