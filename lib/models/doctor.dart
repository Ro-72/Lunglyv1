import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String title;
  final String specialty;
  final String description;
  final double pricePerAppointment;
  final String? profileImageUrl;
  final double rating;
  final int reviewCount;

  // Nuevos campos
  final int yearsExperience;
  final List<String> qualifications;
  final List<String> languages;
  final double distanceKm;
  final String city;
  final String hospital;
  final int? patientCount;
  final int? followUpFee;
  final int consultationMinutes;
  final bool isApolloDoctor;
  final String appointmentType; // 'online' o 'presencial'
  final int? photoNumber; // 1-5 para seleccionar foto de assets/photos

  Doctor({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.description,
    required this.pricePerAppointment,
    this.profileImageUrl,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.yearsExperience = 0,
    this.qualifications = const [],
    this.languages = const [],
    this.distanceKm = 0.0,
    this.city = '',
    this.hospital = '',
    this.patientCount,
    this.followUpFee,
    this.consultationMinutes = 15,
    this.isApolloDoctor = false,
    this.appointmentType = 'presencial',
    this.photoNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'title': title,
      'specialty': specialty,
      'description': description,
      'pricePerAppointment': pricePerAppointment,
      'profileImageUrl': profileImageUrl,
      'rating': rating,
      'reviewCount': reviewCount,
      'yearsExperience': yearsExperience,
      'qualifications': qualifications,
      'languages': languages,
      'distanceKm': distanceKm,
      'city': city,
      'hospital': hospital,
      'patientCount': patientCount,
      'followUpFee': followUpFee,
      'consultationMinutes': consultationMinutes,
      'isApolloDoctor': isApolloDoctor,
      'appointmentType': appointmentType,
      'photoNumber': photoNumber,
    };
  }

  factory Doctor.fromMap(Map<String, dynamic> map, String id) {
    return Doctor(
      id: id,
      name: map['name'] ?? '',
      title: map['title'] ?? '',
      specialty: map['specialty'] ?? '',
      description: map['description'] ?? '',
      pricePerAppointment: (map['pricePerAppointment'] ?? 0).toDouble(),
      profileImageUrl: map['profileImageUrl'],
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      yearsExperience: map['yearsExperience'] ?? 0,
      qualifications: List<String>.from(map['qualifications'] ?? []),
      languages: List<String>.from(map['languages'] ?? []),
      distanceKm: (map['distanceKm'] ?? 0).toDouble(),
      city: map['city'] ?? '',
      hospital: map['hospital'] ?? '',
      patientCount: map['patientCount'],
      followUpFee: map['followUpFee'],
      consultationMinutes: map['consultationMinutes'] ?? 15,
      isApolloDoctor: map['isApolloDoctor'] ?? false,
      appointmentType: map['appointmentType'] ?? 'presencial',
      photoNumber: map['photoNumber'],
    );
  }
}
