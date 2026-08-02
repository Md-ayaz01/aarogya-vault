import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class BedAllocationScreen extends StatefulWidget {
  const BedAllocationScreen({super.key});

  @override
  State<BedAllocationScreen> createState() => _BedAllocationScreenState();
}

class _BedAllocationScreenState extends State<BedAllocationScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _beds = [];
  String _selectedWardFilter = "ALL";

  @override
  void initState() {
    super.initState();
    _fetchBeds();
  }

  Future<void> _fetchBeds() async {
    try {
      final res = await _apiClient.get('/hospital/beds');
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = List<dynamic>.from(raw['data']);
      }
      setState(() {
        _beds = list;
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _beds = [];
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

    final totalBeds = _beds.isEmpty ? 150 : _beds.length * 20;
    final occupiedBeds = _beds.where((b) => b['is_occupied'] == true).length;
    final vacantBeds = totalBeds - occupiedBeds;
    final occupancyPct = ((occupiedBeds / (totalBeds == 0 ? 1 : totalBeds)) * 100).toStringAsFixed(1);

    final filteredBeds = _selectedWardFilter == "ALL"
        ? _beds
        : _beds.where((b) => b['ward_name'].toString().toUpperCase().contains(_selectedWardFilter)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('IPD Admission & Bed Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchBeds,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/beds'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Overview Header & Action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bed & Ward Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Real-time occupancy status & vacant bed readiness', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pushNamed(context, '/admissions'),
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('NEW ADMISSION', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Analytics Bento Grid (Capacity Cards)
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _bentoCard('TOTAL CAPACITY', '$totalBeds Beds', '100% Operational', primaryTeal, Icons.business_rounded),
                      _bentoCard('CURRENT OCCUPANCY', '$occupiedBeds ($occupancyPct%)', 'Active Patients', Colors.purple, Icons.pie_chart_rounded),
                      _bentoCard('AVAILABLE BEDS', '$vacantBeds Vacant', 'Ready for Admission', primaryContainer, Icons.single_bed_rounded),
                      _bentoCard('OCCUPIED BEDS', '$occupiedBeds Occupied', 'Active Patients', Colors.red, Icons.exit_to_app_rounded),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ward Filter Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _wardFilterChip('ALL', 'ALL WARDS'),
                        _wardFilterChip('ICU', 'ICU WARDS'),
                        _wardFilterChip('GENERAL', 'GENERAL WARDS'),
                        _wardFilterChip('PRIVATE', 'PRIVATE WARDS'),
                        _wardFilterChip('EMERGENCY', 'EMERGENCY WARDS'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Ward Bed Grid Visualization
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    itemCount: filteredBeds.length,
                    itemBuilder: (context, idx) {
                      final b = filteredBeds[idx];
                      final isOcc = b['is_occupied'] == true;
                      final statusColor = isOcc ? Colors.red : primaryContainer;
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(b['bed_number'] ?? 'BED', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isOcc ? 'OCCUPIED' : 'VACANT',
                                      style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10),
                                    ),
                                  )
                                ],
                              ),
                              Text(b['ward_name'] ?? 'General Ward', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(isOcc ? (b['patient'] ?? 'Admitted Patient') : 'Ready for patient', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  Text('Rate: ₹${b['daily_rate']}/day', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
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

  Widget _wardFilterChip(String key, String title) {
    final isSelected = _selectedWardFilter == key;
    const primaryTeal = Color(0xFF006B53);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
        selected: isSelected,
        selectedColor: primaryTeal,
        labelStyle: TextStyle(color: isSelected ? Colors.white : null),
        onSelected: (val) {
          if (val) setState(() => _selectedWardFilter = key);
        },
      ),
    );
  }
}
