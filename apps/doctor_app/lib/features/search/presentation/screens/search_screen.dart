import 'package:flutter/material.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _searchResults = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllPatients();
  }

  Future<void> _loadAllPatients() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/doctor/patients/search', queryParameters: {'query': ''});
      if (mounted) {
        setState(() {
          _searchResults = response.data as List? ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load patient registry.";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/doctor/patients/search', queryParameters: {'query': query});
      setState(() {
        _searchResults = response.data as List? ?? [];
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to search patient. Check query and connection.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Registry'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Search Patient ID, Name, or Phone',
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Enter name or ID',
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _performSearch,
                    icon: const Icon(Icons.search),
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
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),

              // Search results list
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _searchResults.isEmpty
                        ? const Center(
                            child: Text(
                              'Search for patients using their unique Aarogya ID or verified mobile phone number.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              final patient = _searchResults[index];
                              final hasAccess = patient['has_access'] == true;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: hasAccess
                                        ? Colors.teal.shade50
                                        : Colors.amber.shade50,
                                    child: Icon(
                                      hasAccess
                                          ? Icons.lock_open_rounded
                                          : Icons.lock_rounded,
                                      color: hasAccess ? Colors.teal : Colors.amber.shade800,
                                    ),
                                  ),
                                  title: Text(
                                    patient['full_name'] ?? 'Patient Name',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    'Aarogya ID: ${patient['patient_id']} | Phone: ${patient['phone'] ?? 'N/A'}',
                                  ),
                                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                                  onTap: () {
                                    if (hasAccess) {
                                      Navigator.pushNamed(
                                        context,
                                        '/patient-profile',
                                        arguments: {'patientId': patient['patient_id']},
                                      );
                                    } else {
                                      // Prompt for access setup
                                      _showAccessDeniedDialog(patient['patient_id'], patient['full_name']);
                                    }
                                  },
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAccessDeniedDialog(int patientId, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.lock_rounded, color: Theme.of(context).colorScheme.error),
              const SizedBox(width: 12),
              const Text("Access Locked"),
            ],
          ),
          content: Text(
            "You do not currently have an active authorization to view $name's medical files. "
            "To gain access, please ask the patient to grant you consent or scan their emergency QR code.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/qr-scan');
              },
              child: const Text("Scan Emergency QR"),
            ),
          ],
        );
      },
    );
  }
}
