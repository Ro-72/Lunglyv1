import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime date;
  final String startTime;
  final int durationHours;
  final String status; // 'pending', 'confirmed', 'completed', 'cancelled'
  final double price;
  final String? paymentMethod;
  final String? medicalRecordId;
  final String? prescriptionId;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final bool isArchived; // Nuevo campo

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.date,
    required this.startTime,
    required this.durationHours,
    this.status = 'pending',
    required this.price,
    this.paymentMethod,
    this.medicalRecordId,
    this.prescriptionId,
    this.confirmedAt,
    this.completedAt,
    this.isArchived = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'durationHours': durationHours,
      'status': status,
      'price': price,
      'paymentMethod': paymentMethod,
      'medicalRecordId': medicalRecordId,
      'prescriptionId': prescriptionId,
      'confirmedAt': confirmedAt != null ? Timestamp.fromDate(confirmedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isArchived': isArchived,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    return Appointment(
      id: id,
      doctorId: map['doctorId'] ?? '',
      patientId: map['patientId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '',
      durationHours: map['durationHours'] ?? 1,
      status: map['status'] ?? 'pending',
      price: (map['price'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'],
      medicalRecordId: map['medicalRecordId'],
      prescriptionId: map['prescriptionId'],
      confirmedAt: map['confirmedAt'] != null ? (map['confirmedAt'] as Timestamp).toDate() : null,
      completedAt: map['completedAt'] != null ? (map['completedAt'] as Timestamp).toDate() : null,
      isArchived: map['isArchived'] ?? false,
    );
  }
}
