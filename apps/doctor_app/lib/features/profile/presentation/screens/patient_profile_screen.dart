import 'package:flutter/material.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class PatientProfileScreen extends StatefulWidget {
  final int patientId;
  const PatientProfileScreen({super.key, required this.patientId});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/doctor/patients/${widget.patientId}/profile');
      setState(() {
        _profileData = response.data;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Access denied or profile not found. Verify consent record.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Patient Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final name = _profileData?['full_name'] ?? 'N/A';
    final dob = _profileData?['dob'] ?? 'N/A';
    final gender = _profileData?['gender'] ?? 'N/A';
    final bloodGroup = _profileData?['blood_group'] ?? 'N/A';
    final address = _profileData?['address'] ?? 'N/A';
    final emergencyName = _profileData?['emergency_contact_name'] ?? 'N/A';
    final emergencyPhone = _profileData?['emergency_contact_phone'] ?? 'N/A';
    final healthScore = _profileData?['health_score'] ?? 90;

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.healthCardGradientStart, AppTheme.healthCardGradientEnd],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.healthCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Health Score: $healthScore',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Aarogya ID: ${widget.patientId}', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('Gender: $gender | Date of Birth: $dob', style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 4),
                    Text('Blood Type: $bloodGroup', style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Action buttons grid
              Text(
                'Clinical Actions',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.6,
                children: [
                  _buildActionCard(
                    title: 'Medical Timeline',
                    icon: Icons.timeline_rounded,
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/timeline',
                      arguments: {'patientId': widget.patientId},
                    ),
                  ),
                  _buildActionCard(
                    title: 'Diagnostic Reports',
                    icon: Icons.assignment_rounded,
                    color: Colors.indigo,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/reports',
                      arguments: {'patientId': widget.patientId},
                    ),
                  ),
                  _buildActionCard(
                    title: 'New Prescription',
                    icon: Icons.edit_document,
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/prescription-create',
                      arguments: {'patientId': widget.patientId, 'patientName': name},
                    ),
                  ),
                  _buildActionCard(
                    title: 'AI Doctor Copilot',
                    icon: Icons.assistant_rounded,
                    color: Colors.purple,
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/ai-copilot',
                      arguments: {'patientId': widget.patientId},
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Demographic details list
              Text(
                'Demographics & Vitals',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow('Address', address),
                      const Divider(),
                      _buildDetailRow('Primary Emergency Contact', emergencyName),
                      const Divider(),
                      _buildDetailRow('Emergency Contact Phone', emergencyPhone),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.24)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: color.withOpacity(0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
