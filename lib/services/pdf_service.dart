import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/settings_model.dart';
import 'watermark_service.dart';

const renderDpi = 150.0;

class PdfService {
  PdfService(this._watermarkService);

  final WatermarkService _watermarkService;

  Future<int> pageCount(String path) async {
    final bytes = await File(path).readAsBytes();
    final doc = PdfDocument(inputBytes: bytes);
    final count = doc.pages.count;
    doc.dispose();
    return count;
  }

  Future<img.Image?> renderPage(
    String path,
    int pageIndex, {
    double dpi = renderDpi,
  }) async {
    final bytes = await File(path).readAsBytes();
    img.Image? result;
    await for (final raster in Printing.raster(
      bytes,
      pages: [pageIndex],
      dpi: dpi,
    )) {
      result = img.Image.fromBytes(
        width: raster.width,
        height: raster.height,
        bytes: raster.pixels.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      break;
    }
    return result;
  }

  Future<void> processPdf(
    String inputPath,
    String outputPath,
    SettingsModel settings, {
    void Function(int current, int total)? onPageProgress,
  }) async {
    final inputBytes = await File(inputPath).readAsBytes();
    final document = PdfDocument(inputBytes: inputBytes);

    try {
      final total = document.pages.count;
      for (var i = 0; i < total; i++) {
        final page = document.pages[i];
        final size = page.size;
        final widthPt = size.width;
        final heightPt = size.height;
        final widthPx = mathMax(1, (widthPt * renderDpi / 72).round());
        final heightPx = mathMax(1, (heightPt * renderDpi / 72).round());

        final canvas = img.Image(width: widthPx, height: heightPx, numChannels: 4);
        final watermarked = await _watermarkService.applyWatermark(canvas, settings);
        final pngBytes = Uint8List.fromList(img.encodePng(watermarked));

        final bitmap = PdfBitmap(pngBytes);
        page.graphics.drawImage(
          bitmap,
          Rect.fromLTWH(0, 0, widthPt, heightPt),
        );

        onPageProgress?.call(i + 1, total);
      }

      // Zapisanie dokumentu - UWAGA: save() zwraca List<int>
      final savedBytes = document.save() as List<int>;
      await File(outputPath).writeAsBytes(Uint8List.fromList(savedBytes));
    } finally {
      document.dispose();
    }
  }

  int mathMax(int a, int b) => a > b ? a : b;
}