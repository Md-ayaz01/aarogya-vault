class MedicalHistoryModel {
  final int id;
  final int userId;
  final String type; // allergy, condition, surgery, vaccination, family, lifestyle
  final String title;
  final String description;
  final String dateRecorded;

  MedicalHistoryModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.dateRecorded,
  });

  factory MedicalHistoryModel.fromJson(Map<String, dynamic> json) {
    return MedicalHistoryModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      type: json['type'] ?? 'condition',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dateRecorded: json['date_recorded'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'description': description,
      'date_recorded': dateRecorded,
    };
  }

  static List<MedicalHistoryModel> mockList() {
    return [
      MedicalHistoryModel(id: 1, userId: 1, type: "condition", title: "Chronic Diseases", description: "No chronic disease diagnosed.", dateRecorded: "2026-05-10"),
      MedicalHistoryModel(id: 2, userId: 1, type: "allergy", title: "Allergies", description: "Penicillin, Pollen", dateRecorded: "2024-03-05"),
      MedicalHistoryModel(id: 3, userId: 1, type: "surgery", title: "Surgeries", description: "Appendectomy (2019)", dateRecorded: "2019-08-20"),
      MedicalHistoryModel(id: 4, userId: 1, type: "family", title: "Family History", description: "Diabetes, Hypertension", dateRecorded: "2025-11-15"),
      MedicalHistoryModel(id: 5, userId: 1, type: "vaccination", title: "Vaccination", description: "Up to date (Hep B, Covid Booster)", dateRecorded: "2025-01-10"),
    ];
  }
}
