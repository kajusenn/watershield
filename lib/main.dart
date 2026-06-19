import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/app_model.dart';
import 'models/settings_model.dart';
import 'screens/home_screen.dart';
import 'services/app_controller.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WatermarkApp());
}

class WatermarkApp extends StatelessWidget {
  const WatermarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppController();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsModel()),
        ChangeNotifierProvider(create: (_) => AppModel()),
      ],
      child: MaterialApp(
        title: 'WaterShield',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        home: HomeScreen(controller: controller),
      ),
    );
  }
}
