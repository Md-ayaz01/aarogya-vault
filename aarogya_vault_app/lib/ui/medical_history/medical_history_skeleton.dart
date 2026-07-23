// lib/ui/medical_history/medical_history_skeleton.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class MedicalHistorySkeleton extends StatelessWidget {
  const MedicalHistorySkeleton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show a list of shimmering placeholders
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 5,
      itemBuilder: (_, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: ListTile(
            leading: const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
            title: Container(height: 12, color: Colors.grey, width: double.infinity),
            subtitle: Container(height: 10, color: Colors.grey, width: double.infinity),
          ),
        ),
      ),
    );
  }
}
