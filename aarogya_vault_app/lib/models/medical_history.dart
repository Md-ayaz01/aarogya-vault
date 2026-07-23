// lib/models/medical_history.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'medical_history.freezed.dart';
part 'medical_history.g.dart';

@freezed
class MedicalHistory with _$MedicalHistory {
  const factory MedicalHistory({
    required List<MedicalRecord> records,
  }) = _MedicalHistory;

  factory MedicalHistory.fromJson(Map<String, dynamic> json) => _$MedicalHistoryFromJson(json);
}

@freezed
class MedicalRecord with _$MedicalRecord {
  const factory MedicalRecord({
    required String id,
    required String title,
    required String description,
    required DateTime date,
    @Default('') String documentUrl, // optional PDF/image
  }) = _MedicalRecord;

  factory MedicalRecord.fromJson(Map<String, dynamic> json) => _$MedicalRecordFromJson(json);
}
