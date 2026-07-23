class AppointmentModel {
  final int id;
  final int userId;
  final String doctorName;
  final String specialty;
  final String dateTime; // YYYY-MM-DD HH:MM
  final String status; // Upcoming, Completed, Cancelled

  AppointmentModel({
    required this.id,
    required this.userId,
    required this.doctorName,
    required this.specialty,
    required this.dateTime,
    required this.status,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      doctorName: json['doctor_name'] ?? '',
      specialty: json['specialty'] ?? '',
      dateTime: json['date_time'] ?? '',
      status: json['status'] ?? 'Upcoming',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'doctor_name': doctorName,
      'specialty': specialty,
      'date_time': dateTime,
      'status': status,
    };
  }

  static List<AppointmentModel> mockList() {
    return [
      AppointmentModel(id: 1, userId: 1, doctorName: "Dr. Ravi Sharma", specialty: "Cardiologist", dateTime: "2026-07-20 10:00 AM", status: "Upcoming"),
      AppointmentModel(id: 2, userId: 1, doctorName: "Dr. Ananya Goel", specialty: "Dermatologist", dateTime: "2026-07-10 04:30 PM", status: "Completed"),
    ];
  }
}
