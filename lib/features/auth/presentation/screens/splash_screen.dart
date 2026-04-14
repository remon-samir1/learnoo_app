import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import 'profile_screen.dart';
import 'verification_method_screen.dart';
import '../../data/auth_repository.dart';
import '../../../../features/home/presentation/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    final token = await _authRepository.getToken();
    if (token == null) {
      _navigateToProfile();
      return;
    }

    final result = await _authRepository.getProfile();
    if (result['success']) {
      final profileData = result['data'];

      // Check if the user has verified their email or phone.
      // If both are null, the account is unverified — send to verification flow.
      final attributes = profileData?['attributes'] ?? profileData;
      final emailVerifiedAt = attributes?['email_verified_at'];
      final phoneVerifiedAt = attributes?['phone_verified_at'];
      final isVerified = emailVerifiedAt != null || phoneVerifiedAt != null;

      if (!isVerified) {
        // User registered but never verified — redirect to verification
        if (mounted) {
          final email = profileData?['email'] ?? '';
          final phone = profileData?['phone'] ?? '';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationMethodScreen(
                token: token,
                email: email,
                phone: phone,
              ),
            ),
          );
        }
        return;
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } else {
      // If 401 or other error, go to profile/register
      _navigateToProfile();
    }
  }

  void _navigateToProfile() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/student_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Blue Overlay (Using semi-transparent primary blue)
          Positioned.fill(
            child: Container(
              color: AppColors.primaryBlue.withValues(alpha: 0.85),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 100),
                const SizedBox(height: 15),
                const Text(
                  'Learnoo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'auth.academic_journey'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
