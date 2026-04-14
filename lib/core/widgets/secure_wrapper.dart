import 'dart:async';
import 'package:flutter/material.dart';
import 'package:learnoo/core/services/screen_protection_service.dart';

/// A fail-safe wrapper that protects sensitive content.
/// Content starts HIDDEN (black screen) until security checks pass.
class SecureWrapper extends StatefulWidget {
  final Widget child;
  final String protectionMessage;

  const SecureWrapper({
    super.key,
    required this.child,
    this.protectionMessage = "Content Protected",
  });

  @override
  State<SecureWrapper> createState() => _SecureWrapperState();
}

class _SecureWrapperState extends State<SecureWrapper> with WidgetsBindingObserver {
  final ScreenProtectionService _security = ScreenProtectionService();
  bool _isSafe = false;
  String _statusMessage = "Initializing security...";
  Timer? _appCheckTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _performInitialSecurityScan();
    
    // Periodically check for suspicious apps on Android
    _appCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) => _scanForSuspiciousApps());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appCheckTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _performInitialSecurityScan();
    } else {
      setState(() => _isSafe = false);
    }
  }

  Future<void> _performInitialSecurityScan() async {
    setState(() {
      _isSafe = false;
      _statusMessage = "Scanning for threats...";
    });

    final status = await _security.getProtectionStatus();
    final isRecording = status['isRecording'] ?? false;
    final isJailbroken = status['isJailbroken'] ?? false;
    final isMultiWindow = status['isMultiWindow'] ?? false;

    if (isRecording) {
      _showBreach("Screen recording detected");
      return;
    }
    if (isJailbroken) {
      _showBreach("Rooted/Jailbroken device detected");
      return;
    }
    if (isMultiWindow) {
      _showBreach("Split-screen mode not allowed");
      return;
    }

    await _scanForSuspiciousApps();
  }

  Future<void> _scanForSuspiciousApps() async {
    final hasSuspiciousApps = await _security.detectSuspiciousApps();
    if (hasSuspiciousApps) {
      _showBreach("Suspicious apps (Zoom/Meet/Recorders) detected");
      return;
    }

    if (mounted) {
      setState(() {
        _isSafe = true;
      });
    }
  }

  void _showBreach(String message) {
    if (mounted) {
      setState(() {
        _isSafe = false;
        _statusMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: _security.onSecurityStatusChanged,
      initialData: _isSafe,
      builder: (context, snapshot) {
        final currentSafety = snapshot.data ?? false;
        
        if (!currentSafety || !_isSafe) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, color: Colors.red, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _performInitialSecurityScan,
                    child: const Text("Retry Security Scan"),
                  )
                ],
              ),
            ),
          );
        }

        return widget.child;
      },
    );
  }
}
