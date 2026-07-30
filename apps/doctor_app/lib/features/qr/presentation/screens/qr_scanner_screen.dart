import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final _tokenController = TextEditingController();
  final MobileScannerController _cameraController = MobileScannerController();
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _emergencyData;

  @override
  void dispose() {
    _tokenController.dispose();
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmergencyToken(String token) async {
    if (token.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _emergencyData = null;
    });

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.post('/doctor/emergency-access', data: {
        'qr_token': token
      });
      setState(() {
        _emergencyData = response.data;
      });
    } catch (e) {
      setState(() {
        if (e is DioException) {
          _errorMessage = e.response?.data['detail'] ?? "Invalid or expired emergency QR token.";
        } else {
          _errorMessage = e.toString();
        }
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTest = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency QR Access'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_emergencyData == null) ...[
                // QR Scanner View
                Container(
                  width: double.infinity,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade800, width: 2),
                  ),
                  child: isTest
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 64, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 16),
                            const Text(
                              '[TEST MODE] Mock QR Scanner Active',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: MobileScanner(
                            controller: _cameraController,
                            onDetect: (capture) {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                final String? code = barcode.rawValue;
                                if (code != null && code.isNotEmpty) {
                                  _verifyEmergencyToken(code);
                                  break;
                                }
                              }
                            },
                          ),
                        ),
                ),
                const SizedBox(height: 28),

                // Fallback Manual Code Input
                Text(
                  'Manual Access Code Fallback',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tokenController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Secure QR Token',
                          prefixIcon: Icon(Icons.vpn_key_outlined),
                          hintText: 'test_qr_token_xyz_123',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton.filled(
                      onPressed: () => _verifyEmergencyToken(_tokenController.text.trim()),
                      icon: const Icon(Icons.check),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.all(16),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ] else ...[
                // Emergency Data Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: Colors.red.shade800),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'RESTRICTED EMERGENCY VIEW\nAccess granted for 1 hour only.',
                          style: TextStyle(
                            color: Colors.red.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  _emergencyData?['patient_name'] ?? 'Patient Name',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Age: ${_emergencyData?['age'] ?? 'N/A'} | Gender: ${_emergencyData?['gender'] ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 24),

                _buildEmergencySection('Blood Type', [_emergencyData?['blood_group'] ?? 'Unknown']),
                const Divider(),
                _buildEmergencySection('Allergies', List<String>.from(_emergencyData?['allergies'] ?? [])),
                const Divider(),
                _buildEmergencySection('Chronic Conditions', List<String>.from(_emergencyData?['chronic_diseases'] ?? [])),
                const Divider(),
                _buildEmergencySection('Current Critical Medicines', List<String>.from(_emergencyData?['current_medicines'] ?? [])),
                const Divider(),
                _buildEmergencySection('Primary Emergency Contacts', List<String>.from(_emergencyData?['emergency_contacts'] ?? [])),

                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _emergencyData = null;
                    });
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Scan Another Code'),
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencySection(String label, List<String> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 4),
          ...items.map((it) => Text(
                it,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
              )),
        ],
      ),
    );
  }
}
