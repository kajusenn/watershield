import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/app_model.dart';
import '../services/app_controller.dart';
import '../services/file_service.dart';
import '../theme/app_theme.dart';
import 'custom_widgets.dart';

class FileList extends StatefulWidget {
  const FileList({
    super.key,
    required this.controller,
    this.onSelectionChanged,
  });

  final AppController controller;
  final VoidCallback? onSelectionChanged;

  @override
  State<FileList> createState() => _FileListState();
}

class _FileListState extends State<FileList> {
  String? _expandedPath;

Future<void> _pickFiles() async {
  const group = XTypeGroup(
    label: 'Images & PDF',
    extensions: ['jpg', 'jpeg', 'png', 'bmp', 'webp', 'tiff', 'pdf'],
  );
  
  final result = await openFiles(acceptedTypeGroups: [group]);
  if (result == null || result.isEmpty) return;
  
  final paths = FileService.filterSupportedFiles(
    result.map((xfile) => xfile.path).whereType<String>().toList(),
  );
  if (paths.isEmpty) return;

  final app = context.read<AppModel>();
  app.addFiles(paths);
  for (final path in paths) {
    _loadThumb(path);
  }
}

  Future<void> _loadThumb(String path) async {
    final bytes = await widget.controller.loadThumbnail(path);
    if (!mounted || bytes == null) return;
    context.read<AppModel>().setThumbnail(path, bytes);
  }

  void _onThumbTap(String path) {
    setState(() {
      _expandedPath = _expandedPath == path ? null : path;
    });
    context.read<AppModel>().selectFile(path);
    widget.onSelectionChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppModel>(
      builder: (context, app, _) {
        return ColoredBox(
          color: AppColors.surf,
          child: Column(
            children: [
              PanelHeader(
                title: 'FILES',
                trailing: Text(
                  '${app.files.length} file${app.files.length == 1 ? '' : 's'}',
                  style: const TextStyle(color: AppColors.dim, fontSize: 10),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: WmPrimaryButton(
                        label: '＋  Add Files',
                        height: 36,
                        onPressed: _pickFiles,
                      ),
                    ),
                    const SizedBox(width: 6),
                    WmDangerButton(
                      label: '✕  Clear',
                      height: 36,
                      width: 72,
                      onPressed: app.files.isEmpty
                          ? null
                          : () {
                              setState(() => _expandedPath = null);
                              app.clearFiles();
                            },
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              if (_expandedPath != null)
                _ExpandedThumb(
                  file: app.files.firstWhere((f) => f.path == _expandedPath),
                  onTap: () => _onThumbTap(_expandedPath!),
                ),
              Expanded(
                child: app.files.isEmpty
                    ? const Center(
                        child: Text(
                          'No files yet',
                          style: TextStyle(color: AppColors.dim, fontSize: 12),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(6),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                            MediaQuery.of(context).size.width < 600 ? 2 : 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: app.files.where((f) => f.path != _expandedPath).length,
                        itemBuilder: (context, index) {
                          final visible = app.files.where((f) => f.path != _expandedPath).toList();
                          final file = visible[index];
                          final selected = app.selectedPath == file.path;
                          return _ThumbTile(
                            name: FileService.getFileDisplayName(file.path),
                            bytes: file.thumbnailBytes,
                            loading: file.loadingThumb,
                            selected: selected,
                            onTap: () => _onThumbTap(file.path),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ExpandedThumb extends StatelessWidget {
  const _ExpandedThumb({required this.file, required this.onTap});

  final SelectedFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(4),
        height: 265,
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.accent, width: 1.2),
        ),
        child: Column(
          children: [
            Expanded(
              child: _ThumbImage(bytes: file.thumbnailBytes, loading: file.loadingThumb),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                _shortName(FileService.getFileDisplayName(file.path), 20),
                style: const TextStyle(color: AppColors.dim, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    required this.name,
    required this.bytes,
    required this.loading,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Uint8List? bytes;
  final bool loading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: selected ? 1 : 0.88,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.accent : AppColors.border,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Column(
            children: [
              Expanded(child: _ThumbImage(bytes: bytes, loading: loading)),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  _shortName(name, 14),
                  style: const TextStyle(color: AppColors.dim, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbImage extends StatelessWidget {
  const _ThumbImage({required this.bytes, required this.loading});

  final Uint8List? bytes;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
        ),
      );
    }
    if (bytes == null) {
      return const Icon(Icons.broken_image, color: AppColors.dim, size: 28);
    }
    return Padding(
      padding: const EdgeInsets.all(2),
      child: Image.memory(bytes!, fit: BoxFit.contain),
    );
  }
}

String _shortName(String name, int max) {
  if (name.length <= max + 1) return name;
  return '${name.substring(0, max)}…';
}
