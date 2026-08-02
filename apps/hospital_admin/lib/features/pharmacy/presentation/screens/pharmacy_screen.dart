import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/hospital_drawer.dart';

class PharmacyScreen extends StatefulWidget {
  const PharmacyScreen({super.key});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _inventory = [];

  @override
  void initState() {
    super.initState();
    _fetchPharmacyInventory();
  }

  Future<void> _fetchPharmacyInventory() async {
    try {
      final res = await _apiClient.get('/hospital/pharmacy/inventory');
      final raw = res.data;
      List<dynamic> list = [];
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = List<dynamic>.from(raw['data']);
      }
      setState(() {
        _inventory = list;
        _isLoading = false;
      });
    } catch (e) {
    setState(() {
      _inventory = [];
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pharmacy Inventory & Stock'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchPharmacyInventory,
          )
        ],
      ),
      drawer: const HospitalDrawer(currentRoute: '/pharmacy'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title & Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Medicine Inventory', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('Stock levels, batch numbers & low-stock reorder warnings', style: TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryContainer,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _showAddStockDialog(context),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('ADD STOCK', style: TextStyle(fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary Stats Grid
                  GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [
                      _bentoCard('TOTAL SKU', '${_inventory.length} SKUs', 'Inventory SKUs', primaryTeal, Icons.inventory_2_rounded),
                      _bentoCard('CRITICAL LOW STOCK', '${_inventory.where((i) => i['is_low_stock'] == true).length} SKUs', 'Reorder Required', Colors.red, Icons.warning_rounded),
                      _bentoCard('FULFILMENT RATE', '98.4%', 'Target: 99%', primaryContainer, Icons.task_alt_rounded),
                      _bentoCard('ACTIVE SUPPLIERS', 'Active Vendors', 'Operational', Colors.blue, Icons.local_shipping_rounded),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Medicine Inventory List Cards
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _inventory.length,
                    itemBuilder: (context, idx) {
                      final item = _inventory[idx];
                      final isCrit = item['status'] == "CRITICAL";
                      final isWarn = item['status'] == "WARNING";
                      final statusColor = isCrit ? Colors.red : (isWarn ? Colors.orange : primaryContainer);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: statusColor.withValues(alpha: 0.2),
                            child: Icon(Icons.local_pharmacy_rounded, color: statusColor),
                          ),
                          title: Row(
                            children: [
                              Text(item['medicine_name'] ?? 'Medicine', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                                child: Text(item['status'] ?? 'STABLE', style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              )
                            ],
                          ),
                          subtitle: Text('Batch: ${item['batch_number']} | Expiry: ${item['expiry_date']}\nUnit Price: ₹${item['unit_price']}'),
                          isThreeLine: true,
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${item['quantity']} Units', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 14)),
                              const Text('In Stock', style: TextStyle(color: Colors.grey, fontSize: 11)),
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

  void _showAddStockDialog(BuildContext context) {
    final medCtrl = TextEditingController();
    final batchCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Pharmacy Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: medCtrl, decoration: const InputDecoration(labelText: 'Medicine Name')),
            const SizedBox(height: 8),
            TextField(controller: batchCtrl, decoration: const InputDecoration(labelText: 'Batch Number')),
            const SizedBox(height: 8),
            TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Quantity Units'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (medCtrl.text.isEmpty || qtyCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter medicine name and quantity')));
                return;
              }
              try {
                final res = await _apiClient.post('/hospital/pharmacy/inventory', data: {
                  'medicine_name': medCtrl.text,
                  'category': 'General',
                  'batch_number': batchCtrl.text.isNotEmpty ? batchCtrl.text : 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                  'stock_quantity': int.tryParse(qtyCtrl.text) ?? 50,
                  'unit_price': 45,
                  'expiry_date': '2027-12-31',
                  'reorder_level': 20
                });
                if (mounted) {
                  Navigator.pop(ctx);
                  if (res.data != null && res.data['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pharmacy stock added successfully!')));
                    _fetchPharmacyInventory();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add stock')));
                  }
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding stock: ${e.toString()}'), backgroundColor: Colors.redAccent));
                }
              }
            },
            child: const Text('ADD STOCK'),
          )
        ],
      ),
    );
  }
}
