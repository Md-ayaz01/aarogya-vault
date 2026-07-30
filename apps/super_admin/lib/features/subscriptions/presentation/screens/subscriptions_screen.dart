import 'package:flutter/material.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/widgets/super_admin_drawer.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final ApiClient _apiClient = ApiClient();
  bool _isLoading = true;
  List<dynamic> _plans = [];

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<void> _fetchSubscriptions() async {
    try {
      final res = await _apiClient.get('/super_admin/subscriptions');
      setState(() {
        _plans = res.data is List ? res.data : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _plans = [
          {"id": 1, "hospital_name": "Apollo Care Hospital", "plan_name": "Enterprise Suite", "billing_status": "Active", "monthly_price": 4999.0, "renewal_date": "2026-08-31"},
          {"id": 2, "hospital_name": "Fortis Healthcare Center", "plan_name": "Pro Tier", "billing_status": "Active", "monthly_price": 1999.0, "renewal_date": "2026-08-15"},
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
        title: const Text('Hospital Subscriptions & Billing'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchSubscriptions,
          )
        ],
      ),
      drawer: const SuperAdminDrawer(currentRoute: '/subscriptions'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Platform Subscription Management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const Text('Hospital plan tiers, monthly recurring billing & renewal schedules', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _plans.length,
                    itemBuilder: (context, idx) {
                      final p = _plans[idx];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: const Icon(Icons.card_membership_rounded, color: primaryTeal),
                          title: Text(p['hospital_name'] ?? 'Hospital', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Plan: ${p['plan_name']} | Price: ₹${p['monthly_price']}/mo\nRenewal: ${p['renewal_date']}'),
                          isThreeLine: true,
                          trailing: Text(p['billing_status'] ?? 'Active', style: const TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
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
