import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

import '../models/settings_model.dart';

const _positionMap = {
  'top-left': ('left', 'top'),
  'top-center': ('center', 'top'),
  'top-right': ('right', 'top'),
  'center': ('center', 'center'),
  'bottom-left': ('left', 'bottom'),
  'bottom-center': ('center', 'bottom'),
  'bottom-right': ('right', 'bottom'),
};

class WatermarkService {
  Future<img.Image> applyWatermark(img.Image image, SettingsModel settings) async {
    final rgb = settings.colorRgb;
    final color = (rgb.$1, rgb.$2, rgb.$3);

    switch (settings.wmType) {
      case 'text':
        return settings.mode == 'corner'
            ? await applyCornerWatermark(
                image,
                text: settings.text,
                position: settings.position,
                opacity: settings.opacity,
                sizePercent: settings.textSize,
                offset: settings.offset,
                color: color,
              )
            : await applyTileWatermark(
                image,
                text: settings.text,
                opacity: settings.opacity,
                sizePercent: settings.textSize,
                spacing: settings.spacing,
                angle: settings.angle,
                color: color,
              );
      case 'logo':
        final lp = settings.logoPath;
        if (lp == null || lp.isEmpty) {
          throw ArgumentError('logo_path required');
        }
        return settings.mode == 'corner'
            ? applyCornerLogo(
                image,
                logoPath: lp,
                position: settings.position,
                opacity: settings.opacity,
                sizePercent: settings.logoSize,
                offset: settings.offset,
              )
            : applyTileLogo(
                image,
                logoPath: lp,
                opacity: settings.opacity,
                sizePercent: settings.logoSize,
                spacing: settings.spacing,
                angle: settings.angle,
              );
      case 'logo_text':
        final lp = settings.logoPath;
        if (lp == null || lp.isEmpty) {
          throw ArgumentError('logo_path required');
        }
        return settings.mode == 'corner'
            ? await applyCornerLogoAndText(
                image,
                text: settings.text,
                logoPath: lp,
                position: settings.position,
                opacity: settings.opacity,
                sizePercent: settings.textSize,
                offset: settings.offset,
                logoSizePercent: settings.logoSize,
                order: settings.order,
                color: color,
              )
            : await applyTileLogoAndText(
                image,
                text: settings.text,
                logoPath: lp,
                opacity: settings.opacity,
                sizePercent: settings.textSize,
                spacing: settings.spacing,
                angle: settings.angle,
                logoSizePercent: settings.logoSize,
                order: settings.order,
                color: color,
              );
      default:
        throw ArgumentError('Unknown wm_type: ${settings.wmType}');
    }
  }

