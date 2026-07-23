import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_db.dart';
import '../../../../core/models/report_model.dart';
import '../../../../core/models/prescription_model.dart';
import '../../../../core/providers/api_provider.dart';

class ReportsState {
  final List<ReportModel> reports;
  final PrescriptionModel? prescription;
  final bool isLoading;
  final String? error;
  final Map<int, String> reportExplanations; // reportId -> AI explanation

  ReportsState({
    this.reports = const [],
    this.prescription,
    this.isLoading = false,
    this.error,
    this.reportExplanations = const {},
  });

  ReportsState copyWith({
    List<ReportModel>? reports,
    PrescriptionModel? prescription,
    bool? isLoading,
    String? error,
    Map<int, String>? reportExplanations,
  }) {
    return ReportsState(
      reports: reports ?? this.reports,
      prescription: prescription ?? this.prescription,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      reportExplanations: reportExplanations ?? this.reportExplanations,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final Ref ref;

  ReportsNotifier(this.ref) : super(ReportsState()) {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cachedReports = LocalDB.get(LocalDB.keyReports);
    List<ReportModel> reports = [];
    if (cachedReports != null) {
      reports = (cachedReports as List)
          .map((i) => ReportModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    state = ReportsState(reports: reports, prescription: null);
  }

  Future<void> fetchReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      
      // Fetch Reports
      final reportsRes = await client.get('/reports');
      final reportsList = (reportsRes.data as List)
          .map((i) => ReportModel.fromJson(i))
          .toList();
      await LocalDB.save(LocalDB.keyReports, reportsList.map((i) => i.toJson()).toList());
      
      state = state.copyWith(reports: reportsList, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> uploadReport({
    required String title,
    required String date,
    required String type,
    String? filePath,
    List<int>? bytes,
    String? fileName,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.uploadFile(
        '/reports/upload',
        filePath,
        title,
        date,
        type,
        bytes: bytes,
        fileName: fileName,
      );
      
      if (response.statusCode == 200) {
        final newReport = ReportModel.fromJson(response.data);
        final updatedList = [newReport, ...state.reports];
        await LocalDB.save(LocalDB.keyReports, updatedList.map((i) => i.toJson()).toList());
        state = state.copyWith(reports: updatedList, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<String> getReportExplanation(int reportId) async {
    if (state.reportExplanations.containsKey(reportId)) {
      return state.reportExplanations[reportId]!;
    }
    
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/ai/explain-report/$reportId');
      final explanation = response.data['explanation'];
      
      final updatedExplanations = Map<int, String>.from(state.reportExplanations);
      updatedExplanations[reportId] = explanation;
      state = state.copyWith(reportExplanations: updatedExplanations);
      return explanation;
    } catch (e) {
      final explanation = "AI Report Explanation is currently unavailable.";
      return explanation;
    }
  }

  Future<bool> deleteReport(int reportId) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.delete('/reports/$reportId');
      if (response.statusCode == 200) {
        final updatedList = state.reports.where((r) => r.id != reportId).toList();
        await LocalDB.save(LocalDB.keyReports, updatedList.map((i) => i.toJson()).toList());
        state = state.copyWith(reports: updatedList);
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier(ref);
});
