import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class AIControlScreen extends StatefulWidget {
  const AIControlScreen({super.key});

  @override
  State<AIControlScreen> createState() => _AIControlScreenState();
}

class _AIControlScreenState extends State<AIControlScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _configs = [];

  @override
  void initState() {
    super.initState();
    _fetchAIConfigs();
  }

  Future<void> _fetchAIConfigs() async {
    try {
      final res = await _apiClient.get('/super_admin/ai-control');
      setState(() {
        _configs = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _configs = [];
      _isLoading = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to load data from server: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);
    const activeGreen = Color(0xFF79F9D0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Gemini AI Control Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAIConfigs,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/ai-control'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Model Configurations', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Configure Gemini AI models, prompt templates & token limits', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _configs.length,
                    itemBuilder: (context, idx) {
                      final cfg = _configs[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.psychology_rounded, color: primaryTeal),
                                      const SizedBox(width: 8),
                                      Text(cfg['model_name'] ?? 'Gemini Model', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    ],
                                  ),
                                  Switch(
                                    value: cfg['is_active'] == true,
                                    activeThumbColor: activeGreen,
                                    onChanged: (val) {},
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('System Prompt: "${cfg['system_prompt']}"', style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Chip(label: Text('Temp: ${cfg['temperature']}')),
                                  const SizedBox(width: 8),
                                  Chip(label: Text('Max Tokens: ${cfg['max_tokens']}')),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
    );
  }
}
