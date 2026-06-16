import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const supportedImageExtensions = {
  '.jpg',
  '.jpeg',
  '.png',
  '.bmp',
  '.webp',
  '.tiff',
};

const supportedExtensions = {...supportedImageExtensions, '.pdf'};

class FileService {
  static Future<String> get baseDir async {
    if (Platform.isAndroid || Platform.isIOS) {
      return (await getApplicationDocumentsDirectory()).path;
    }
    return Directory.current.path;
  }

  static Future<String> get outputDir async {
    final dir = p.join(await baseDir, 'output');
    await Directory(dir).create(recursive: true);
    return dir;
  }

  static Future<String> get configPath async =>
      p.join(await baseDir, 'config.json');

  static bool isSupportedImage(String filePath) =>
      supportedImageExtensions.contains(p.extension(filePath).toLowerCase());

  static bool isSupportedFile(String filePath) =>
      supportedExtensions.contains(p.extension(filePath).toLowerCase());

  static List<String> filterSupportedFiles(List<String> paths) =>
      paths.where(isSupportedFile).toList();

  static Future<String> buildOutputPath(String inputPath) async {
    final stem = p.basenameWithoutExtension(inputPath);
    final suffix = p.extension(inputPath).toLowerCase();
    final outSuffix = (suffix == '.jpg' || suffix == '.jpeg')
        ? '.jpg'
        : suffix == '.pdf'
            ? '.pdf'
            : '.png';
    return p.join(await outputDir, '${stem}_watermarked$outSuffix');
  }

  static String getFileDisplayName(String filePath) => p.basename(filePath);

  static Future<String> getOutputDirAbsolute() async => await outputDir;
}

class ConfigService {
  static Future<Map<String, dynamic>> _load() async {
    try {
      final file = File(await FileService.configPath);
      if (await file.exists()) {
        return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      }
    } catch (_) {}
    return {};
  }

  static Future<void> _save(Map<String, dynamic> data) async {
    try {
      final path = await FileService.configPath;
      await File(path).writeAsString(
        const JsonEncoder.withIndent('  ').convert(data),
      );
    } catch (_) {}
  }

  static Future<String?> getSavedLogoPath() async {
    final cfg = await _load();
    final saved = cfg['logo_path'] as String?;
    if (saved != null && saved.isNotEmpty && File(saved).existsSync()) {
      return saved;
    }
    return null;
  }

  static Future<void> saveLogoPath(String? path) async {
    final cfg = await _load();
    if (path != null && path.isNotEmpty) {
      cfg['logo_path'] = path;
    } else {
      cfg.remove('logo_path');
    }
    await _save(cfg);
  }
}
