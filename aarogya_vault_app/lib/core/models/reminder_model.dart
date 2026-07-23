class ReminderModel {
  final int id;
  final int userId;
  final String medicineName;
  final String dosage;
  final String time;
  final String instruction;
  final bool isActive;
  final String status; // Taken, Missed, Pending

  ReminderModel({
    required this.id,
    required this.userId,
    required this.medicineName,
    required this.dosage,
    required this.time,
    required this.instruction,
    required this.isActive,
    required this.status,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      medicineName: json['medicine_name'] ?? '',
      dosage: json['dosage'] ?? '',
      time: json['time'] ?? '',
      instruction: json['instruction'] ?? '',
      isActive: json['is_active'] ?? true,
      status: json['status'] ?? 'Pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'medicine_name': medicineName,
      'dosage': dosage,
      'time': time,
      'instruction': instruction,
      'is_active': isActive,
      'status': status,
    };
  }

  static List<ReminderModel> mockList() {
    return [
      ReminderModel(id: 1, userId: 1, medicineName: "Paracetamol", dosage: "650mg", time: "08:00 AM", instruction: "1 Tablet After Food", isActive: true, status: "Taken"),
      ReminderModel(id: 2, userId: 1, medicineName: "Azithromycin", dosage: "500mg", time: "02:00 PM", instruction: "1 Tablet After Food", isActive: true, status: "Pending"),
      ReminderModel(id: 3, userId: 1, medicineName: "Cetirizine", dosage: "10mg", time: "08:00 PM", instruction: "1 Tablet Before Sleep", isActive: true, status: "Pending"),
    ];
  }
}
