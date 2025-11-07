class SpecialistAnswer {
  final String id;
  final String patientName;
  final String patientPhoto;
  final String question;
  final String doctorName;
  final String doctorPhoto;
  final String doctorSpecialty;
  final String answer;
  final String date;

  SpecialistAnswer({
    required this.id,
    required this.patientName,
    required this.patientPhoto,
    required this.question,
    required this.doctorName,
    required this.doctorPhoto,
    required this.doctorSpecialty,
    required this.answer,
    required this.date,
  });

  factory SpecialistAnswer.fromJson(Map<String, dynamic> json) {
    return SpecialistAnswer(
      id: json['id'] as String,
      patientName: json['patientName'] as String,
      patientPhoto: json['patientPhoto'] as String,
      question: json['question'] as String,
      doctorName: json['doctorName'] as String,
      doctorPhoto: json['doctorPhoto'] as String,
      doctorSpecialty: json['doctorSpecialty'] as String,
      answer: json['answer'] as String,
      date: json['date'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patientName': patientName,
      'patientPhoto': patientPhoto,
      'question': question,
      'doctorName': doctorName,
      'doctorPhoto': doctorPhoto,
      'doctorSpecialty': doctorSpecialty,
      'answer': answer,
      'date': date,
    };
  }
}
