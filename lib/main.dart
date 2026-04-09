import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/services/screen_protection_service.dart';
import 'features/auth/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  runApp(const LearnooApp());
}

class LearnooApp extends StatelessWidget {
  const LearnooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
