import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_model.dart';
import '../services/file_service.dart';
import '../theme/app_theme.dart';
import 'custom_widgets.dart';

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({
    super.key,
    required this.onPrevPage,
    required this.onNextPage,
  });

  final VoidCallback onPrevPage;
  final VoidCallback onNextPage;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, app, _) {
        final isPdf = app.selectedPath != null &&
            app.selectedPath!.toLowerCase().endsWith('.pdf');
        final showNav = isPdf && app.pdfPageCount > 1;
        final fileName = app.selectedPath != null
            ? FileService.getFileDisplayName(app.selectedPath!)
            : '';

        return ColoredBox(
          color: AppColors.surf,
          child: Column(
            children: [
              PanelHeader(
                title: 'PREVIEW',
                trailing: Text(
                  fileName,
                  style: const TextStyle(color: AppColors.dim, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: Container(
                  color: AppColors.surf,
                  padding: const EdgeInsets.all(8),
                  child: app.selectedPath == null
                      ? const Center(
                          child: Text(
                            'Select a file to preview',
                            style: TextStyle(color: AppColors.dim, fontSize: 12),
                          ),
                        )
                      : app.previewLoading
                          ? const Center(
                              child: CircularProgressIndicator(color: AppColors.accent),
                            )
                          : app.previewBytes != null
                              ? Image.memory(app.previewBytes!, fit: BoxFit.contain)
                              : Center(
                                  child: Text(
                                    app.previewStatus,
                                    style: const TextStyle(color: AppColors.dim, fontSize: 11),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                ),
              ),
              if (showNav)
                Container(
                  color: AppColors.card,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      WmButton(
                        label: '◀',
                        onPressed: app.pdfPageIndex > 0 ? onPrevPage : null,
                        height: 30,
                        expand: false,
                      ),
                      Expanded(
                        child: Text(
                          'Page ${app.pdfPageIndex + 1} / ${app.pdfPageCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.fg2, fontSize: 11),
                        ),
                      ),
                      WmButton(
                        label: '▶',
                        onPressed: app.pdfPageIndex < app.pdfPageCount - 1
                            ? onNextPage
                            : null,
                        height: 30,
                        expand: false,
                      ),
                    ],
                  ),
                ),
              const Divider(height: 1, color: AppColors.border),
              Container(
                color: AppColors.card,
                height: 24,
                alignment: Alignment.center,
                child: Text(
                  app.previewStatus,
                  style: const TextStyle(color: AppColors.dim, fontSize: 10),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
