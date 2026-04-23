import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DownloadService {
  /// Downloads raw high-res URL to device storage.
  /// Only called on explicit user tap - never automatically.
  static Future<String> downloadHighRes(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode != 200) {
      throw Exception('Download failed: HTTP ${response.statusCode}');
    }

    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'highres_${DateTime.now().millisecondsSinceEpoch}.webp';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(response.bodyBytes);

    return file.path;
  }
}
