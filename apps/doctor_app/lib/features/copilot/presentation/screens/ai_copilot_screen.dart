import 'package:flutter/material.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';

class AICopilotScreen extends StatefulWidget {
  final int patientId;
  const AICopilotScreen({Key? key, required this.patientId}) : super(key: key);

  @override
  State<AICopilotScreen> createState() => _AICopilotScreenState();
}

class _AICopilotScreenState extends State<AICopilotScreen> {
  final _queryController = TextEditingController();
  bool _isLoading = false;
  String? _copilotResponse;
  String? _errorMessage;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _fetchCopilotResponse(String prompt, String type) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _copilotResponse = null;
    });

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post('/doctor/ai/copilot', data: {
        'patient_id': widget.patientId,
        'prompt': prompt,
        'type': type
      });
      setState(() {
        _copilotResponse = response.data['insight'] as String?;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "AI Engine failure. Please repeat or verify query.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Doctor Copilot'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Clinical Presets
              Text(
                'Clinical Helpers',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip("Patient Summary", "Summarize entire medical profile", "summary"),
                    const SizedBox(width: 8),
                    _buildPresetChip("Allergies & Interactions", "Check drug allergy warnings", "interaction"),
                    const SizedBox(width: 8),
                    _buildPresetChip("SOAP Note", "Generate SOAP visit note structure", "soap"),
                    const SizedBox(width: 8),
                    _buildPresetChip("Follow-ups", "Suggest treatment follow-up paths", "followup"),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Query Input Box
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _queryController,
                      decoration: const InputDecoration(
                        labelText: 'Ask Copilot a Clinical Question...',
                        prefixIcon: Icon(Icons.psychology_outlined),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) {
                          _fetchCopilotResponse(val.trim(), "custom");
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: () {
                      final val = _queryController.text.trim();
                      if (val.isNotEmpty) {
                        _fetchCopilotResponse(val, "custom");
                      }
                    },
                    icon: const Icon(Icons.send_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.all(16),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // Copilot Response Box
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Copilot is analyzing medical records...'),
                              ],
                            ),
                          )
                        : _errorMessage != null
                            ? Center(
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                                ),
                              )
                            : _copilotResponse != null
                                ? SingleChildScrollView(
                                    child: Text(
                                      _copilotResponse!,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        height: 1.5,
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Text(
                                      'Select a preset helper above or ask a clinical question to get AI-assisted decision support.',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String prompt, String type) {
    return ActionChip(
      avatar: const Icon(Icons.auto_awesome_rounded, size: 16),
      label: Text(label),
      onPressed: () => _fetchCopilotResponse(prompt, type),
    );
  }
}
