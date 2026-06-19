import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  static const String _androidSaveRoot = '/storage/emulated/0/Download/WaterShield';

  static const MethodChannel _mediaScanner =
      MethodChannel('watershield/media_scanner');

  static Future<void> scanFile(String path) async {
    if (!Platform.isAndroid) return;
    try {
      await _mediaScanner.invokeMethod('scanFile', {'path': path});
    } catch (_) {}
  }

  static Future<String> get baseDir async {
    if (Platform.isAndroid || Platform.isIOS) {
      return (await getApplicationDocumentsDirectory()).path;
    }
    return Directory.current.path;
  }

  static Future<String> get saveRootDir async {
    final dir = Platform.isAndroid
        ? Directory(_androidSaveRoot)
        : Directory(p.join(await baseDir, 'output'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get imagesDir async {
    final dir = Directory(p.join(await saveRootDir, 'fotos'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get pdfDir async {
    final dir = Directory(p.join(await saveRootDir, 'pdf'));
    await dir.create(recursive: true);
    return dir.path;
  }

  static Future<String> get outputDir async => saveRootDir;

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

    final dir = suffix == '.pdf' ? await pdfDir : await imagesDir;
    return p.join(dir, '${stem}_watermarked$outSuffix');
  }

  static String getFileDisplayName(String filePath) => p.basename(filePath);

  static Future<String> getOutputDirAbsolute() async => await saveRootDir;
  static Future<String> getImagesDirAbsolute() async => await imagesDir;
  static Future<String> getPdfDirAbsolute() async => await pdfDir;
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
