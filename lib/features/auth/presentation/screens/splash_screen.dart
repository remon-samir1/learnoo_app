import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
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
    _checkForUpdates();
  }

  /// First check for app updates, then proceed with auth
  Future<void> _checkForUpdates() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    final updateInfo = await _authRepository.checkForUpdate();

    if (updateInfo != null && updateInfo['hasUpdate'] == true) {
      if (mounted) {
        _showUpdateDialog(updateInfo);
      }
    } else {
      // No update needed, proceed with auth check
      _checkAuth();
    }
  }

  /// Show update dialog with optional skip based on is_force_update
  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    final isForceUpdate = updateInfo['isForceUpdate'] ?? false;
    final versionName = updateInfo['versionName'] ?? '';
    final fileSize = updateInfo['fileSize'] ?? '';
    final downloadUrl = updateInfo['downloadUrl'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => WillPopScope(
        onWillPop: () async => !isForceUpdate,
        child: AlertDialog(
          title: Text('update_available'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${'new_version'.tr()}: $versionName'),
              if (fileSize != null && fileSize.isNotEmpty)
                Text('${'file_size'.tr()}: $fileSize'),
              const SizedBox(height: 16),
              Text(
                isForceUpdate
                    ? 'force_update_message'.tr()
                    : 'optional_update_message'.tr(),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            if (!isForceUpdate)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _checkAuth();
                },
                child: Text('skip'.tr()),
              ),
            ElevatedButton(
              onPressed: () async {
                if (downloadUrl.isNotEmpty) {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                }
              },
              child: Text('update_now'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkAuth() async {
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
