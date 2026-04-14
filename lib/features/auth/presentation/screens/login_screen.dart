import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/widgets/primary_button.dart';
import '../screens/otp_verification_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../../data/auth_repository.dart';
import '../../../../features/academic/presentation/screens/university_selection_screen.dart';
import '../../../home/presentation/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepository = AuthRepository();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isEmailIdentifier(String input) {
    return input.contains('@');
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('auth.fill_all_fields'.tr())),
      );
      return;
    }

    setState(() => _isLoading = true);

    // 1. Login
    final loginResult = await _authRepository.login(
      identifier: identifier,
      password: password,
    );

    if (!loginResult['success']) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loginResult['message'] ?? 'auth.login_failed'.tr())),
        );
      }
      return;
    }

    // Login success, get token and profile info
    final token = loginResult['data']['meta']['token'];
    final attributes = loginResult['data']['data']['attributes'];
    final universityId = attributes['university_id'];
    final isEmail = _isEmailIdentifier(identifier);
    
    // Check if user is already verified
    final isEmailVerified = attributes['email_verified_at'] != null;
    final isPhoneVerified = attributes['phone_verified_at'] != null;
    final isVerified = isEmail ? isEmailVerified : isPhoneVerified;

    if (isVerified) {
      setState(() => _isLoading = false);
      if (mounted) {
        if (universityId != null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const UniversitySelectionScreen()),
            (route) => false,
          );
        }
      }
      return;
    }

    // 2. Call Verification API based on identifier type
    final verifyResult = isEmail
        ? await _authRepository.sendEmailVerification(token)
        : await _authRepository.sendPhoneVerification(token);

    setState(() => _isLoading = false);

    if (mounted) {
      if (verifyResult['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              isRegister: false,
              phone: identifier,
              token: token,
              isEmail: isEmail,
              universityId: universityId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(verifyResult['message'] ?? 'auth.failed_send_code'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header Section (unchanged style, just content)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 80, bottom: 50),
              decoration: const BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                children: [
                  const AppLogo(size: 85),
                  const SizedBox(height: 24),
                  Text(
                    'auth.welcome_login'.tr(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'auth.verify_identity_login'.tr(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Form Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextField(
                    label: 'auth.email_or_phone'.tr(), // Dynamic hint
                    hintText: 'auth.email_phone_hint'.tr(),
                    keyboardType: TextInputType.emailAddress,
                    controller: _identifierController,
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    label: 'auth.password'.tr(),
                    hintText: 'auth.enter_password'.tr(),
                    isPassword: true,
                    controller: _passwordController,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ForgotPasswordScreen(),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                      child: Text(
                        'auth.forget_password'.tr(),
                        style: const TextStyle(
                          color: AppColors.textGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  PrimaryButton(
                    text: 'auth.login'.tr(),
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _handleLogin,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'auth.dont_have_account'.tr(),
                        style: const TextStyle(color: AppColors.textGray, fontWeight: FontWeight.w500),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ProfileScreen()),
                          );
                        },
                        child: Text(
                          'auth.sign_up'.tr(),
                          style: const TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
