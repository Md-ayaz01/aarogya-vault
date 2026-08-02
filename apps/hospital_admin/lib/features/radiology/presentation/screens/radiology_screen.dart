import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class RadiologyScreen extends StatefulWidget {
  const RadiologyScreen({super.key});

  @override
  State<RadiologyScreen> createState() => _RadiologyScreenState();
}

class _RadiologyScreenState extends State<RadiologyScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _radiologyOrders = [];
  String _selectedModality = "ALL";

  @override
  void initState() {
    super.initState();
    _fetchRadiologyOrders();
  }

  Future<void> _fetchRadiologyOrders() async {
    try {
      final res = await _apiClient.get('/hospital/radiology');
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = List<dynamic>.from(raw['data']);
      }
      setState(() {
        _radiologyOrders = list;
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _radiologyOrders = [];
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

    final filteredScans = _selectedModality == "ALL"
        ? _radiologyOrders
        : _radiologyOrders.where((r) => r['modality'].toString().toUpperCase() == _selectedModality).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radiology & Diagnostic Imaging'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchRadiologyOrders,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/radiology'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Header Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Radiology & Imaging', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Diagnostic intelligence & image management system', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showUploadImagingDialog(context),
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: const Text('UPLOAD IMAGING', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Modality Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _modalityChip('ALL', 'ALL SCANS'),
                        _modalityChip('MRI', 'MRI SCANS'),
                        _modalityChip('CT', 'CT SCANS'),
                        _modalityChip('X-RAY', 'X-RAY'),
                        _modalityChip('ULTRASOUND', 'ULTRASOUND'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Scans Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: filteredScans.length,
                    itemBuilder: (context, idx) {
                      final scan = filteredScans[idx];
                      final isCrit = scan['status'] == "Critical";
                      final badgeColor = isCrit ? Colors.red : (scan['status'] == "Stable" ? primaryContainer : Colors.blue);

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: badgeColor.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Icon(
                                      scan['modality'] == "MRI" || scan['modality'] == "CT"
                                          ? Icons.psychology_rounded
                                          : Icons.monitor_weight_rounded,
                                      color: Colors.white70,
                                      size: 50,
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(4)),
                                      child: Text(scan['scan_code'] ?? 'SCAN_01', style: const TextStyle(color: Colors.white, fontSize: 10, fontFamily: 'monospace')),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(scan['patient_name'] ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                                        child: Text(scan['status'] ?? 'Routine', style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10)),
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('${scan['modality']} - ${scan['body_part']}', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                                  const SizedBox(height: 2),
                                  Text('Findings: ${scan['findings']}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  )
                ],
              ),
            ),
    );
  }

  Widget _modalityChip(String key, String title) {
    final isSelected = _selectedModality == key;
    const primaryTeal = Color(0xFF006B53);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        selected: isSelected,
        selectedColor: primaryTeal,
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
        onSelected: (val) {
          if (val) setState(() => _selectedModality = key);
        },
      ),
    );
  }

  void _showUploadImagingDialog(BuildContext context) {
    final modCtrl = TextEditingController(text: 'MRI');
    final partCtrl = TextEditingController(text: 'Brain');
    final patientCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Upload DICOM / Radiology Scan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_upload_rounded, size: 48, color: Color(0xFF006B53)),
            const SizedBox(height: 8),
            TextField(controller: modCtrl, decoration: const InputDecoration(labelText: 'Modality (MRI, CT, X-RAY, ULTRASOUND)')),
            const SizedBox(height: 8),
            TextField(controller: partCtrl, decoration: const InputDecoration(labelText: 'Body Part')),
            const SizedBox(height: 8),
            TextField(controller: patientCtrl, decoration: const InputDecoration(labelText: 'Patient Name')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (patientCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter patient name')));
                return;
              }
              try {
                final res = await _apiClient.post('/hospital/radiology', data: {
                  'modality': modCtrl.text,
                  'body_part': partCtrl.text,
                  'patient_name': patientCtrl.text,
                  'scan_code': 'RAD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                  'findings': 'Clear / Unremarkable',
                  'status': 'Routine'
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  if (res.data != null && res.data['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Radiology scan uploaded successfully!')));
                    _fetchRadiologyOrders();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to upload scan')));
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading scan: ${e.toString()}'), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('UPLOAD DICOM'),
          )
        ],
      ),
    );
  }
}
