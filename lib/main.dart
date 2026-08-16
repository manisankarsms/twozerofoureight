import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/save_manager.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'services/ad_service.dart';
import 'services/firebase_service.dart';
import 'services/purchase_service.dart';
import 'theme/app_theme.dart';

/// Notifier that triggers a full app rebuild when the theme changes.
final ValueNotifier<bool> themeNotifier = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Crashlytics before other asynchronous app services start.
  await FirebaseService.instance.initialize();

  // Initialize persistent game state.
  await SaveManager.instance.init();

  // Initialize monetization services. Release ads stay disabled until real
  // AdMob IDs are supplied through the documented dart-defines.
  await PurchaseService.instance.initialize();
  await AdService.instance.initialize();

  // Apply persisted theme preference.
  final isDark = SaveManager.instance.save.isDarkTheme;
  AppColors.setDark(isDark);
  themeNotifier.value = isDark;

  // Lock to portrait.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const TwoZeroFourEightApp());
}

class TwoZeroFourEightApp extends StatelessWidget {
  const TwoZeroFourEightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (context, isDark, _) {
        final analyticsObserver = FirebaseService.instance.analyticsObserver;
        return MaterialApp(
          title: '2048',
          navigatorObservers: [
            analyticsObserver?,
          ],
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const HomeScreen(),
          routes: {
            '/settings': (_) => SettingsScreen(
                  onThemeChanged: () async {
                    final isDark = !AppColors.isDark;
                    AppColors.setDark(isDark);
                    SaveManager.instance.save.isDarkTheme = isDark;
                    themeNotifier.value = isDark;
                    await SaveManager.instance.persist();
                  },
                ),
          },
        );
      },
    );
  }
}
