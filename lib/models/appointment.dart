import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final DateTime date;
  final String startTime;
  final int durationHours;
  final String status;
  final double price;
  final String? paymentMethod;

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.date,
    required this.startTime,
    required this.durationHours,
    this.status = 'scheduled',
    required this.price,
    this.paymentMethod,
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
      status: map['status'] ?? 'scheduled',
      price: (map['price'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'],
    );
  }
}
