import 'package:flutter/material.dart';

class SettingsModel extends ChangeNotifier {
  String wmType = 'text'; // text | logo | logo_text
  String mode = 'corner'; // corner | tile
  String position = 'bottom-right';
  double opacity = 0.5;
  double textSize = 5.0;
  double logoSize = 15.0;
  int offset = 20;
  int spacing = 60;
  double angle = -30.0;
  String text = '© WaterShield';
  String? logoPath;
  String order = 'text_above_logo'; // text_above_logo | logo_above_text
  Color color = Colors.white;

  static const positions = [
    'top-left',
    'top-center',
    'top-right',
    'center',
    'bottom-left',
    'bottom-center',
    'bottom-right',
  ];

  Map<String, dynamic> toMap() {
    final rgb = colorRgb;
    return {
      'wm_type': wmType,
      'mode': mode,
      'position': position,
      'opacity': opacity,
      'size_percent': textSize,
      'offset': offset,
      'spacing': spacing,
      'angle': angle,
      'text': text.trim(),
      'logo_path': logoPath ?? '',
      'logo_size_percent': logoSize,
      'order': order,
      'color': rgb,
    };
  }

  /// RGB tuple like Python settings dict.
  (int, int, int) get colorRgb => (
        (color.r * 255).round(),
        (color.g * 255).round(),
        (color.b * 255).round(),
      );

  void setWmType(String v) {
    wmType = v;
    notifyListeners();
  }

  void setMode(String v) {
    mode = v;
    notifyListeners();
  }

  void setPosition(String v) {
    position = v;
    notifyListeners();
  }

  void setOpacity(double v) {
    opacity = v;
    notifyListeners();
  }

  void setTextSize(double v) {
    textSize = v;
    notifyListeners();
  }

  void setLogoSize(double v) {
    logoSize = v;
    notifyListeners();
  }

  void setOffset(int v) {
    offset = v;
    notifyListeners();
  }

  void setSpacing(int v) {
    spacing = v;
    notifyListeners();
  }

  void setAngle(double v) {
    angle = v;
    notifyListeners();
  }

  void setText(String v) {
    text = v;
    notifyListeners();
  }

  void setLogoPath(String? v) {
    logoPath = v;
    notifyListeners();
  }

  void setOrder(String v) {
    order = v;
    notifyListeners();
  }

  void setColor(Color v) {
    color = v;
    notifyListeners();
  }

  void setColorRgb(int r, int g, int b) {
    color = Color.fromARGB(255, r, g, b);
    notifyListeners();
  }
}
