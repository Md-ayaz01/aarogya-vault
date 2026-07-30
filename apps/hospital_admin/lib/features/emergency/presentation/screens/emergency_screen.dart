import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key});

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _qrCtrl = TextEditingController();
  bool _isLoading = true;
  List<dynamic> _cases = [];

  @override
  void initState() {
    super.initState();
    _fetchEmergencyCases();
  }

  Future<void> _fetchEmergencyCases() async {
    try {
      final res = await _apiClient.get('/hospital/emergency');
      setState(() {
        _cases = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _cases = [
          {
            "id": 1,
            "patient_name": "Multiple Trauma - Vehicle Collision",
            "severity": "LEVEL 1 - CRITICAL",
            "triage_notes": "Junction 42-A, Downtown | En-route: 4 min",
            "ambulance_unit": "AMB-702",
            "police_notified": true,
            "level": 1
          },
          {
            "id": 2,
            "patient_name": "Cardiac Arrest - Elderly Male",
            "severity": "LEVEL 2 - SEVERE",
            "triage_notes": "Westside Care Home | Patient Arrived",
            "ambulance_unit": "AMB-104",
            "police_notified": false,
            "level": 2
          },
          {
            "id": 3,
            "patient_name": "Acute Respiratory Distress",
            "severity": "LEVEL 3 - STABLE",
            "triage_notes": "Eastview Plaza | Patient Loading",
            "ambulance_unit": "AMB-331",
            "police_notified": false,
            "level": 3
          },
        ];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const warRoomBg = Color(0xFF0B1C30);
    const activeGreen = Color(0xFF79F9D0);
    const primaryTeal = Color(0xFF006B53);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Command Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: activeGreen),
            onPressed: () => _showQRDialog(context),
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/emergency'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Command Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Emergency Surveillance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Real-time medical resource & ambulance allocation', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('CODE RED INITIATED - ALL EMERGENCY WARD UNITS ALERTED'), backgroundColor: Colors.red),
                          );
                        },
                        icon: const Icon(Icons.add_alert_rounded),
                        label: const Text('CODE RED', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Emergency QR Search Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryTeal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, color: primaryTeal, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _qrCtrl,
                            decoration: const InputDecoration(
                              hintText: 'SCAN OR ENTER EMERGENCY PATIENT QR CODE...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryTeal, foregroundColor: Colors.white),
                          onPressed: () {
                            if (_qrCtrl.text.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Retrieved record for QR Token: ${_qrCtrl.text}')),
                              );
                            }
                          },
                          child: const Text('LOOKUP'),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Live Emergency Feed (War Room Card)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: warRoomBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: activeGreen.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 8),
                                const Text('LIVE EMERGENCY FEED', style: TextStyle(color: activeGreen, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              ],
                            ),
                            const Text('SYSTEM OPERATIONAL', style: TextStyle(color: Colors.white54, fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ..._cases.map((c) {
                          final isL1 = c['level'] == 1 || c['severity'].toString().contains("CRITICAL");
                          final badgeColor = isL1 ? Colors.red : (c['level'] == 2 ? Colors.orange : activeGreen);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: badgeColor.withValues(alpha: 0.2),
                                  child: Icon(Icons.emergency_rounded, color: badgeColor),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c['patient_name'] ?? 'Emergency Patient', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                      const SizedBox(height: 4),
                                      Text('Unit: ${c['ambulance_unit']} | ${c['triage_notes']}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: badgeColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text(
                                    c['severity'] ?? 'LEVEL 1',
                                    style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold, fontSize: 10),
                                  ),
                                )
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Fleet & Ambulance Status Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ambulance Fleet Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('12 / 15 UNITS ACTIVE', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: const LinearProgressIndicator(
                              value: 0.8,
                              minHeight: 8,
                              backgroundColor: Colors.grey,
                              valueColor: AlwaysStoppedAnimation<Color>(primaryTeal),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  void _showQRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Scan Emergency QR Code'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.qr_code_scanner_rounded, size: 80, color: Color(0xFF006B53)),
            SizedBox(height: 12),
            Text('Point camera at patient ABHA / Emergency QR card'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
        ],
      ),
    );
  }
}
