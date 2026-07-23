import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_db.dart';
import '../../../../core/models/prescription_model.dart';
import '../../../../core/providers/api_provider.dart';

class PrescriptionsState {
  final List<PrescriptionModel> prescriptions;
  final bool isLoading;
  final String? error;

  PrescriptionsState({
    this.prescriptions = const [],
    this.isLoading = false,
    this.error,
  });

  PrescriptionsState copyWith({
    List<PrescriptionModel>? prescriptions,
    bool? isLoading,
    String? error,
  }) {
    return PrescriptionsState(
      prescriptions: prescriptions ?? this.prescriptions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class PrescriptionsNotifier extends StateNotifier<PrescriptionsState> {
  final Ref ref;

  PrescriptionsNotifier(this.ref) : super(PrescriptionsState()) {
    _loadFromCache();
  }

  void _loadFromCache() {
    final cached = LocalDB.get('cached_prescriptions');
    List<PrescriptionModel> list = [];
    if (cached != null) {
      list = (cached as List)
          .map((i) => PrescriptionModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }
    state = PrescriptionsState(prescriptions: list);
  }

  Future<void> fetchPrescriptions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/prescriptions');
      if (response.statusCode == 200) {
        final list = (response.data as List)
            .map((i) => PrescriptionModel.fromJson(i))
            .toList();
        await LocalDB.save('cached_prescriptions', list.map((i) => i.toJson()).toList());
        state = PrescriptionsState(prescriptions: list, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> addPrescription(PrescriptionModel prescription) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/prescriptions', data: prescription.toJson());
      if (response.statusCode == 200) {
        final newPres = PrescriptionModel.fromJson(response.data);
        final list = [...state.prescriptions, newPres];
        await LocalDB.save('cached_prescriptions', list.map((i) => i.toJson()).toList());
        state = state.copyWith(prescriptions: list);
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }

  Future<bool> deletePrescription(int id) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.delete('/prescriptions/$id');
      if (response.statusCode == 200) {
        final list = state.prescriptions.where((p) => p.id != id).toList();
        await LocalDB.save('cached_prescriptions', list.map((i) => i.toJson()).toList());
        state = state.copyWith(prescriptions: list);
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }
}

final prescriptionsProvider = StateNotifierProvider<PrescriptionsNotifier, PrescriptionsState>((ref) {
  return PrescriptionsNotifier(ref);
});
