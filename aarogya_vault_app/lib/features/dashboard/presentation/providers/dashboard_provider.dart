import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_db.dart';
import '../../../../core/models/profile_model.dart';
import '../../../../core/models/medical_history_model.dart';
import '../../../../core/models/reminder_model.dart';
import '../../../../core/models/appointment_model.dart';
import '../../../../core/providers/api_provider.dart';

class DashboardState {
  final ProfileModel? profile;
  final List<MedicalHistoryModel> history;
  final List<dynamic> reminders;
  final List<dynamic> appointments;
  final bool isLoading;
  final String? error;

  DashboardState({
    this.profile,
    this.history = const [],
    this.reminders = const [],
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    ProfileModel? profile,
    List<MedicalHistoryModel>? history,
    List<dynamic>? reminders,
    List<dynamic>? appointments,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      profile: profile ?? this.profile,
      history: history ?? this.history,
      reminders: reminders ?? this.reminders,
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref ref;

  DashboardNotifier(this.ref) : super(DashboardState()) {
    // Attempt to load from offline cache first
    _loadFromCache();
  }

  void _loadFromCache() {
    final cachedProfile = LocalDB.get(LocalDB.keyProfile);
    final cachedHistory = LocalDB.get(LocalDB.keyHistory);

    ProfileModel? profile;
    List<MedicalHistoryModel> history = [];

    if (cachedProfile != null) {
      profile = ProfileModel.fromJson(Map<String, dynamic>.from(cachedProfile));
    }

    if (cachedHistory != null) {
      history = (cachedHistory as List)
          .map((i) => MedicalHistoryModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    final cachedReminders = LocalDB.get(LocalDB.keyReminders);
    List<ReminderModel> reminders = [];
    if (cachedReminders != null) {
      reminders = (cachedReminders as List)
          .map((i) => ReminderModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    final cachedAppointments = LocalDB.get('cached_appointments');
    List<AppointmentModel> appointments = [];
    if (cachedAppointments != null) {
      appointments = (cachedAppointments as List)
          .map((i) => AppointmentModel.fromJson(Map<String, dynamic>.from(i)))
          .toList();
    }

    state = DashboardState(
      profile: profile, 
      history: history,
      reminders: reminders,
      appointments: appointments,
    );
  }

  // Alias for compatibility
  Future<void> loadDashboard() => fetchDashboardData();

  Future<void> fetchDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      
      // Fetch Profile
      final profileRes = await client.get('/profile');
      final profile = ProfileModel.fromJson(profileRes.data);
      await LocalDB.save(LocalDB.keyProfile, profile.toJson());
      
      // Fetch History
      final historyRes = await client.get('/profile/medical-history');
      final history = (historyRes.data as List)
          .map((i) => MedicalHistoryModel.fromJson(i))
          .toList();
      await LocalDB.save(LocalDB.keyHistory, history.map((i) => i.toJson()).toList());

      // Fetch Reminders
      List<ReminderModel> reminders = [];
      try {
        final remindersRes = await client.get('/reminders');
        reminders = (remindersRes.data as List)
            .map((i) => ReminderModel.fromJson(i))
            .toList();
        await LocalDB.save(LocalDB.keyReminders, reminders.map((i) => i.toJson()).toList());
      } catch (e) {
        final cached = LocalDB.get(LocalDB.keyReminders);
        if (cached != null) {
          reminders = (cached as List)
              .map((i) => ReminderModel.fromJson(Map<String, dynamic>.from(i)))
              .toList();
        }
      }

      // Fetch Appointments
      List<AppointmentModel> appointments = [];
      try {
        final appointmentsRes = await client.get('/appointments');
        appointments = (appointmentsRes.data as List)
            .map((i) => AppointmentModel.fromJson(i))
            .toList();
        await LocalDB.save('cached_appointments', appointments.map((i) => i.toJson()).toList());
      } catch (e) {
        final cached = LocalDB.get('cached_appointments');
        if (cached != null) {
          appointments = (cached as List)
              .map((i) => AppointmentModel.fromJson(Map<String, dynamic>.from(i)))
              .toList();
        }
      }

      state = DashboardState(
        profile: profile, 
        history: history, 
        reminders: reminders,
        appointments: appointments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addHistoryItem(String type, String title, String description) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/profile/medical-history', data: {
        'type': type,
        'title': title,
        'description': description,
        'date_recorded': DateTime.now().toString().split(' ')[0],
      });
      
      if (response.statusCode == 200) {
        final newItem = MedicalHistoryModel.fromJson(response.data);
        final updatedList = [...state.history, newItem];
        await LocalDB.save(LocalDB.keyHistory, updatedList.map((i) => i.toJson()).toList());
        state = state.copyWith(history: updatedList);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> updateProfile({
    required String fullName,
    required String dob,
    required String gender,
    required String bloodGroup,
    required String address,
    required String emergencyContactName,
    required String emergencyContactPhone,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.put('/profile', data: {
        'full_name': fullName,
        'dob': dob,
        'gender': gender,
        'blood_group': bloodGroup,
        'address': address,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
      });
      
      if (response.statusCode == 200) {
        final updatedProfile = ProfileModel.fromJson(response.data);
        await LocalDB.save(LocalDB.keyProfile, updatedProfile.toJson());
        state = state.copyWith(profile: updatedProfile);
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }

  Future<bool> deleteHistoryItem(int itemId) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.delete('/profile/medical-history/$itemId');
      if (response.statusCode == 200) {
        final updatedList = state.history.where((item) => item.id != itemId).toList();
        await LocalDB.save(LocalDB.keyHistory, updatedList.map((i) => i.toJson()).toList());
        state = state.copyWith(history: updatedList);
        return true;
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
    return false;
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});
