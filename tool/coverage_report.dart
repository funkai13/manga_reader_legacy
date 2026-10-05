// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  final file = File('coverage/lcov.info');
  if (!file.existsSync()) {
    print('No lcov.info found');
    return;
  }
  final lines = file.readAsLinesSync();
  String? currentSource;
  int found = 0;
  int hit = 0;

  final summary = <String, (int, int)>{};
  final unhitLines = <String, List<int>>{};

  for (final line in lines) {
    if (line.startsWith('SF:')) {
      currentSource = line.substring(3);
    } else if (line.startsWith('DA:')) {
      final parts = line.substring(3).split(',');
      final lineNum = int.parse(parts[0]);
      final count = int.parse(parts[1]);
      found++;
      if (count > 0) {
        hit++;
      } else {
        unhitLines.putIfAbsent(currentSource!, () => []).add(lineNum);
      }
    } else if (line == 'end_of_record') {
      if (currentSource != null) {
        summary[currentSource] = (hit, found);
      }
      found = 0;
      hit = 0;
      currentSource = null;
    }
  }

  print('=== NON-WIDGET / LOGIC COVERAGE ===');
  final keys = summary.keys.toList()..sort();
  for (final path in keys) {
    if (path.contains('widgets') || path.contains('screens') || path.contains('screen')) {
      continue;
    }
    final stats = summary[path]!;
    final pct = stats.$2 == 0 ? 100.0 : (stats.$1 / stats.$2 * 100);
    final unhit = unhitLines[path] ?? [];
    final unhitStr = unhit.isEmpty ? '' : ' | Unhit: $unhit';
    print('${pct.toStringAsFixed(1).padLeft(6)}% (${stats.$1}/${stats.$2}) : $path$unhitStr');
  }
}
