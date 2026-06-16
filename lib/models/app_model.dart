import 'dart:typed_data';

import 'package:flutter/material.dart';

class SelectedFile {
  SelectedFile({required this.path});

  final String path;
  Uint8List? thumbnailBytes;
  bool loadingThumb = true;
}

class AppModel extends ChangeNotifier {
  final List<SelectedFile> files = [];
  String? selectedPath;
  int pdfPageIndex = 0;
  int pdfPageCount = 1;

  bool exporting = false;
  double exportProgress = 0;
  String statusText = 'Ready';
  Color statusColor = const Color(0xFF5E6678);

  Uint8List? previewBytes;
  String previewStatus = 'Select a file to preview';
  bool previewLoading = false;

  void addFiles(List<String> paths) {
    final existing = files.map((f) => f.path).toSet();
    for (final p in paths) {
      if (!existing.contains(p)) {
        files.add(SelectedFile(path: p));
      }
    }
    notifyListeners();
  }

  void clearFiles() {
    files.clear();
    selectedPath = null;
    pdfPageIndex = 0;
    pdfPageCount = 1;
    previewBytes = null;
    previewStatus = 'Select a file to preview';
    notifyListeners();
  }

  void selectFile(String path) {
    selectedPath = path;
    pdfPageIndex = 0;
    notifyListeners();
  }

  void setPdfPageCount(int count) {
    pdfPageCount = count.clamp(1, 99999);
    if (pdfPageIndex >= pdfPageCount) {
      pdfPageIndex = pdfPageCount - 1;
    }
    notifyListeners();
  }

  void setPdfPageIndex(int index) {
    pdfPageIndex = index.clamp(0, pdfPageCount - 1);
    notifyListeners();
  }

  void setThumbnail(String path, Uint8List bytes) {
    for (final f in files) {
      if (f.path == path) {
        f.thumbnailBytes = bytes;
        f.loadingThumb = false;
        notifyListeners();
        return;
      }
    }
  }

  void setPreview(Uint8List? bytes, {String status = ''}) {
    previewBytes = bytes;
    previewLoading = false;
    if (status.isNotEmpty) previewStatus = status;
    notifyListeners();
  }

  void setPreviewLoading() {
    previewLoading = true;
    notifyListeners();
  }

  void setExportState({
    required bool exporting,
    double progress = 0,
    String status = 'Ready',
    Color? color,
  }) {
    this.exporting = exporting;
    exportProgress = progress;
    statusText = status;
    if (color != null) statusColor = color;
    notifyListeners();
  }
}
