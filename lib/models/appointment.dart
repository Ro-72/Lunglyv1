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

  Appointment({
    required this.id,
    required this.doctorId,
    required this.patientId,
    required this.date,
    required this.startTime,
    required this.durationHours,
    this.status = 'scheduled',
    required this.price,
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
    );
  }
}

class DoctorSchedule {
  final String doctorId;
  final int startHour;
  final int endHour;
  final List<String> workDays;

  DoctorSchedule({
    required this.doctorId,
    required this.startHour,
    required this.endHour,
    required this.workDays,
  });

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'startHour': startHour,
      'endHour': endHour,
      'workDays': workDays,
    };
  }

  factory DoctorSchedule.fromMap(Map<String, dynamic> map) {
    return DoctorSchedule(
      doctorId: map['doctorId'] ?? '',
      startHour: map['startHour'] ?? 8,
      endHour: map['endHour'] ?? 16,
      workDays: List<String>.from(map['workDays'] ?? []),
    );
  }
}
