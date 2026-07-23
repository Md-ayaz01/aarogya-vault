import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';

class MedicalHistoryScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const MedicalHistoryScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  ConsumerState<MedicalHistoryScreen> createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends ConsumerState<MedicalHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this, initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardProvider);
    final history = dashboardState.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Medical History",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppTheme.primaryTeal,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Overview"),
            Tab(text: "Conditions"),
            Tab(text: "Allergies"),
            Tab(text: "Surgeries"),
            Tab(text: "Family History"),
            Tab(text: "Vaccinations"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(history),
          _buildFilteredList(history, "condition"),
          _buildFilteredList(history, "allergy"),
          _buildFilteredList(history, "surgery"),
          _buildFilteredList(history, "family"),
          _buildFilteredList(history, "vaccination"),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddHistoryDialog(context),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("Add History"),
      ),
    );
  }

  Widget _buildOverviewTab(dynamic historyList) {
    if (historyList.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: historyList.map<Widget>((item) {
          IconData icon;
          Color color;
          switch (item.type) {
            case 'condition':
              icon = Icons.healing_rounded;
              color = AppTheme.primaryTeal;
              break;
            case 'allergy':
              icon = Icons.warning_amber_rounded;
              color = AppTheme.errorRed;
              break;
            case 'surgery':
              icon = Icons.medical_services_rounded;
              color = AppTheme.alertYellow;
              break;
            case 'family':
              icon = Icons.people_outline_rounded;
              color = Colors.indigo;
              break;
            default:
              icon = Icons.vaccines_rounded;
              color = AppTheme.secondaryEmerald;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(item.description),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed),
                    onPressed: () => _confirmDelete(context, item.id, item.title),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
              onTap: () {
                int index = 0;
                if (item.type == 'condition') index = 1;
                if (item.type == 'allergy') index = 2;
                if (item.type == 'surgery') index = 3;
                if (item.type == 'family') index = 4;
                if (item.type == 'vaccination') index = 5;
                _tabController.animateTo(index);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilteredList(dynamic historyList, String type) {
    final filtered = historyList.where((item) => item.type == type).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text("No entries recorded under this category.", style: TextStyle(color: isDark ? Colors.white60 : Colors.black54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return GlassContainer(
          margin: const EdgeInsets.only(bottom: 16),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                  Text(
                    item.dateRecorded,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed, size: 20),
                    onPressed: () => _confirmDelete(context, item.id, item.title),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                item.description,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  height: 1.4,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, int itemId, String title) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Entry?"),
          content: Text("Are you sure you want to delete medical history entry '$title'?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(dashboardProvider.notifier).deleteHistoryItem(itemId);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Entry deleted successfully."),
                      backgroundColor: AppTheme.primaryTeal,
                    ),
                  );
                }
              },
              child: const Text("Delete", style: TextStyle(color: AppTheme.errorRed)),
            ),
          ],
        );
      },
    );
  }

  void _showAddHistoryDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedType = "condition";
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text("Add Medical History", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: "History Category"),
                    items: const [
                      DropdownMenuItem(value: "condition", child: Text("Chronic Condition")),
                      DropdownMenuItem(value: "allergy", child: Text("Allergy")),
                      DropdownMenuItem(value: "surgery", child: Text("Surgery")),
                      DropdownMenuItem(value: "family", child: Text("Family History")),
                      DropdownMenuItem(value: "vaccination", child: Text("Vaccination")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() {
                          selectedType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: "Title (e.g. Pollen Allergy, Appendectomy)"),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: "Details / Description"),
                  ),
                  const SizedBox(height: 24),
                  
                  ElevatedButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) return;
                      
                      await ref.read(dashboardProvider.notifier).addHistoryItem(
                        selectedType,
                        titleController.text.trim(),
                        descController.text.trim(),
                      );
                      
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Medical history entry added!"),
                            backgroundColor: AppTheme.primaryTeal,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryTeal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Save Entry"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
