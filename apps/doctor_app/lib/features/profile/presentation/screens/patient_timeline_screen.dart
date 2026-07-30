import 'package:flutter/material.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';

class PatientTimelineScreen extends StatefulWidget {
  final int patientId;
  const PatientTimelineScreen({super.key, required this.patientId});

  @override
  State<PatientTimelineScreen> createState() => _PatientTimelineScreenState();
}

class _PatientTimelineScreenState extends State<PatientTimelineScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _timelineEvents = [];

  @override
  void initState() {
    super.initState();
    _fetchTimeline();
  }

  Future<void> _fetchTimeline() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get('/doctor/patients/${widget.patientId}/timeline');
      setState(() {
        _timelineEvents = response.data as List? ?? [];
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to load medical timeline.";
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconForType(String type, String category) {
    final catLower = category.toLowerCase();
    final typeLower = type.toLowerCase();
    
    if (catLower.contains('allergy')) return Icons.warning_amber_rounded;
    if (catLower.contains('surgery')) return Icons.biotech_rounded;
    if (catLower.contains('vaccin')) return Icons.vaccines_rounded;
    if (typeLower.contains('prescription')) return Icons.medication_rounded;
    if (typeLower.contains('report') || catLower.contains('imaging')) return Icons.folder_shared_rounded;
    return Icons.healing_rounded;
  }

  Color _getColorForType(String type, String category) {
    final catLower = category.toLowerCase();
    final typeLower = type.toLowerCase();
    
    if (catLower.contains('allergy')) return Colors.red;
    if (catLower.contains('surgery')) return Colors.orange;
    if (catLower.contains('vaccin')) return Colors.purple;
    if (typeLower.contains('prescription')) return Colors.green;
    if (typeLower.contains('report') || catLower.contains('imaging')) return Colors.indigo;
    return Colors.teal;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinical History Timeline'),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _timelineEvents.isEmpty
                    ? const Center(child: Text('No history items registered on patient timeline.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(24.0),
                        itemCount: _timelineEvents.length,
                        itemBuilder: (context, index) {
                          final event = _timelineEvents[index];
                          final type = event['type'] as String? ?? 'Record';
                          final category = event['category'] as String? ?? 'General';
                          final title = event['title'] as String? ?? 'Item';
                          final description = event['description'] as String? ?? '';
                          final date = event['date'] as String? ?? 'N/A';

                          final icon = _getIconForType(type, category);
                          final color = _getColorForType(type, category);

                          return IntrinsicHeight(
                            child: Row(
                              children: [
                                // Timeline bullet
                                Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: color, width: 2),
                                      ),
                                      child: Icon(icon, color: color, size: 20),
                                    ),
                                    if (index < _timelineEvents.length - 1)
                                      Expanded(
                                        child: VerticalDivider(
                                          color: Colors.grey.shade300,
                                          thickness: 2,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 20),

                                // Timeline content card
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 24.0),
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: color.withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    category.toUpperCase(),
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  date,
                                                  style: Theme.of(context).textTheme.bodySmall,
                                                )
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (description.isNotEmpty) ...[
                                              const SizedBox(height: 6),
                                              Text(
                                                description,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                    ),
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
