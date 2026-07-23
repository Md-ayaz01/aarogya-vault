// lib/infrastructure/repositories/medical_history_repository.dart
import 'package:dio/dio.dart';
import 'package:aarogya_vault_app/models/medical_history.dart';

class MedicalHistoryRepository {
  final Dio dio;

  MedicalHistoryRepository(this.dio);

  Future<MedicalHistory> fetchMedicalHistory() async {
    final response = await dio.get('/medical-history');
    // Assuming the API returns a JSON matching MedicalHistory structure
    return MedicalHistory.fromJson(response.data);
  }
}
