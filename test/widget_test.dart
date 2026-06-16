import 'package:flutter_test/flutter_test.dart';
import 'package:watermark_app/models/settings_model.dart';

void main() {
  test('SettingsModel defaults match Python app', () {
    final s = SettingsModel();
    expect(s.wmType, 'text');
    expect(s.mode, 'corner');
    expect(s.position, 'bottom-right');
    expect(s.opacity, 0.5);
    expect(s.textSize, 5.0);
    expect(s.logoSize, 15.0);
    expect(s.offset, 20);
    expect(s.spacing, 60);
    expect(s.angle, -30.0);
  });
}
