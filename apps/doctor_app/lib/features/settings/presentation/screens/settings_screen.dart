import 'package:flutter/material.dart';
import '../../../../core/database/local_db.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled = false;
  bool _twoFAEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final bio = await LocalDB.getBool('biometric_enabled') ?? false;
    final fa = await LocalDB.getBool('twofa_enabled') ?? false;
    setState(() {
      _biometricEnabled = bio;
      _twoFAEnabled = fa;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    await LocalDB.putBool('biometric_enabled', value);
    setState(() { _biometricEnabled = value; });
  }

  Future<void> _toggleTwoFA(bool value) async {
    await LocalDB.putBool('twofa_enabled', value);
    setState(() { _twoFAEnabled = value; });
  }

  Future<void> _handleLogout(BuildContext context) async {
    await LocalDB.clearAll();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Widget _buildTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTile(
                      icon: Icons.person,
                      title: 'Profile Details',
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ListTile(
                              leading: const Icon(Icons.password),
                              title: const Text('Change Password'),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.pushNamed(context, '/change-password'),
                            ),
                            SwitchListTile(
                              title: const Text('Biometric Login'),
                              value: _biometricEnabled,
                              onChanged: _toggleBiometric,
                            ),
                            SwitchListTile(
                              title: const Text('Two‑Factor Authentication'),
                              value: _twoFAEnabled,
                              onChanged: _toggleTwoFA,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Institution', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            SizedBox(height: 8),
                            Text('Apollo Hospital, Indore'),
                            Text('Permissions: View, Edit, Emergency Access'),
                          ],
                        ),
                      ),
                    ),
                    _buildTile(
                      icon: Icons.help_center,
                      title: 'Support / FAQ',
                      onTap: () => Navigator.pushNamed(context, '/support'),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}






