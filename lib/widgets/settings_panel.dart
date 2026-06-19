import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../models/app_model.dart';
import '../models/settings_model.dart';
import '../services/app_controller.dart';
import '../theme/app_theme.dart';
import 'custom_widgets.dart';

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({
    super.key,
    required this.controller,
    required this.onSettingsChanged,
    required this.onExport,
  });

  final AppController controller;
  final VoidCallback onSettingsChanged;
  final Future<void> Function() onExport;

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late final TextEditingController _textController;
  Uint8List? _logoThumb;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsModel>();
    _textController = TextEditingController(text: settings.text);
    _loadLogoThumb(settings.logoPath);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadLogoThumb(String? path) async {
    if (path == null || path.isEmpty) {
      setState(() => _logoThumb = null);
      return;
    }
    final bytes = await widget.controller.loadThumbnail(path);
    if (mounted) setState(() => _logoThumb = bytes);
  }

Future<void> _pickLogo() async {
  const group = XTypeGroup(
    label: 'Logo Image',
    extensions: ['png', 'jpg', 'jpeg', 'webp'],
  );
  
  final result = await openFile(acceptedTypeGroups: [group]);
  if (result == null) return;
  
  final path = result.path;
  if (path == null || path.isEmpty) return;

  final settings = context.read<SettingsModel>();
  settings.setLogoPath(path);
  await widget.controller.saveLogoPath(path);
  await _loadLogoThumb(path);
  widget.onSettingsChanged();
}

  int _wmTypeIndex(SettingsModel s) {
    switch (s.wmType) {
      case 'logo':
        return 1;
      case 'logo_text':
        return 2;
      default:
        return 0;
    }
  }

  void _setWmType(int i) {
    final settings = context.read<SettingsModel>();
    settings.setWmType(switch (i) {
      1 => 'logo',
      2 => 'logo_text',
      _ => 'text',
    });
    widget.onSettingsChanged();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsModel, AppModel>(
      builder: (context, settings, app, _) {
        final showText = settings.wmType == 'text' || settings.wmType == 'logo_text';
        final showLogo = settings.wmType == 'logo' || settings.wmType == 'logo_text';
        final showOrder = settings.wmType == 'logo_text';
        final corner = settings.mode == 'corner';

        return ColoredBox(
          color: AppColors.surf,
          child: Column(
            children: [
              const PanelHeader(title: 'SETTINGS'),
              const Divider(height: 1, color: AppColors.border),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SectionHeader('Watermark Type'),
                      const SizedBox(height: 6),
                      WmToggleGroup(
                        options: const ['📝  Text', '🖼  Logo', '📝+🖼  Both'],
                        selectedIndex: _wmTypeIndex(settings),
                        onChanged: _setWmType,
                      ),

                      if (showText) ...[
                        const SectionHeader('Watermark Text'),
                        const SizedBox(height: 6),
                        WmTextField(
                          controller: _textController,
                          hint: 'Use Enter for new lines',
                          onChanged: (v) {
                            settings.setText(v);
                            widget.onSettingsChanged();
                          },
                        ),
                      ],

                      if (showLogo) ...[
                        const SectionHeader('Logo'),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: _logoThumb != null
                                  ? Image.memory(_logoThumb!, fit: BoxFit.contain)
                                  : const Icon(Icons.image, color: AppColors.dim),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    settings.logoPath != null
                                        ? p.basename(settings.logoPath!)
                                        : 'No logo selected',
                                    style: TextStyle(
                                      color: settings.logoPath == null
                                          ? AppColors.dim
                                          : AppColors.fg2,
                                      fontSize: 10,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  WmPrimaryButton(
                                    label: '📂  Choose Logo',
                                    height: 32,
                                    onPressed: _pickLogo,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        WmSliderRow(
                          label: 'Logo Size  —  ${settings.logoSize.round()}%',
                          value: settings.logoSize,
                          min: 2,
                          max: 50,
                          divisions: 48,
                          onChanged: (v) {
                            settings.setLogoSize(v);
                            widget.onSettingsChanged();
                          },
                        ),
                      ],

                      if (showOrder) ...[
                        const SectionHeader('Stack Order'),
                        const SizedBox(height: 6),
                        WmToggleGroup(
                          options: const ['📝 top  ·  🖼 bottom', '🖼 top  ·  📝 bottom'],
                          selectedIndex: settings.order == 'text_above_logo' ? 0 : 1,
                          fontSize: 11,
                          onChanged: (i) {
                            settings.setOrder(
                              i == 0 ? 'text_above_logo' : 'logo_above_text',
                            );
                            widget.onSettingsChanged();
                          },
                        ),
                      ],

                      const SizedBox(height: 4),
                      const Divider(color: AppColors.border),
                      const SectionHeader('Mode'),
                      const SizedBox(height: 6),
                      WmToggleGroup(
                        options: const ['Corner', 'Tile'],
                        selectedIndex: corner ? 0 : 1,
                        onChanged: (i) {
                          settings.setMode(i == 0 ? 'corner' : 'tile');
                          widget.onSettingsChanged();
                        },
                      ),
                      const SizedBox(height: 6),

                      if (corner) ...[
                        const Text('Position', style: TextStyle(color: AppColors.fg2, fontSize: 12)),
                        const SizedBox(height: 4),
                        WmDropdown(
                          value: settings.position,
                          items: SettingsModel.positions,
                          onChanged: (v) {
                            if (v != null) {
                              settings.setPosition(v);
                              widget.onSettingsChanged();
                            }
                          },
                        ),
                        const SizedBox(height: 4),
                        WmSliderRow(
                          label: 'Edge Offset  —  ${settings.offset} px',
                          value: settings.offset.toDouble(),
                          min: 0,
                          max: 200,
                          divisions: 200,
                          onChanged: (v) {
                            settings.setOffset(v.round());
                            widget.onSettingsChanged();
                          },
                        ),
                      ] else ...[
                        WmSliderRow(
                          label: 'Tile Spacing  —  ${settings.spacing} px',
                          value: settings.spacing.toDouble(),
                          min: 0,
                          max: 800,
                          divisions: 80,
                          onChanged: (v) {
                            settings.setSpacing(v.round());
                            widget.onSettingsChanged();
                          },
                        ),
                        WmSliderRow(
                          label: 'Rotation  —  ${settings.angle.round()}°',
                          value: settings.angle,
                          min: -90,
                          max: 90,
                          divisions: 36,
                          onChanged: (v) {
                            settings.setAngle(v);
                            widget.onSettingsChanged();
                          },
                        ),
                      ],

                      const SizedBox(height: 4),
                      const Divider(color: AppColors.border),
                      const SectionHeader('Appearance'),
                      const SizedBox(height: 6),
                      WmSliderRow(
                        label: 'Opacity  —  ${(settings.opacity * 100).round()}%',
                        value: settings.opacity * 100,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: (v) {
                          settings.setOpacity(v / 100);
                          widget.onSettingsChanged();
                        },
                      ),
                      if (showText)
                        WmSliderRow(
                          label: 'Text Size  —  ${settings.textSize.round()}%',
                          value: settings.textSize,
                          min: 1,
                          max: 30,
                          divisions: 29,
                          onChanged: (v) {
                            settings.setTextSize(v);
                            widget.onSettingsChanged();
                          },
                        ),

                      const SizedBox(height: 4),
                      const Divider(color: AppColors.border),
                      const SectionHeader('Color'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: settings.color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'R: ${settings.colorRgb.$1}   G: ${settings.colorRgb.$2}   B: ${settings.colorRgb.$3}',
                              style: const TextStyle(color: AppColors.fg2, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      WmSliderRow(
                        label: 'R  —  ${settings.colorRgb.$1}',
                        value: settings.colorRgb.$1.toDouble(),
                        min: 0,
                        max: 255,
                        divisions: 255,
                        onChanged: (v) {
                          final c = settings.colorRgb;
                          settings.setColorRgb(v.round(), c.$2, c.$3);
                          widget.onSettingsChanged();
                        },
                      ),
                      WmSliderRow(
                        label: 'G  —  ${settings.colorRgb.$2}',
                        value: settings.colorRgb.$2.toDouble(),
                        min: 0,
                        max: 255,
                        divisions: 255,
                        onChanged: (v) {
                          final c = settings.colorRgb;
                          settings.setColorRgb(c.$1, v.round(), c.$3);
                          widget.onSettingsChanged();
                        },
                      ),
                      WmSliderRow(
                        label: 'B  —  ${settings.colorRgb.$3}',
                        value: settings.colorRgb.$3.toDouble(),
                        min: 0,
                        max: 255,
                        divisions: 255,
                        onChanged: (v) {
                          final c = settings.colorRgb;
                          settings.setColorRgb(c.$1, c.$2, v.round());
                          widget.onSettingsChanged();
                        },
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final preset in _colorPresets)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Material(
                                  color: preset.color,
                                  borderRadius: BorderRadius.circular(4),
                                  child: InkWell(
                                    onTap: () {
                                      settings.setColorRgb(
                                        preset.rgb.$1,
                                        preset.rgb.$2,
                                        preset.rgb.$3,
                                      );
                                      widget.onSettingsChanged();
                                    },
                                    child: Container(
                                      height: 32,
                                      alignment: Alignment.center,
                                      child: Text(
                                        preset.name,
                                        style: TextStyle(
                                          color: preset.textColor,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Container(
                color: AppColors.card,
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: app.exporting ? app.exportProgress : 0,
                        minHeight: 4,
                        backgroundColor: AppColors.border,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      app.statusText,
                      style: TextStyle(color: app.statusColor, fontSize: 10),
                    ),
                    const SizedBox(height: 6),
                    WmSuccessButton(
                      label: app.exporting ? 'Processing…' : '⚡  Generate / Export',
                      height: 44,
                      onPressed: app.exporting ? null : () => widget.onExport(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ColorPreset {
  _ColorPreset(this.name, (int, int, int) rgb, this.textColor)
      : rgb = rgb,
        color = Color.fromARGB(255, rgb.$1, rgb.$2, rgb.$3);

  final String name;
  final (int, int, int) rgb;
  final Color color;
  final Color textColor;
}

// USUNIĘTO 'const' - to była przyczyna błędu
final _colorPresets = [
  _ColorPreset('White', (255, 255, 255), Colors.black),
  _ColorPreset('Black', (0, 0, 0), Color(0xFFCCCCCC)),
  _ColorPreset('Red', (210, 50, 50), Colors.white),
  _ColorPreset('Gold', (255, 195, 0), Colors.black),
  _ColorPreset('Blue', (55, 120, 220), Colors.white),
];