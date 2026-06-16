import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../models/settings_model.dart';
import '../theme/app_theme.dart';
import 'file_service.dart';
import 'pdf_service.dart';
import 'watermark_service.dart';

/// Coordinates thumbnails, preview, and export.
class AppController {
  AppController({
    WatermarkService? watermarkService,
    PdfService? pdfService,
  })  : _watermark = watermarkService ?? WatermarkService(),
        _pdf = pdfService ?? PdfService(watermarkService ?? WatermarkService());

  final WatermarkService _watermark;
  final PdfService _pdf;

  Future<void> loadSavedLogo(SettingsModel settings) async {
    final path = await ConfigService.getSavedLogoPath();
    if (path != null) settings.setLogoPath(path);
  }

  Future<Uint8List?> loadThumbnail(String path) async {
    try {
      if (p.extension(path).toLowerCase() == '.pdf') {
        final page = await _pdf.renderPage(path, 0, dpi: 72);
        if (page == null) return null;
        final thumb = img.copyResize(
          page,
          width: 220,
          height: 180,
          maintainAspect: true,
        );
        return Uint8List.fromList(img.encodePng(thumb));
      }
      final bytes = await File(path).readAsBytes();
      var image = img.decodeImage(bytes);
      if (image == null) return null;
      image = img.bakeOrientation(image).convert(numChannels: 4);
      final thumb = img.copyResize(
        image,
        width: 220,
        height: 180,
        maintainAspect: true,
      );
      return Uint8List.fromList(img.encodePng(thumb));
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> renderPreview({
    required String path,
    required SettingsModel settings,
    int pdfPageIndex = 0,
  }) async {
    img.Image? base;
    if (p.extension(path).toLowerCase() == '.pdf') {
      base = await _pdf.renderPage(path, pdfPageIndex, dpi: renderDpi);
    } else {
      final bytes = await File(path).readAsBytes();
      base = img.decodeImage(bytes);
      if (base != null) base = img.bakeOrientation(base);
    }
    if (base == null) return null;

    final needsLogo = settings.wmType == 'logo' || settings.wmType == 'logo_text';
    if (needsLogo && (settings.logoPath == null || settings.logoPath!.isEmpty)) {
      return _watermark.encodePreviewPng(base);
    }

    final result = await _watermark.applyWatermark(base, settings);
    return _watermark.encodePreviewPng(result);
  }

  Future<int> pdfPageCount(String path) => _pdf.pageCount(path);

  Future<void> exportFiles({
    required List<String> paths,
    required SettingsModel settings,
    required void Function(double progress) onProgress,
    required void Function(String status, Color color) onStatus,
  }) async {
    final errors = <String>[];
    final total = paths.length;

    for (var i = 0; i < total; i++) {
      final path = paths[i];
      try {
        final out = await FileService.buildOutputPath(path);
        if (p.extension(path).toLowerCase() == '.pdf') {
          await _pdf.processPdf(path, out, settings);
        } else {
          await _watermark.processImage(
            inputPath: path,
            outputPath: out,
            settings: settings,
          );
        }
      } catch (e) {
        errors.add('${FileService.getFileDisplayName(path)}: $e');
      }
      onProgress((i + 1) / total);
    }

    if (errors.isNotEmpty) {
      onStatus('${errors.length} error(s)', AppColors.warn);
      throw ExportException(errors.join('\n'));
    }
    onStatus('✓  $total file(s) saved', AppColors.success);
  }

  Future<void> saveLogoPath(String? path) => ConfigService.saveLogoPath(path);
}

class ExportException implements Exception {
  ExportException(this.message);
  final String message;
  @override
  String toString() => message;
}
