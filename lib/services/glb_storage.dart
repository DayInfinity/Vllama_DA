import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_log.dart';

class GlbStorage {
  static Future<File> saveFromBase64({
    required String glbBase64,
    String? fileName,
  }) async {
    AppLog.add('Decoding glbData base64… length=${glbBase64.length}');
    final bytes = base64Decode(glbBase64);
    AppLog.add('Decoded GLB bytes: ${bytes.length}');
    final dir = await getTemporaryDirectory();
    final safeName = (fileName == null || fileName.trim().isEmpty)
        ? 'model_${DateTime.now().millisecondsSinceEpoch}.glb'
        : fileName;
    final finalName = safeName.toLowerCase().endsWith('.glb') ? safeName : '$safeName.glb';
    final file = File(p.join(dir.path, finalName));
    await file.writeAsBytes(bytes, flush: true);
    AppLog.add('Saved GLB: ${file.path}');
    return file;
  }
}


