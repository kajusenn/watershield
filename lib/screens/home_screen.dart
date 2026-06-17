import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_model.dart';
import '../models/settings_model.dart';
import '../services/app_controller.dart';
import '../services/file_service.dart';
import '../theme/app_theme.dart';
import '../widgets/custom_widgets.dart';
import '../widgets/file_list.dart';
import '../widgets/preview_panel.dart';
import '../widgets/settings_panel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _previewDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await widget.controller.loadSavedLogo(context.read<SettingsModel>());
    });
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    super.dispose();
  }

  void _schedulePreview() {
    _previewDebounce?.cancel();
    _previewDebounce = Timer(const Duration(milliseconds: 350), _refreshPreview);
  }

  Future<void> _refreshPreview() async {
    if (!mounted) return;
    final app = context.read<AppModel>();
    final settings = context.read<SettingsModel>();
    final path = app.selectedPath;
    if (path == null) return;

    app.setPreviewLoading();
    try {
      if (path.toLowerCase().endsWith('.pdf')) {
        final count = await widget.controller.pdfPageCount(path);
        app.setPdfPageCount(count);
      } else {
        app.setPdfPageCount(1);
      }

      final bytes = await widget.controller.renderPreview(
        path: path,
        settings: settings,
        pdfPageIndex: app.pdfPageIndex,
      );
      app.setPreview(bytes, status: '');
    } catch (e) {
      app.setPreview(null, status: 'Preview error: $e');
    }
  }

  Future<void> _onExport() async {
    final app = context.read<AppModel>();
    final settings = context.read<SettingsModel>();
    final paths = app.files.map((f) => f.path).toList();

    if (paths.isEmpty) {
      showWmDialog(
        context,
        "No files loaded.\nClick '＋ Add Files' to get started.",
      );
      return;
    }
    if (settings.wmType == 'text' && settings.text.trim().isEmpty) {
      showWmDialog(context, 'Watermark text is empty.');
      return;
    }
    if ((settings.wmType == 'logo' || settings.wmType == 'logo_text') &&
        (settings.logoPath == null || settings.logoPath!.isEmpty)) {
      showWmDialog(
        context,
        "No logo selected.\nClick '📂 Choose Logo' to pick one.",
      );
      return;
    }

    app.setExportState(
      exporting: true,
      progress: 0,
      status: 'Working…',
      color: AppColors.dim,
    );

    try {
      await widget.controller.exportFiles(
        paths: paths,
        settings: settings,
        onProgress: (p) {
          app.setExportState(
            exporting: true,
            progress: p,
            status: 'Working…',
            color: AppColors.dim,
          );
        },
        onStatus: (status, color) {
          app.setExportState(
            exporting: false,
            progress: 1,
            status: status,
            color: color,
          );
        },
      );
      if (!mounted) return;
      final outDir = await FileService.getOutputDirAbsolute();
      showWmDialog(
        context,
        'Done!\n${paths.length} file(s) saved to:\n$outDir',
      );
    } on ExportException catch (e) {
      if (mounted) showWmDialog(context, 'Errors:\n$e');
    } finally {
      if (mounted) {
        app.setExportState(
          exporting: false,
          progress: app.exportProgress,
          status: app.statusText,
          color: app.statusColor,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;

          if (isMobile) {
            return DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const Material(
                    color: AppColors.card,
                    child: TabBar(
                      tabs: [
                        Tab(text: 'FILES'),
                        Tab(text: 'SETTINGS'),
                        Tab(text: 'PREVIEW'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        FileList(
                          controller: widget.controller,
                          onSelectionChanged: _schedulePreview,
                        ),
                        SettingsPanel(
                          controller: widget.controller,
                          onSettingsChanged: _schedulePreview,
                          onExport: _onExport,
                        ),
                        PreviewPanel(
                          onPrevPage: () {
                            context.read<AppModel>().setPdfPageIndex(
                              context.read<AppModel>().pdfPageIndex - 1,
                            );
                            _schedulePreview();
                          },
                          onNextPage: () {
                            context.read<AppModel>().setPdfPageIndex(
                              context.read<AppModel>().pdfPageIndex + 1,
                            );
                            _schedulePreview();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return Row(
            children: [
              Expanded(
                flex: 30,
                child: FileList(
                  controller: widget.controller,
                  onSelectionChanged: _schedulePreview,
                ),
              ),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(
                flex: 33,
                child: SettingsPanel(
                  controller: widget.controller,
                  onSettingsChanged: _schedulePreview,
                  onExport: _onExport,
                ),
              ),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(
                flex: 37,
                child: PreviewPanel(
                  onPrevPage: () {
                    context.read<AppModel>().setPdfPageIndex(
                      context.read<AppModel>().pdfPageIndex - 1,
                    );
                    _schedulePreview();
                  },
                  onNextPage: () {
                    context.read<AppModel>().setPdfPageIndex(
                      context.read<AppModel>().pdfPageIndex + 1,
                    );
                    _schedulePreview();
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
