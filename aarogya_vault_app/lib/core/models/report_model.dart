class ReportModel {
  final int id;
  final int userId;
  final String title;
  final String date;
  final String type; // Lab, Imaging, Others
  final String status;
  final String fileName;
  final String summary;

  ReportModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.date,
    required this.type,
    required this.status,
    required this.fileName,
    required this.summary,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      type: json['type'] ?? 'Lab',
      status: json['status'] ?? 'Final',
      fileName: json['file_name'] ?? '',
      summary: json['summary'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'date': date,
      'type': type,
      'status': status,
      'file_name': fileName,
      'summary': summary,
    };
  }

  static List<ReportModel> mockList() {
    return [
      ReportModel(
        id: 1,
        userId: 1,
        title: "Blood Report",
        date: "12 Apr 2024",
        type: "Lab",
        status: "Final",
        fileName: "blood_report_20240412.pdf",
        summary: "AI Summary: Hemoglobin, platelets, and white blood cell count are within healthy limits. Fasting glucose is 98 mg/dL. Suggest monitoring sugar intake.",
      ),
      ReportModel(
        id: 2,
        userId: 1,
        title: "X-Ray Chest",
        date: "05 Mar 2024",
        type: "Imaging",
        status: "Final",
        fileName: "chest_xray_20240305.pdf",
        summary: "AI Summary: Normal chest radiograph. Lungs are clear. Cardiac silhouette is of normal size and configuration.",
      ),
      ReportModel(
        id: 3,
        userId: 1,
        title: "MRI Brain",
        date: "22 Feb 2024",
        type: "Imaging",
        status: "Final",
        fileName: "mri_brain_20240222.pdf",
        summary: "AI Summary: Normal MRI of the brain. No intracranial mass, hemorrhage, or acute infarction.",
      ),
      ReportModel(
        id: 4,
        userId: 1,
        title: "ECG Report",
        date: "18 Jan 2024",
        type: "Lab",
        status: "Final",
        fileName: "ecg_report_20240118.pdf",
        summary: "AI Summary: Normal sinus rhythm. Heart rate 72 bpm. Normal electrical axis.",
      ),
      ReportModel(
        id: 5,
        userId: 1,
        title: "CT Scan Abdomen",
        date: "10 Dec 2023",
        type: "Imaging",
        status: "Final",
        fileName: "ct_abdomen_20231210.pdf",
        summary: "AI Summary: Normal CT abdomen. Visualized organs appear healthy with no abnormal masses or structural concerns.",
      ),
    ];
  }
}
