// bin/generate_stitch_screens.dart
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Path to the MCP JSON that lists all screens.
const String _screenListPath = r'C:\Users\patha\.gemini\antigravity-ide\brain\0e7efde9-e19d-4cd7-b436-6938394743e7\.system_generated\steps\1245\output.txt';

/// Destination folder for generated screen widgets.
final String _outputDir = p.join(
  Directory.current.path,
  'lib',
  'generated',
  'screens',
);

void main() async {
  final File jsonFile = File(_screenListPath);
  if (!await jsonFile.exists()) {
    print('Screen list file not found: $_screenListPath');
    exit(1);
  }

  final String raw = await jsonFile.readAsString();
  final Map<String, dynamic> data = json.decode(raw);
  final List<dynamic> screens = data['screens'] ?? [];

  await Directory(_outputDir).create(recursive: true);

  for (final screen in screens) {
    final String title = (screen['title'] as String?) ?? 'Untitled';
    final String html = (screen['htmlCode']?['downloadUrl'] as String?) ?? '';

    final String fileName = _titleToFileName(title);
    final String className = _fileNameToClassName(fileName);

    final String content = '''
import 'package:flutter/material.dart';
import 'package:aarogya_vault_app/theme/design_system.dart';

class $className extends StatelessWidget {
  const $className({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$title', style: AppTextStyles.headlineLg),
        backgroundColor: AppColors.primary,
      ),
      body: Center(
        child: Text(
          'Screen placeholder for "$title".\\n\\nHTML source: $html',
          style: AppTextStyles.bodyLg,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
''';

    final File outFile = File(p.join(_outputDir, fileName));
    await outFile.writeAsString(content);
    print('Generated ${outFile.path}');
  }

  print('✅ All ${screens.length} screen stubs generated under lib/generated/screens/');
}

String _titleToFileName(String title) {
  final cleaned = title
      .replaceAll(RegExp(r'^\d+\.\s*'), '')
      .replaceAll(RegExp(r'[^a-zA-Z0-9_\s]'), '')
      .replaceAll(RegExp(r'[/\\]'), ' ')
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '_');
  return '${cleaned}_screen.dart';
}

String _fileNameToClassName(String fileName) {
  final base = p.basenameWithoutExtension(fileName);
  return base.split('_').map((part) => part[0].toUpperCase() + part.substring(1)).join();
}
