import 'package:flutter/material.dart';
import 'package:aarogya_vault_app/theme/design_system.dart';

class EmergencyAccessSampleViewScreen extends StatelessWidget {
  const EmergencyAccessSampleViewScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('10. Emergency Access (Sample View)', style: AppTextStyles.headlineLg),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Text(
          'Screen placeholder for "10. Emergency Access (Sample View)".\n\nHTML source: https://contribution.usercontent.google.com/download?c=CgthaWRhX2NvZGVmeBJ6Eh1hcHBfY29tcGFuaW9uX2dlbmVyYXRlZF9maWxlcxpZCiVodG1sXzAwMDY1NmExMDgyOTI3Y2IwOTI1Yzc1ZTg5MTExMjkyEgsSBxD17s3KjBQYAZIBIgoKcHJvamVjdF9pZBIUQhI3ODA3MDg1ODc5NDcxMDQ2ODE&filename=&opi=89354086',
          style: AppTextStyles.bodyLg,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
