// lib/ui/medical_history/medical_history_header.dart
import 'package:flutter/material.dart';
import 'package:aarogya_vault_app/theme/design_system.dart';

class MedicalHistoryHeader extends StatelessWidget {
  final String title;

  const MedicalHistoryHeader({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Text(title, style: AppTextStyles.headlineLg),
    );
  }
}
