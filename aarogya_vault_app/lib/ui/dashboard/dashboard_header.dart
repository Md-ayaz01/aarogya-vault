// lib/ui/dashboard/dashboard_header.dart
import 'package:flutter/material.dart';
import 'package:aarogya_vault_app/theme/design_system.dart';

class DashboardHeader extends StatelessWidget {
  final String userName;
  final String avatarUrl; // can be empty for placeholder

  const DashboardHeader({
    Key? key,
    required this.userName,
    this.avatarUrl = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
            child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 32) : null,
            backgroundColor: AppColors.secondary,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good day,', style: AppTextStyles.bodyLg.copyWith(color: Colors.grey[600])),
              Text(userName, style: AppTextStyles.headlineLg),
            ],
          ),
          const Spacer(),
          // Quick status chip (example: "All Set")
          Chip(
            label: const Text('All Set'),
            backgroundColor: AppColors.primaryContainer,
            labelStyle: AppTextStyles.labelBold.copyWith(color: AppColors.onPrimary),
          ),
        ],
      ),
    );
  }
}
