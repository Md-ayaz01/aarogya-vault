import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../../core/di/locator.dart';
import '../../../../core/network/api_client.dart';

class PrescriptionCreateScreen extends StatefulWidget {
  final int patientId;
  final String patientName;
  const PrescriptionCreateScreen({Key? key, required this.patientId, required this.patientName}) : super(key: key);

  @override
  State<PrescriptionCreateScreen> createState() => _PrescriptionCreateScreenState();
}

class _PrescriptionCreateScreenState extends State<PrescriptionCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _diagnosisController = TextEditingController();
  final _notesController = TextEditingController();

  final List<Map<String, String>> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  final _medNameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _instructionController = TextEditingController();

  @override
  void dispose() {
    _diagnosisController.dispose();
    _notesController.dispose();
    _medNameController.dispose();
    _dosageController.dispose();
    _instructionController.dispose();
    super.dispose();
  }

  void _addItem() {
    final medName = _medNameController.text.trim();
    final dosage = _dosageController.text.trim();
    final instruction = _instructionController.text.trim();

    if (medName.isEmpty || dosage.isEmpty || instruction.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all medicine fields before adding.')),
      );
      return;
    }

    setState(() {
      _items.add({
        'medicine_name': medName,
        'dosage': dosage,
        'instruction': instruction,
      });
      _medNameController.clear();
      _dosageController.clear();
      _instructionController.clear();
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submitPrescription() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one medicine item.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.post('/doctor/prescriptions', data: {
        'patient_id': widget.patientId,
        'diagnosis': _diagnosisController.text.trim(),
        'notes': _notesController.text.trim(),
        'items': _items,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription registered successfully.')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        if (e is DioException) {
          _errorMessage = e.response?.data['detail'] ?? "Failed to save prescription.";
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Writer'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Patient Name: ${widget.patientName}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 20),

                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                    ),
                  ),

                TextFormField(
                  controller: _diagnosisController,
                  decoration: const InputDecoration(
                    labelText: 'Diagnosis / Chief Complaint',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Diagnosis is required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Clinical Notes',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 28),

                Text(
                  'Medicines & Dosage Instructions',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Medicine Input Card
                Card(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _medNameController,
                          decoration: const InputDecoration(
                            labelText: 'Medicine Name',
                            prefixIcon: Icon(Icons.medication_rounded),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _dosageController,
                                decoration: const InputDecoration(
                                  labelText: 'Dosage (e.g. 500mg)',
                                  prefixIcon: Icon(Icons.numbers_rounded),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _instructionController,
                                decoration: const InputDecoration(
                                  labelText: 'Freq (e.g. 1-0-1)',
                                  prefixIcon: Icon(Icons.schedule_rounded),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Medicine'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Selected items list
                if (_items.isNotEmpty) ...[
                  const Text(
                    'Added Items:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            item['medicine_name']!,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Dosage: ${item['dosage']} | Instruction: ${item['instruction']}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeItem(index),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _submitPrescription,
                        child: const Text('Save & Sign Prescription'),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
