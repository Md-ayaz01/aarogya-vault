import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';

class PatientReportsScreen extends StatefulWidget {
  final int patientId;
  const PatientReportsScreen({super.key, required this.patientId});

  @override
  State<PatientReportsScreen> createState() => _PatientReportsScreenState();
}

class _PatientReportsScreenState extends State<PatientReportsScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _reports = [];
  List<dynamic> _filteredReports = [];
  String _searchQuery = "";
  String _selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/doctor/patients/${widget.patientId}/reports');
      setState(() {
        _reports = response.data as List? ?? [];
        _applyFilters();
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to fetch diagnostic reports.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReports = _reports.where((r) {
        final title = (r['title'] as String? ?? '').toLowerCase();
        final type = (r['type'] as String? ?? '').toLowerCase();
        
        final matchesSearch = title.contains(_searchQuery.toLowerCase());
        final matchesType = _selectedFilter == "All" || type.contains(_selectedFilter.toLowerCase());
        
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostic Reports'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search and filter headers
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search Reports',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ["All", "Lab", "Imaging"].map((type) {
                      final isSelected = _selectedFilter == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedFilter = type;
                              _applyFilters();
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // Reports list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : _filteredReports.isEmpty
                          ? const Center(child: Text('No reports matching search filters.'))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredReports.length,
                              itemBuilder: (context, index) {
                                final report = _filteredReports[index];
                                final title = report['title'] as String? ?? 'Lab Report';
                                final date = report['date'] as String? ?? 'N/A';
                                final type = report['type'] as String? ?? 'Lab';
                                final summary = report['summary'] as String? ?? 'No AI summary generated.';
                                final url = report['file_url'] as String?;

                                final isImaging = type.toLowerCase().contains('imaging') || type.toLowerCase().contains('mri') || type.toLowerCase().contains('x-ray');

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ExpansionTile(
                                    leading: CircleAvatar(
                                      backgroundColor: isImaging ? Colors.purple.shade50 : Colors.blue.shade50,
                                      child: Icon(
                                        isImaging ? Icons.biotech_rounded : Icons.folder_shared_rounded,
                                        color: isImaging ? Colors.purple : Colors.blue,
                                      ),
                                    ),
                                    title: Text(
                                      title,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Text('$type | Date: $date'),
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'AI Generated Report Summary:',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              summary,
                                              style: const TextStyle(color: Colors.black87, fontSize: 14),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                if (url != null && url.isNotEmpty)
                                                  ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final uri = Uri.parse(url);
                                                      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
                                                        // opened report URL
                                                      }
                                                    },
                                                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                                                    label: const Text('Open PDF File'),
                                                    style: ElevatedButton.styleFrom(
                                                      minimumSize: const Size(120, 44),
                                                    ),
                                                  )
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            )
          ],
        ),
      ),
    );
  }
}