  Future<void> processImage({
    required String inputPath,
    required String outputPath,
    required SettingsModel settings,
  }) async {
    final bytes = await File(inputPath).readAsBytes();
    var image = img.decodeImage(bytes);
    if (image == null) throw Exception('Cannot decode image: $inputPath');

    image = img.bakeOrientation(image);
    final ext = inputPath.toLowerCase();
    final result = await applyWatermark(image, settings);

    if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
      final rgb = img.Image.from(result);
      await File(outputPath).writeAsBytes(img.encodeJpg(rgb, quality: 95));
    } else {
      await File(outputPath).writeAsBytes(img.encodePng(result));
    }
  }

  Future<img.Image> applyCornerWatermark(
    img.Image image, {
    required String text,
    String position = 'bottom-right',
    double opacity = 0.5,
    double sizePercent = 5.0,
    int offset = 20,
    (int, int, int) color = (255, 255, 255),
  }) async {
    final base = image.convert(numChannels: 4);
    final fontSize = math.max(10.0, base.width * sizePercent / 100);
    final textImg = await _renderText(
      text,
      fontSize: fontSize,
      color: Color.fromARGB((255 * opacity).round(), color.$1, color.$2, color.$3),
      lineSpacing: 4,
    );
    final (x, y) = _calcXy(
      base.width,
      base.height,
      textImg.width,
      textImg.height,
      position,
      offset,
    );
    final overlay = img.Image(width: base.width, height: base.height, numChannels: 4);
    img.compositeImage(overlay, textImg, dstX: x, dstY: y);
    return img.compositeImage(base, overlay);
  }

  img.Image applyCornerLogo(
    img.Image image, {
    required String logoPath,
    String position = 'bottom-right',
    double opacity = 0.5,
    double sizePercent = 15.0,
    int offset = 20,
  }) {
    final base = image.convert(numChannels: 4);
    final logoW = math.max(10, (base.width * sizePercent / 100).round());
    final logo = _loadLogo(logoPath, logoW, opacity);
    final (x, y) = _calcXy(
      base.width,
      base.height,
      logo.width,
      logo.height,
      position,
      offset,
    );
    final overlay = img.Image(width: base.width, height: base.height, numChannels: 4);
    img.compositeImage(overlay, logo, dstX: x, dstY: y);
    return img.compositeImage(base, overlay);
  }

  Future<img.Image> applyCornerLogoAndText(
    img.Image image, {
    required String text,
    required String logoPath,
    String position = 'bottom-right',
    double opacity = 0.5,
    double sizePercent = 5.0,
    int offset = 20,
    double logoSizePercent = 15.0,
    String order = 'text_above_logo',
    (int, int, int) color = (255, 255, 255),
  }) async {
    final base = image.convert(numChannels: 4);
    final fontSize = math.max(10.0, base.width * sizePercent / 100);
    final textImg = await _renderText(
      text,
      fontSize: fontSize,
      color: Color.fromARGB((255 * opacity).round(), color.$1, color.$2, color.$3),
      lineSpacing: 4,
      align: TextAlign.center,
    );
    final tw = textImg.width;
    final th = textImg.height;

    final logoW = math.max(10, (base.width * logoSizePercent / 100).round());
    final logo = _loadLogo(logoPath, logoW, opacity);
    final lw = logo.width;
    final lh = logo.height;

    final gap = math.max(6, (base.height * 0.012).round());
    final blockW = math.max(tw, lw);
    final blockH = th + gap + lh;

    final (bx, by) = _calcXy(base.width, base.height, blockW, blockH, position, offset);
    final textX = bx + (blockW - tw) ~/ 2;
    final logoX = bx + (blockW - lw) ~/ 2;

    final textY = order == 'text_above_logo' ? by : by + lh + gap;
    final logoY = order == 'text_above_logo' ? by + th + gap : by;

    final overlay = img.Image(width: base.width, height: base.height, numChannels: 4);
    img.compositeImage(overlay, textImg, dstX: textX, dstY: textY);
    img.compositeImage(overlay, logo, dstX: logoX, dstY: logoY);
    return img.compositeImage(base, overlay);
  }

  Future<img.Image> applyTileWatermark(
    img.Image image, {
    required String text,
    double opacity = 0.3,
    double sizePercent = 4.0,
    int spacing = 60,
    double angle = -30.0,
    (int, int, int) color = (255, 255, 255),
  }) async {
    final base = image.convert(numChannels: 4);
    final fontSize = math.max(10.0, base.width * sizePercent / 100);
    final textImg = await _renderText(
      text,
      fontSize: fontSize,
      color: Color.fromARGB((255 * opacity).round(), color.$1, color.$2, color.$3),
      lineSpacing: 2,
    );
    final tw = textImg.width;
    final th = textImg.height;

    final tiled = _tileLayer(
      (base.width, base.height),
      tw + spacing,
      th + spacing,
      angle,
      (layer, col, row) {
        img.compositeImage(layer, textImg, dstX: col, dstY: row);
      },
    );
    return img.compositeImage(base, tiled);
  }

  img.Image applyTileLogo(
    img.Image image, {
    required String logoPath,
    double opacity = 0.3,
    double sizePercent = 10.0,
    int spacing = 60,
    double angle = -30.0,
  }) {
    final base = image.convert(numChannels: 4);
    final logoW = math.max(10, (base.width * sizePercent / 100).round());
    final logo = _loadLogo(logoPath, logoW, opacity);
    final lw = logo.width;
    final lh = logo.height;

    final tiled = _tileLayer(
      (base.width, base.height),
      lw + spacing,
      lh + spacing,
      angle,
      (layer, col, row) {
        if (col + lw > 0 && row + lh > 0 && col < layer.width && row < layer.height) {
          img.compositeImage(layer, logo, dstX: col, dstY: row);
        }
      },
    );
    return img.compositeImage(base, tiled);
  }

  Future<img.Image> applyTileLogoAndText(
    img.Image image, {
    required String text,
    required String logoPath,
    double opacity = 0.3,
    double sizePercent = 4.0,
    int spacing = 60,
    double angle = -30.0,
    double logoSizePercent = 10.0,
    String order = 'text_above_logo',
    (int, int, int) color = (255, 255, 255),
  }) async {
    final base = image.convert(numChannels: 4);
    final fontSize = math.max(10.0, base.width * sizePercent / 100);
    final textImg = await _renderText(
      text,
      fontSize: fontSize,
      color: Color.fromARGB((255 * opacity).round(), color.$1, color.$2, color.$3),
      lineSpacing: 2,
    );
    final tw = textImg.width;
    final th = textImg.height;

    final logoW = math.max(10, (base.width * logoSizePercent / 100).round());
    final logo = _loadLogo(logoPath, logoW, opacity);
    final lw = logo.width;
    final lh = logo.height;
    final gap = math.max(4, (base.height * 0.005).round());

    final stampW = math.max(tw, lw);
    final stampH = th + gap + lh;
    final textDx = (stampW - tw) ~/ 2;
    final logoDx = (stampW - lw) ~/ 2;
    final textDy = order == 'text_above_logo' ? 0 : lh + gap;
    final logoDy = order == 'text_above_logo' ? th + gap : 0;

    final tiled = _tileLayer(
      (base.width, base.height),
      stampW + spacing,
      stampH + spacing,
      angle,
      (layer, col, row) {
        img.compositeImage(layer, textImg, dstX: col + textDx, dstY: row + textDy);
        final lx = col + logoDx;
        final ly = row + logoDy;
        if (lx + lw > 0 && ly + lh > 0 && lx < layer.width && ly < layer.height) {
          img.compositeImage(layer, logo, dstX: lx, dstY: ly);
        }
      },
    );
    return img.compositeImage(base, tiled);
  }

  img.Image _loadLogo(String logoPath, int targetWidthPx, double opacity) {
    final bytes = File(logoPath).readAsBytesSync();
    var logo = img.decodeImage(bytes);
    if (logo == null) throw Exception('Cannot decode logo: $logoPath');
    logo = img.bakeOrientation(logo);
    logo = logo.convert(numChannels: 4);
    final ratio = targetWidthPx / logo.width;
    logo = img.copyResize(
      logo,
      width: targetWidthPx,
      height: math.max(1, (logo.height * ratio).round()),
      interpolation: img.Interpolation.linear,
    );
    return _applyOpacity(logo, opacity);
  }

  img.Image _applyOpacity(img.Image image, double opacity) {
    final out = img.Image.from(image);
    for (final p in out) {
      p.a = (p.a * opacity).round().clamp(0, 255);
    }
    return out;
  }

  (int, int) _calcXy(
    int baseW,
    int baseH,
    int elemW,
    int elemH,
    String position,
    int offset,
  ) {
    final pos = _positionMap[position] ?? ('right', 'bottom');
    final h = pos.$1;
    final v = pos.$2;
    final x = h == 'left'
        ? offset
        : h == 'right'
            ? baseW - elemW - offset
            : (baseW - elemW) ~/ 2;
    final y = v == 'top'
        ? offset
        : v == 'bottom'
            ? baseH - elemH - offset
            : (baseH - elemH) ~/ 2;
    return (x, y);
  }

  img.Image _tileLayer(
    (int, int) baseSize,
    int stepX,
    int stepY,
    double angle,
    void Function(img.Image layer, int col, int row) stampFn,
  ) {
    final diag = math.sqrt(baseSize.$1 * baseSize.$1 + baseSize.$2 * baseSize.$2).ceil();
    final layer = img.Image(width: diag * 2, height: diag * 2, numChannels: 4);
    stepX = math.max(stepX, 1);
    stepY = math.max(stepY, 1);
    for (var row = -diag; row < diag * 2; row += stepY) {
      for (var col = -diag; col < diag * 2; col += stepX) {
        stampFn(layer, col, row);
      }
    }
    final rotated = img.copyRotate(layer, angle: angle);
    final cx = (rotated.width - baseSize.$1) ~/ 2;
    final cy = (rotated.height - baseSize.$2) ~/ 2;
    return img.copyCrop(
      rotated,
      x: cx,
      y: cy,
      width: baseSize.$1,
      height: baseSize.$2,
    );
  }

  Future<img.Image> _renderText(
    String text, {
    required double fontSize,
    required Color color,
    int lineSpacing = 4,
    TextAlign align = TextAlign.left,
  }) async {
    final lines = text.split('\n');
    final style = TextStyle(
      fontSize: fontSize,
      color: color,
      fontFamily: 'Segoe UI',
      height: 1.0,
    );

    double maxW = 1;
    double totalH = 0;
    final lineMetrics = <({double w, double h, String line})>[];

    for (final line in lines) {
      final tp = _measureText(line.isEmpty ? ' ' : line, style);
      lineMetrics.add((w: tp.width, h: tp.height, line: line));
      maxW = math.max(maxW, tp.width);
      totalH += tp.height;
    }
    if (lines.length > 1) totalH += lineSpacing * (lines.length - 1);

    final w = maxW.ceil().clamp(1, 10000);
    final h = totalH.ceil().clamp(1, 10000);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    var y = 0.0;
    for (var i = 0; i < lineMetrics.length; i++) {
      final m = lineMetrics[i];
      final tp = TextPainter(
        text: TextSpan(text: m.line.isEmpty ? ' ' : m.line, style: style),
        textAlign: align,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxW);
      var x = 0.0;
      if (align == TextAlign.center) x = (maxW - m.w) / 2;
      tp.paint(canvas, Offset(x, y));
      y += m.h + (i < lineMetrics.length - 1 ? lineSpacing : 0);
    }

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(w, h);
    final data = await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    uiImage.dispose();
    if (data == null) {
      return img.Image(width: 1, height: 1, numChannels: 4);
    }
    return img.Image.fromBytes(
      width: w,
      height: h,
      bytes: data.buffer,
      numChannels: 4,
      order: img.ChannelOrder.rgba,
    );
  }

  TextPainter _measureText(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  Future<Uint8List> encodePreviewPng(img.Image image, {int maxW = 900, int maxH = 700}) async {
    var out = image;
    if (out.width > maxW || out.height > maxH) {
      out = img.copyResize(
        out,
        width: out.width > maxW ? maxW : null,
        height: out.height > maxH ? maxH : null,
        maintainAspect: true,
        interpolation: img.Interpolation.linear,
      );
    }
    return Uint8List.fromList(img.encodePng(out));
  }
}
