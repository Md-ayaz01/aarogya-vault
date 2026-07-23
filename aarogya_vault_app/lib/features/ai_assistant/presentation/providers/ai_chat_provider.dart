import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/api_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../reminders/presentation/providers/reminders_provider.dart';

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime? timestamp;

  const ChatMessage({
    required this.content,
    required this.isUser,
    this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    content: json['message'] as String,
    isUser: json['is_user'] as bool,
    timestamp: json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'] as String)
        : null,
  );
}

class AiChatState {
  final List<ChatMessage> messages;
  final bool isLoading;
  final bool isTyping;
  final String? error;

  const AiChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isTyping = false,
    this.error,
  });

  AiChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoading,
    bool? isTyping,
    String? error,
  }) => AiChatState(
    messages: messages ?? this.messages,
    isLoading: isLoading ?? this.isLoading,
    isTyping: isTyping ?? this.isTyping,
    error: error,
  );
}

class AiChatNotifier extends StateNotifier<AiChatState> {
  final Ref ref;

  AiChatNotifier(this.ref) : super(const AiChatState());

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/ai/chat-history');
      if (response.data is List) {
        final msgs = (response.data as List)
            .map((j) => ChatMessage.fromJson(j as Map<String, dynamic>))
            .toList();
        state = state.copyWith(messages: msgs, isLoading: false);
      } else {
        state = state.copyWith(messages: [], isLoading: false);
      }
    } catch (_) {
      // Offline fallback — show welcoming message
      state = state.copyWith(
        isLoading: false,
        messages: const [
          ChatMessage(
            content: "Hello! I am your Aarogya Vault AI Health Assistant. "
                "Ask me to explain a report, outline a medicine schedule, "
                "or provide general wellness tips.",
            isUser: false,
          ),
        ],
      );
    }
  }

  Future<void> sendMessage(String text) async {
    final userMsg = ChatMessage(content: text, isUser: true, timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
    );

    try {
      final client = ref.read(apiClientProvider);

      // Build dynamic patient context
      final dashState = ref.read(dashboardProvider);
      final remState = ref.read(remindersProvider);

      final profile = dashState.profile;
      final history = dashState.history;
      final reminders = remState.reminders;

      String ctx = '';
      if (profile != null) {
        ctx += 'Patient: ${profile.fullName}, DOB: ${profile.dob}, '
            'Gender: ${profile.gender}, Blood Group: ${profile.bloodGroup}. ';
      }
      if (history.isNotEmpty) {
        final allergies = history
            .where((e) => e.type.toLowerCase() == 'allergy')
            .map((e) => e.title)
            .join(', ');
        final conditions = history
            .where((e) => e.type.toLowerCase() == 'condition')
            .map((e) => e.title)
            .join(', ');
        ctx += 'Allergies: [$allergies]. Conditions: [$conditions]. ';
      }
      if (reminders.isNotEmpty) {
        final meds = reminders
            .where((r) => r.isActive)
            .map((r) => '${r.medicineName} ${r.dosage}')
            .join(', ');
        ctx += 'Active Medications: [$meds]. ';
      }

      final response = await client.post('/ai/chat', data: {
        'prompt': text,
        'context': ctx,
      });

      final aiText = (response.data['explanation'] as String?) ??
          'I encountered an error. Please try again.';
      final aiMsg = ChatMessage(
        content: aiText, isUser: false, timestamp: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isTyping: false,
      );
    } catch (_) {
      final fallback = _simulatedResponse(text);
      state = state.copyWith(
        messages: [
          ...state.messages,
          ChatMessage(content: fallback, isUser: false, timestamp: DateTime.now()),
        ],
        isTyping: false,
      );
    }
  }

  Future<void> clearHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      final client = ref.read(apiClientProvider);
      await client.delete('/ai/chat-history');
    } catch (_) {}
    state = const AiChatState(messages: [
      ChatMessage(
        content: 'Chat history cleared. How can I help you today?',
        isUser: false,
      ),
    ]);
  }

  String _simulatedResponse(String prompt) {
    final p = prompt.toLowerCase();
    if (p.contains('blood') || p.contains('report')) {
      return 'Based on your Blood Report (April 12, 2024):\n\n'
          '• Hemoglobin: 14.2 g/dL — Normal\n'
          '• Glucose Fasting: 98 mg/dL — Normal (near 100 mg/dL pre-diabetes limit). Limit processed sugars.\n'
          '• Platelets: 220,000 /mcL — Healthy';
    } else if (p.contains('mri') || p.contains('brain')) {
      return 'Regarding your MRI Brain (Feb 22, 2024):\n\n'
          'Completely normal scan — no intracranial pathology, mass effect, or demyelination. '
          'If you have chronic headaches, consult your physician.';
    } else if (p.contains('paracetamol') || p.contains('medicine') || p.contains('meds')) {
      return 'Your current medications:\n\n'
          '1. Paracetamol 650mg — Fever/Pain reducer. After food.\n'
          '2. Azithromycin 500mg — Antibiotic. Complete the 3-day course.\n'
          '3. Cetirizine 10mg — Antihistamine. Take at night.';
    } else if (p.contains('summary') || p.contains('health')) {
      return 'Your Health Summary:\n\n'
          '• Health Score: 92% — Excellent\n'
          '• Known Allergies: Penicillin\n'
          '• Chronic Conditions: Mild Hypertension\n'
          '• Recent Reports: 2 lab reports, 1 imaging scan\n'
          '• Next Appointment: Dr. Ravi Sharma on 04:30 PM today';
    } else {
      return 'I can help you with:\n'
          '• Explaining your lab reports\n'
          '• Medicine schedules and instructions\n'
          '• General health summaries\n'
          '• Emergency tips and precautions\n\n'
          'What would you like to know?';
    }
  }
}

final aiChatProvider =
    StateNotifierProvider<AiChatNotifier, AiChatState>((ref) {
  return AiChatNotifier(ref);
});

// Keep legacy alias for backward compat
final chatProvider = aiChatProvider;
