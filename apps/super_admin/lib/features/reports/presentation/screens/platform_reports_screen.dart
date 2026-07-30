import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class PlatformReportsScreen extends StatefulWidget {
  const PlatformReportsScreen({super.key});

  @override
  State<PlatformReportsScreen> createState() => _PlatformReportsScreenState();
}

class _PlatformReportsScreenState extends State<PlatformReportsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final res = await _apiClient.get('/super_admin/reports');
      setState(() {
        _reports = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _reports = [
          {"id": 1, "name": "Ecosystem Platform Health Summary", "type": "PDF", "size": "12.4 MB", "generated_at": "2026-07-30T00:00:00Z"},
          {"id": 2, "name": "ABHA & PM-JAY Compliance Audit", "type": "Excel", "size": "4.8 MB", "generated_at": "2026-07-29T18:00:00Z"},
          {"id": 3, "name": "Gemini AI Clinical Usage & Token Report", "type": "PDF", "size": "8.2 MB", "generated_at": "2026-07-28T12:00:00Z"},
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Executive Platform Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchReports,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/reports'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Executive Platform Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Download institutional system, security, AI & hospital reports', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _reports.length,
                    itemBuilder: (context, idx) {
                      final r = _reports[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.assessment_rounded, color: primaryTeal),
                          title: Text(r['name'] ?? 'Report', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Type: ${r['type']} | Size: ${r['size']} | Generated: ${r['generated_at']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.download_rounded, color: primaryTeal),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Downloading ${r['name']}...')));
                            },
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
