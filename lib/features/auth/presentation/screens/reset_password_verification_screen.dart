import 'package:flutter/material.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../data/auth_repository.dart';
import 'create_new_password_screen.dart';

class ResetPasswordVerificationScreen extends StatefulWidget {
  final String phoneOrEmail;
  final bool isEmail;

  const ResetPasswordVerificationScreen({
    super.key,
    required this.phoneOrEmail,
    required this.isEmail,
  });

  @override
  State<ResetPasswordVerificationScreen> createState() =>
      _ResetPasswordVerificationScreenState();
}

class _ResetPasswordVerificationScreenState
    extends State<ResetPasswordVerificationScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (index) => FocusNode());
  int _secondsRemaining = 58;
  Timer? _timer;
  bool _isLoading = false;
  final _authRepository = AuthRepository();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _handleResend() async {
    setState(() {
      _isLoading = true;
      _secondsRemaining = 58;
    });

    final result = await _authRepository.requestPasswordReset(widget.phoneOrEmail);

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Code resent successfully'),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
        ),
      );
      if (result['success']) {
        _startTimer();
      }
    }
  }

  Future<void> _handleVerify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the 6-digit code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authRepository.verifyPasswordReset(
      phoneOrEmail: widget.phoneOrEmail,
      code: code,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (result['success']) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateNewPasswordScreen(
              phoneOrEmail: widget.phoneOrEmail,
              code: code,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to verify code'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Text(
              widget.isEmail
                  ? 'Verify your Email address'
                  : 'Verify your Phone number',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textGray,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: widget.isEmail
                        ? 'We sent a verification code to your email\naddress '
                        : 'We sent a verification code to your phone\nnumber ',
                  ),
                  TextSpan(
                    text: widget.phoneOrEmail,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) => _buildOtpField(index)),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_secondsRemaining > 0) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8FDF2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      '0:${_secondsRemaining.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        color: Color(0xFF27AE60),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Resend code in 0:${_secondsRemaining.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else
                  TextButton(
                    onPressed: _isLoading ? null : _handleResend,
                    child: const Text(
                      'Resend Code',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            PrimaryButton(
              text: 'VERIFY',
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _handleVerify,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        keyboardType: TextInputType.text,
        maxLength: 1,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.textDark,
        ),
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            if (index < 5) {
              _focusNodes[index + 1].requestFocus();
            } else {
              _focusNodes[index].unfocus();
              if (_controllers.every((c) => c.text.isNotEmpty)) {
                _handleVerify();
              }
            }
          } else {
            if (index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          }
        },
      ),
    );
  }
}
