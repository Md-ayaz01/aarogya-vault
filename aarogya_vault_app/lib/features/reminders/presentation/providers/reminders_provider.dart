import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_db.dart';
import '../../../../core/models/reminder_model.dart';
import '../../../../core/models/appointment_model.dart';
import '../../../../core/providers/api_provider.dart';

class RemindersState {
  final List<ReminderModel> reminders;
  final List<AppointmentModel> appointments;
  final bool isLoading;
  final String? error;

  RemindersState({
    this.reminders = const [],
    this.appointments = const [],
    this.isLoading = false,
    this.error,
  });

  RemindersState copyWith({
    List<ReminderModel>? reminders,
    List<AppointmentModel>? appointments,
    bool? isLoading,
    String? error,
  }) {
    return RemindersState(
      reminders: reminders ?? this.reminders,
      appointments: appointments ?? this.appointments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RemindersNotifier extends StateNotifier<RemindersState> {
  final Ref ref;

  RemindersNotifier(this.ref) : super(RemindersState()) {
    _loadFromCache();
  }

  void _loadFromCache() {
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

    state = RemindersState(reminders: reminders, appointments: appointments);
  }

  Future<void> fetchRemindersAndAppointments() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      
      final remindersRes = await client.get('/reminders');
      final remindersList = (remindersRes.data as List)
          .map((i) => ReminderModel.fromJson(i))
          .toList();
      await LocalDB.save(LocalDB.keyReminders, remindersList.map((i) => i.toJson()).toList());
      
      final appointmentsRes = await client.get('/appointments');
      final appointmentsList = (appointmentsRes.data as List)
          .map((i) => AppointmentModel.fromJson(i))
          .toList();
      await LocalDB.save('cached_appointments', appointmentsList.map((i) => i.toJson()).toList());

      state = RemindersState(
        reminders: remindersList,
        appointments: appointmentsList,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addReminder({
    required String name,
    required String dosage,
    required String time,
    required String instruction,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/reminders', data: {
        'medicine_name': name,
        'dosage': dosage,
        'time': time,
        'instruction': instruction,
      });

      if (response.statusCode == 200) {
        final newRem = ReminderModel.fromJson(response.data);
        final updated = [...state.reminders, newRem];
        await LocalDB.save(LocalDB.keyReminders, updated.map((i) => i.toJson()).toList());
        state = state.copyWith(reminders: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleReminder(int reminderId) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.put('/reminders/$reminderId/toggle');
      if (response.statusCode == 200) {
        final updatedRem = ReminderModel.fromJson(response.data);
        final updated = state.reminders.map((r) => r.id == reminderId ? updatedRem : r).toList();
        await LocalDB.save(LocalDB.keyReminders, updated.map((i) => i.toJson()).toList());
        state = state.copyWith(reminders: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateReminderStatus(int reminderId, String status) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.patch('/reminders/$reminderId/status', queryParameters: {'status': status}, data: null);
      if (response.statusCode == 200) {
        final updatedRem = ReminderModel.fromJson(response.data);
        final updated = state.reminders.map((r) => r.id == reminderId ? updatedRem : r).toList();
        await LocalDB.save(LocalDB.keyReminders, updated.map((i) => i.toJson()).toList());
        state = state.copyWith(reminders: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteReminder(int reminderId) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.delete('/reminders/$reminderId');
      if (response.statusCode == 200) {
        final updated = state.reminders.where((r) => r.id != reminderId).toList();
        await LocalDB.save(LocalDB.keyReminders, updated.map((i) => i.toJson()).toList());
        state = state.copyWith(reminders: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> bookAppointment({
    required String doctor,
    required String specialty,
    required String dateTime,
  }) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/appointments', data: {
        'doctor_name': doctor,
        'specialty': specialty,
        'date_time': dateTime,
      });
      if (response.statusCode == 200) {
        final newApp = AppointmentModel.fromJson(response.data);
        final updated = [...state.appointments, newApp];
        await LocalDB.save('cached_appointments', updated.map((i) => i.toJson()).toList());
        state = state.copyWith(appointments: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> cancelAppointment(int appointmentId) async {
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.delete('/appointments/$appointmentId');
      if (response.statusCode == 200) {
        final updated = state.appointments.where((a) => a.id != appointmentId).toList();
        await LocalDB.save('cached_appointments', updated.map((i) => i.toJson()).toList());
        state = state.copyWith(appointments: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final remindersProvider = StateNotifierProvider<RemindersNotifier, RemindersState>((ref) {
  return RemindersNotifier(ref);
});
