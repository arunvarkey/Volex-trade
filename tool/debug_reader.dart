import 'dart:io';
import 'dart:convert';

void main() async {
  final inFile = File('current_errors.txt');
  final outFile = File('current_errors_utf8.txt');

  if (!await inFile.exists()) {
    await outFile.writeAsString('Error: current_errors.txt not found');
    exit(1);
  }

  try {
    // Try reading as UTF-8 first (default)
    String content = await inFile.readAsString();
    await outFile.writeAsString(content); // Writes as UTF-8 default
  } catch (e) {
    // Fallback to Latin1/Binary
    try {
      final bytes = await inFile.readAsBytes();
      // Decode with replacement for safety
      final content = utf8.decode(bytes, allowMalformed: true);
      await outFile.writeAsString(content);
    } catch (e2) {
      await outFile.writeAsString('Failed to convert: $e\n$e2');
    }
  }
}
