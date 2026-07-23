import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

import '../../../../core/models/prescription_model.dart';
import '../providers/prescriptions_provider.dart';
import 'prescription_details_screen.dart';

class PrescriptionsListScreen extends ConsumerStatefulWidget {
  const PrescriptionsListScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<PrescriptionsListScreen> createState() => _PrescriptionsListScreenState();
}

class _PrescriptionsListScreenState extends ConsumerState<PrescriptionsListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(prescriptionsProvider.notifier).fetchPrescriptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prescriptionsProvider);
    

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Prescriptions",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(prescriptionsProvider.notifier).fetchPrescriptions(),
        color: AppTheme.primaryTeal,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryTeal))
            : state.prescriptions.isEmpty
                ? const Center(child: Text("No prescriptions found."))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: state.prescriptions.length,
                    itemBuilder: (context, index) {
                      final pres = state.prescriptions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTeal.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.description_outlined, color: AppTheme.primaryTeal),
                          ),
                          title: Text(
                            pres.doctorName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("${pres.date} • ${pres.diagnosis}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorRed),
                                onPressed: () => _confirmDelete(context, pres.id, pres.doctorName),
                              ),
                              const Icon(Icons.chevron_right_rounded),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PrescriptionDetailsScreen(prescription: pres),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPrescriptionSheet(context),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text("New Prescription"),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int id, String doctor) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Prescription?"),
          content: Text("Are you sure you want to delete the prescription from $doctor?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await ref.read(prescriptionsProvider.notifier).deletePrescription(id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Prescription deleted successfully."),
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

  void _showAddPrescriptionSheet(BuildContext context) {
    final doctorController = TextEditingController();
    final specialtyController = TextEditingController();
    final diagnosisController = TextEditingController();
    final notesController = TextEditingController();
    
    // Line items lists
    final List<PrescriptionItemModel> items = [];
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text("Add New Prescription", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: doctorController,
                      decoration: const InputDecoration(labelText: "Doctor Name"),
                    ),
                    const SizedBox(height: 12),
                    
                    TextField(
                      controller: specialtyController,
                      decoration: const InputDecoration(labelText: "Hospital / Specialty"),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: diagnosisController,
                      decoration: const InputDecoration(labelText: "Diagnosis (e.g. Cough & Cold)"),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(labelText: "Doctor Notes"),
                    ),
                    const SizedBox(height: 16),

                    const Text("Medicines", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    
                    if (items.isEmpty)
                      const Text("No medicines added yet.", style: TextStyle(color: Colors.grey, fontSize: 12)),

                    ...items.map((it) => ListTile(
                      title: Text(it.medicineName),
                      subtitle: Text(it.instruction),
                      trailing: Text(it.dosage),
                    )),
                    const SizedBox(height: 8),

                    ElevatedButton.icon(
                      onPressed: () {
                        // Quick input form for item
                        final nameC = TextEditingController();
                        final doseC = TextEditingController();
                        final instC = TextEditingController();
                        
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Add Medicine"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(controller: nameC, decoration: const InputDecoration(labelText: "Name")),
                                TextField(controller: doseC, decoration: const InputDecoration(labelText: "Dosage (e.g. 1 Tablet)")),
                                TextField(controller: instC, decoration: const InputDecoration(labelText: "Instruction (e.g. 1-0-1 After Food)")),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                              TextButton(
                                onPressed: () {
                                  if (nameC.text.isNotEmpty) {
                                    setModalState(() {
                                      items.add(PrescriptionItemModel(
                                        medicineName: nameC.text,
                                        dosage: doseC.text,
                                        instruction: instC.text,
                                      ));
                                    });
                                  }
                                  Navigator.pop(context);
                                },
                                child: const Text("Add"),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add Medicine Item"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? Colors.white10 : Colors.black12,
                        foregroundColor: AppTheme.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    ElevatedButton(
                      onPressed: () async {
                        if (doctorController.text.trim().isEmpty) return;
                        
                        final pres = PrescriptionModel(
                          id: DateTime.now().millisecondsSinceEpoch,
                          userId: 1,
                          doctorName: doctorController.text.trim(),
                          specialty: specialtyController.text.trim(),
                          date: DateTime.now().toString().split(' ')[0],
                          diagnosis: diagnosisController.text.trim(),
                          notes: notesController.text.trim(),
                          items: items,
                        );

                        final success = await ref.read(prescriptionsProvider.notifier).addPrescription(pres);
                        if (success && context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Prescription saved successfully!"),
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
                      child: const Text("Save Prescription"),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
