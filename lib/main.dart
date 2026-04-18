import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/services/screen_protection_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/feature_service.dart';
import 'core/services/feature_manager.dart';
import 'core/theme/dynamic_theme.dart';
import 'core/local/hive_service.dart';
import 'core/sync/sync_service.dart';
import 'core/sync/sync_processors.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Initialize Hive local database for offline storage
  // This must be done before any repository operations
  final hiveService = HiveService();
  await hiveService.initialize();

  // Initialize sync service for background synchronization
  final syncService = SyncService();
  await syncService.initialize();

  // Register all sync processors for pending actions
  // This enables offline queue to sync comments, progress, posts, etc.
  SyncProcessors.registerAll(syncService);

  // Initialize screen protection service
  // This must be done before runApp()
  final screenProtection = ScreenProtectionService();
  await screenProtection.initialize();

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Initialize FeatureManager (loads cached features first)
  final featureManager = FeatureManager();
  await featureManager.initialize();

  // Initialize FeatureService
  final featureService = FeatureService();
  await featureService.initialize();

  // Initialize DynamicThemeService
  final themeService = DynamicThemeService();
  await themeService.initialize();

  // Optional: Enable global protection for the entire app
  // Uncomment to protect all screens by default
  // await screenProtection.enableGlobalProtection();
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const LearnooApp(),
    ),
  );
}

class LearnooApp extends StatefulWidget {
  const LearnooApp({super.key});

  @override
  State<LearnooApp> createState() => _LearnooAppState();
}

class _LearnooAppState extends State<LearnooApp> {
  final DynamicThemeService _themeService = DynamicThemeService();
  final FeatureManager _featureManager = FeatureManager();

  @override
  void initState() {
    super.initState();
    _featureManager.addListener(_onFeaturesChanged);
  }

  @override
  void dispose() {
    _featureManager.removeListener(_onFeaturesChanged);
    super.dispose();
  }

  void _onFeaturesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: _featureManager.platformName,
      debugShowCheckedModeBanner: false,
      theme: _themeService.getLightTheme(),
      darkTheme: _themeService.getDarkTheme(),
      home: const SplashScreen(),
    );
  }
}
