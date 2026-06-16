import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PanelHeader extends StatelessWidget {
  const PanelHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class WmButton extends StatelessWidget {
  const WmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.background = AppColors.btn,
    this.foreground = AppColors.fg,
    this.height = 44,
    this.fontSize = 13,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color background;
  final Color foreground;
  final double height;
  final double fontSize;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final btn = Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: TextStyle(color: foreground, fontSize: fontSize),
          ),
        ),
      ),
    );
    return expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class WmPrimaryButton extends StatelessWidget {
  const WmPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 44,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return WmButton(
      label: label,
      onPressed: onPressed,
      background: AppColors.accent,
      foreground: Colors.white,
      height: height,
      fontSize: onPressed == null ? 13 : 14,
      expand: expand,
    );
  }
}

class WmDangerButton extends StatelessWidget {
  const WmDangerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 44,
    this.width,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: WmButton(
        label: label,
        onPressed: onPressed,
        background: AppColors.danger,
        foreground: Colors.white,
        height: height,
        expand: width == null,
      ),
    );
  }
}

class WmSuccessButton extends StatelessWidget {
  const WmSuccessButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return WmButton(
      label: label,
      onPressed: onPressed,
      background: AppColors.success,
      foreground: Colors.white,
      height: height,
      fontSize: 15,
    );
  }
}

class WmToggleGroup extends StatelessWidget {
  const WmToggleGroup({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    this.height = 38,
    this.fontSize = 12,
  });

  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final double height;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(options.length, (i) {
        final selected = i == selectedIndex;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 4),
            child: Material(
              color: selected ? AppColors.accent : AppColors.btn,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => onChanged(i),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: height,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    options[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.fg2,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class WmSliderRow extends StatelessWidget {
  const WmSliderRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.fg2, fontSize: 12)),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class WmCard extends StatelessWidget {
  const WmCard({super.key, required this.child, this.padding = 12});

  final Widget child;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.surf,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class WmTextField extends StatelessWidget {
  const WmTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.maxLines = 4,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.fg, fontSize: 14),
        cursorColor: AppColors.accent,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.dim.withValues(alpha: 0.8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}

class WmDropdown extends StatelessWidget {
  const WmDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: AppColors.fg, fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

void showWmDialog(BuildContext context, String message, {String title = 'Watermark Tool'}) {
  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.card,
      title: Text(title, style: const TextStyle(color: AppColors.fg, fontSize: 13)),
      content: Text(message, style: const TextStyle(color: AppColors.fg, fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('OK', style: TextStyle(color: AppColors.accent)),
        ),
      ],
    ),
  );
}
