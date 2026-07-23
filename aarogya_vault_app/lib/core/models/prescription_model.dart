class PrescriptionItemModel {
  final String medicineName;
  final String dosage;
  final String instruction; // e.g. 1-0-1 After Food

  PrescriptionItemModel({
    required this.medicineName,
    required this.dosage,
    required this.instruction,
  });

  factory PrescriptionItemModel.fromJson(Map<String, dynamic> json) {
    return PrescriptionItemModel(
      medicineName: json['medicine_name'] ?? '',
      dosage: json['dosage'] ?? '',
      instruction: json['instruction'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'medicine_name': medicineName,
      'dosage': dosage,
      'instruction': instruction,
    };
  }
}

class PrescriptionModel {
  final int id;
  final int userId;
  final String doctorName;
  final String specialty;
  final String date;
  final String diagnosis;
  final String notes;
  final List<PrescriptionItemModel> items;

  PrescriptionModel({
    required this.id,
    required this.userId,
    required this.doctorName,
    required this.specialty,
    required this.date,
    required this.diagnosis,
    required this.notes,
    required this.items,
  });

  factory PrescriptionModel.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List?;
    final itemsList = list != null
        ? list.map((i) => PrescriptionItemModel.fromJson(i)).toList()
        : <PrescriptionItemModel>[];
        
    return PrescriptionModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      doctorName: json['doctor_name'] ?? '',
      specialty: json['specialty'] ?? 'General Physician',
      date: json['date'] ?? '',
      diagnosis: json['diagnosis'] ?? '',
      notes: json['notes'] ?? '',
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'doctor_name': doctorName,
      'specialty': specialty,
      'date': date,
      'diagnosis': diagnosis,
      'notes': notes,
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  static PrescriptionModel mock() {
    return PrescriptionModel(
      id: 1,
      userId: 1,
      doctorName: "Dr. Ravi Sharma",
      specialty: "MBBS, MD (Medicine)\nApollo Hospital, Indore",
      date: "12 Apr 2024",
      diagnosis: "Viral Fever",
      notes: "Take rest and drink plenty of fluids.",
      items: [
        PrescriptionItemModel(medicineName: "Paracetamol 650mg", dosage: "1 Tablet", instruction: "1-0-1 After Food"),
        PrescriptionItemModel(medicineName: "Azithromycin 500mg", dosage: "1 Tablet", instruction: "0-0-1 After Food"),
        PrescriptionItemModel(medicineName: "Cetirizine 10mg", dosage: "1 Tablet", instruction: "0-0-1 Before Sleep"),
      ],
    );
  }
}
