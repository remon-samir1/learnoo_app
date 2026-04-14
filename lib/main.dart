import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'core/services/screen_protection_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  
  // Initialize screen protection service
  // This must be done before runApp()
  final screenProtection = ScreenProtectionService();
  await screenProtection.initialize();
  
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

class LearnooApp extends StatelessWidget {
  const LearnooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      title: 'Learnoo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter', // Defaulting to Roboto
      ),
      home: const SplashScreen(),
    );
  }
}
