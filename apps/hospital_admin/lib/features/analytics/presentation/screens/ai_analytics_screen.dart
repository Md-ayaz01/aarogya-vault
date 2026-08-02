import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class AIAnalyticsScreen extends StatefulWidget {
  const AIAnalyticsScreen({super.key});

  @override
  State<AIAnalyticsScreen> createState() => _AIAnalyticsScreenState();
}

class _AIAnalyticsScreenState extends State<AIAnalyticsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic> _insights = {};

  @override
  void initState() {
    super.initState();
    _fetchAIInsights();
  }

  Future<void> _fetchAIInsights() async {
    try {
      final res = await _apiClient.get('/hospital/analytics/ai-insights');
      final raw = res.data;
      Map<String, dynamic> insights = {};
      if (raw is Map) {
        if (raw.containsKey('data') && raw['data'] is Map) {
          insights = Map<String, dynamic>.from(raw['data']);
        } else {
          insights = Map<String, dynamic>.from(raw);
        }
      }
      setState(() {
        _insights = insights;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _insights = {};
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load AI Insights: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);
    const primaryContainer = Color(0xFF00A884);
    const activeGreen = Color(0xFF79F9D0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Performance & Clinical Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchAIInsights,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/analytics'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Action Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Performance Insights', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Real-time heuristic analysis & predictive risk modeling', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting AI Operational Report PDF...')));
                        },
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('EXPORT PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Top KPI Cards Grid
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _bentoCard('AVG READMISSION', '${_insights['readmission_rate'] ?? 0}%', 'Risk Adjusted', primaryTeal, Icons.replay_rounded),
                      _bentoCard('MORTALITY INDEX', '${_insights['mortality_index'] ?? 0.0}', 'Risk Adjusted', Colors.purple, Icons.analytics_rounded),
                      _bentoCard('BED TURNOVER', '${_insights['bed_turnover_days'] ?? 0} Days', 'Per Patient', Colors.blue, Icons.bed_rounded),
                      _bentoCard('AI EFFICIENCY', '${_insights['ai_efficiency_score'] ?? 0}%', 'System Health', primaryContainer, Icons.auto_awesome_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Operational Strategy AI Copilot Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryTeal,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.psychology_rounded, color: activeGreen, size: 28),
                            SizedBox(width: 10),
                            Text('Operational Strategy AI Copilot', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '"${_insights['recommendation'] ?? 'Analyzing clinical trends...'}"',
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic, height: 1.4),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(Icons.auto_awesome_rounded, color: activeGreen, size: 16),
                            SizedBox(width: 6),
                            Text('Powered by Google Gemini Clinical AI', style: TextStyle(color: activeGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _bentoCard(String label, String val, String sub, Color color, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.grey)),
                Icon(icon, color: color, size: 20),
              ],
            ),
            Text(val, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
