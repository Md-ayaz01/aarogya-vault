import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class LaboratoryScreen extends StatefulWidget {
  const LaboratoryScreen({super.key});

  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends State<LaboratoryScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _labOrders = [];
  String _selectedCategory = "ALL";

  @override
  void initState() {
    super.initState();
    _fetchLabOrders();
  }

  Future<void> _fetchLabOrders() async {
    try {
      final res = await _apiClient.get('/hospital/laboratory');
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = List<dynamic>.from(raw['data']);
      }
      setState(() {
        _labOrders = list;
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _labOrders = [];
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
    const primaryContainer = Color(0xFF00A884);

    final filteredOrders = _selectedCategory == "ALL"
        ? _labOrders
        : _labOrders.where((l) => l['category'].toString().toUpperCase() == _selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratory Diagnostics & Processing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchLabOrders,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/laboratory'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Title Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Laboratory Worklist', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Real-time automated tracking & clinical diagnostics', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showUploadDialog(context),
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('UPLOAD REPORT', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Bento Grid Stats Cards
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _bentoCard('PENDING TESTS', '${_labOrders.where((l) => l['status'] == "Pending").length} Tests', '${_labOrders.where((l) => l['stat_priority'] == true).length} STAT Priority', Colors.orange, Icons.pending_actions_rounded),
                      _bentoCard('COMPLETED TODAY', '${_labOrders.where((l) => l['status'] == "Completed" || l['status'] == "Uploaded & Verified").length} Done', 'In-house Diagnostics', primaryContainer, Icons.check_circle_rounded),
                      _bentoCard('TOTAL ORDERS', '${_labOrders.length} Orders', 'Registered Tests', Colors.blue, Icons.timer_rounded),
                      _bentoCard('EQUIPMENT STATUS', 'Optimal', 'Operational', primaryTeal, Icons.settings_input_component_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _categoryChip('ALL', 'ALL TESTS'),
                        _categoryChip('HEMATOLOGY', 'HEMATOLOGY'),
                        _categoryChip('PATHOLOGY', 'PATHOLOGY'),
                        _categoryChip('ENDOCRINOLOGY', 'ENDOCRINOLOGY'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lab Orders List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, idx) {
                      final lab = filteredOrders[idx];
                      final isDone = lab['status'] == "Completed";
                      final isStat = lab['stat_priority'] == true;
                      final statusColor = isDone ? primaryContainer : (isStat ? Colors.red : Colors.orange);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.2),
                            child: Icon(Icons.biotech_rounded, color: statusColor),
                          ),
                          title: Row(
                            children: [
                              Text(lab['test_name'] ?? 'Diagnostic Test', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (isStat) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                  child: const Text('STAT URGENT', style: TextStyle(color: Colors.red, fontSize: 9, fontWeight: FontWeight.bold)),
                                )
                              ]
                            ],
                          ),
                          subtitle: Text('Patient: ${lab['patient_name']}\nResults: ${lab['results']}'),
                          isThreeLine: true,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                            child: Text(
                              lab['status'] ?? 'Pending',
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
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
            Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(sub, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(String key, String title) {
    final isSelected = _selectedCategory == key;
    const primaryTeal = Color(0xFF006B53);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        selected: isSelected,
        selectedColor: primaryTeal,
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
        onSelected: (val) {
          if (val) setState(() => _selectedCategory = key);
        },
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    final testCtrl = TextEditingController();
    final patientCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload Digital Diagnostic Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.upload_file_rounded, size: 48, color: Color(0xFF006B53)),
            const SizedBox(height: 8),
            TextField(controller: testCtrl, decoration: const InputDecoration(labelText: 'Test Name (e.g. CBC / Lipid Profile)')),
            const SizedBox(height: 8),
            TextField(controller: patientCtrl, decoration: const InputDecoration(labelText: 'Patient Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (testCtrl.text.isEmpty || patientCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter test and patient name')));
                return;
              }
              try {
                final res = await _apiClient.post('/hospital/laboratory', data: {
                  'test_name': testCtrl.text,
                  'patient_name': patientCtrl.text,
                  'category': 'PATHOLOGY',
                  'results': 'Uploaded & Verified',
                  'stat_priority': false
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  if (res.data != null && res.data['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Diagnostic report uploaded successfully!')));
                    _fetchLabOrders();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload report')));
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading report: ${e.toString()}'), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('UPLOAD'),
          )
        ],
      ),
    );
  }
}
