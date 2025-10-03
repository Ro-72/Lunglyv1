import 'package:cloud_firestore/cloud_firestore.dart';

class Doctor {
  final String id;
  final String name;
  final String title;
  final String specialty;
  final String description;
  final double pricePerAppointment;
  final String? profileImageUrl;
  final List<String> availableDays;
  final double rating;
  final int reviewCount;

  Doctor({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.description,
    required this.pricePerAppointment,
    this.profileImageUrl,
    this.availableDays = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'title': title,
      'specialty': specialty,
      'description': description,
      'pricePerAppointment': pricePerAppointment,
      'profileImageUrl': profileImageUrl,
      'availableDays': availableDays,
      'rating': rating,
      'reviewCount': reviewCount,
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
      availableDays: List<String>.from(map['availableDays'] ?? []),
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
    );
  }
}
