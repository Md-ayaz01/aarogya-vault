// lib/ui/medical_history/medical_history_item.dart
import 'package:flutter/material.dart';
import 'package:aarogya_vault_app/theme/design_system.dart';
import 'package:aarogya_vault_app/models/medical_history.dart';

class MedicalHistoryItem extends StatelessWidget {
  final MedicalRecord record;

  const MedicalHistoryItem({Key? key, required this.record}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: const Icon(Icons.folder, color: AppColors.secondary),
        title: Text(record.title, style: AppTextStyles.headlineLg),
        subtitle: Text(
          '${record.description}\n${record.date.toLocal().toString().split(' ').first}',
          style: AppTextStyles.bodyLg,
        ),
        trailing: record.documentUrl.isNotEmpty
            ? const Icon(Icons.insert_drive_file, color: AppColors.tertiary)
            : null,
        onTap: () {
          // TODO: navigate to detail view or open document
        },
      ),
    );
  }
}
