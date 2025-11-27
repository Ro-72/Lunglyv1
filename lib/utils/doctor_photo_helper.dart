class DoctorPhotoHelper {
  static String getDoctorPhotoPath(int? photoNumber) {
    if (photoNumber == null || photoNumber < 1 || photoNumber > 5) {
      // Si no hay número o está fuera de rango, usar foto por defecto
      return 'assets/photos/doctor1.jpg';
    }
    return 'assets/photos/doctor$photoNumber.jpg';
  }

  static String getDoctorPhotoPathForDoctor(String? profileImageUrl, int? photoNumber) {
    // Si tiene URL de imagen de perfil (de internet), usar esa
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      return profileImageUrl;
    }

    // Si no, usar la foto local basada en photoNumber
    return getDoctorPhotoPath(photoNumber);
  }
}
