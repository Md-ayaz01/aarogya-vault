import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  Map<String, dynamic> _reports = {};

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final res = await _apiClient.get('/hospital/reports/patients');
      final raw = res.data;
      Map<String, dynamic> reports = {};
      if (raw is Map) {
        if (raw.containsKey('data') && raw['data'] is Map) {
          reports = Map<String, dynamic>.from(raw['data']);
        } else {
          reports = Map<String, dynamic>.from(raw);
        }
      }
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _reports = {};
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load Reports: ${e.toString()}"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF006B53);
    const primaryContainer = Color(0xFF00A884);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operational Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchReports,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/reports'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Export Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Administrative Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Real-time performance metrics & institutional health indicators', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Master Hospital Report (PDF & Excel)...')));
                        },
                        icon: const Icon(Icons.download_rounded),
                        label: const Text('EXPORT REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // KPI Bento Grid Cards
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.6,
                    children: [
                      // Hospital Performance
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(backgroundColor: primaryTeal.withValues(alpha: 0.2), child: const Icon(Icons.local_hospital_rounded, color: primaryTeal)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: primaryTeal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('+4.2%', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 10)),
                                  )
                                ],
                              ),
                              const Text('HOSPITAL PERFORMANCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text('${_reports['hospital_performance'] ?? 0}%', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                              const Text('Bed occupancy rate across all departments', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),

                      // Patient Satisfaction
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(backgroundColor: primaryContainer.withValues(alpha: 0.2), child: const Icon(Icons.sentiment_very_satisfied_rounded, color: primaryContainer)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: primaryContainer.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: const Text('HIGH NPS', style: TextStyle(color: primaryContainer, fontWeight: FontWeight.bold, fontSize: 10)),
                                  )
                                ],
                              ),
                              const Text('PATIENT SATISFACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text('${_reports['patient_satisfaction'] ?? 0.0} / 5.0', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryContainer)),
                              const Text('Average NPS score from responses', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),

                      // Financial Health
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  CircleAvatar(backgroundColor: Colors.purple.withValues(alpha: 0.2), child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.purple)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.purple.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                    child: Text('Margin: ${_reports['margin'] ?? 'N/A'}', style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.bold, fontSize: 10)),
                                  )
                                ],
                              ),
                              const Text('FINANCIAL REVENUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                              Text('${_reports['revenue'] ?? '₹0'}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple)),
                              Text('OpEx: ${_reports['opex'] ?? 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Report Downloads List
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Available Executive Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          _reportTile('Monthly IPD / OPD Occupancy Report', 'PDF • 4.2 MB', () {}),
                          _reportTile('Pharmacy Stock & Supplier Reorder Log', 'Excel • 1.8 MB', () {}),
                          _reportTile('Gemini AI Clinical Risk Assessment', 'PDF • 8.5 MB', () {}),
                          _reportTile('RBAC System Security Audit Trail', 'CSV • 620 KB', () {}),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _reportTile(String title, String meta, VoidCallback onDownload) {
    const primaryTeal = Color(0xFF006B53);
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf_rounded, color: primaryTeal),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Text(meta, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: IconButton(
        icon: const Icon(Icons.download_rounded, color: primaryTeal),
        onPressed: onDownload,
      ),
    );
  }
}
