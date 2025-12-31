import 'package:flutter/foundation.dart';

/// Simple in-app logger so we can debug API + file + viewer flow without
/// relying only on terminal output.
class AppLog {
  static final ValueNotifier<List<String>> lines = ValueNotifier<List<String>>(<String>[]);

  static void clear() => lines.value = <String>[];

  static void add(String message) {
    final ts = DateTime.now().toIso8601String().split('T').last;
    final line = '[$ts] $message';

    // Console too (useful when running `flutter run`).
    debugPrint(line);

    final next = List<String>.from(lines.value)..add(line);
    // Keep last 400 lines to avoid unbounded growth.
    lines.value = next.length > 400 ? next.sublist(next.length - 400) : next;
  }
}


