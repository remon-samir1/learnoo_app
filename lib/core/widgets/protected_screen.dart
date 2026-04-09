// lib/core/widgets/protected_screen.dart
// ProtectedScreen wrapper widget for declarative screen protection
//
// USAGE:
// ```dart
// ProtectedScreen(
//   child: MySensitiveScreen(),
// )
// ```
//
// Or with custom options:
// ```dart
// ProtectedScreen(
//   mode: ProtectionMode.strict,  // More aggressive iOS overlay
//   onScreenshotAttempt: () => showWarningDialog(),
//   child: MyBankingScreen(),
// )
// ```

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/screen_protection_service.dart';

/// Protection mode for ProtectedScreen
enum ProtectionMode {
  /// Standard protection (uses native FLAG_SECURE / overlay)
  standard,
  
  /// Strict mode - adds additional Flutter-level blur when app inactive
  strict,
  
  /// Debug mode - visual indicator showing protection is active
  debug,
}

/// A widget that protects its child screen from screenshots and screen recording.
///
/// This widget automatically handles:
/// - Enabling protection when the screen is shown
/// - Disabling protection when the screen is hidden
/// - Listening to protection events (iOS)
/// - Showing overlay when app becomes inactive (strict mode)
///
/// ANDROID: Uses FLAG_SECURE (hardware-level, cannot be bypassed)
/// iOS: Uses best-effort detection + overlay (no true blocking available)
class ProtectedScreen extends StatefulWidget {
  /// The child widget (the actual screen content)
  final Widget child;

  /// Protection mode
  final ProtectionMode mode;

  /// Optional callback when screenshot is attempted (iOS only)
  final VoidCallback? onScreenshotAttempt;

  /// Optional callback when screen recording starts (iOS only)
  final VoidCallback? onRecordingStarted;

  /// Optional callback when screen recording stops (iOS only)
  final VoidCallback? onRecordingStopped;

  /// Custom message to show in overlay (iOS app switcher)
  final String? protectionMessage;

  /// Background color for the protection overlay
  final Color overlayColor;

  /// Duration for overlay fade animations
  final Duration animationDuration;

  /// Whether to show a visual indicator in debug mode
  final bool showDebugIndicator;

  const ProtectedScreen({
    super.key,
    required this.child,
    this.mode = ProtectionMode.standard,
    this.onScreenshotAttempt,
    this.onRecordingStarted,
    this.onRecordingStopped,
    this.protectionMessage,
    this.overlayColor = const Color(0xFF1A1A2E),
    this.animationDuration = const Duration(milliseconds: 250),
    this.showDebugIndicator = false,
  });

  @override
  State<ProtectedScreen> createState() => _ProtectedScreenState();
}

class _ProtectedScreenState extends State<ProtectedScreen> 
    with WidgetsBindingObserver, RouteAware {
  
  final ScreenProtectionService _protectionService = ScreenProtectionService();
  StreamSubscription<ScreenProtectionEventData>? _eventSubscription;
  
  // Strict mode states
  bool _showBlurOverlay = false;
  bool _isRecording = false;
  bool _protectionActive = false;

  // Route observer for detecting when screen is pushed/popped
  RouteObserver<ModalRoute<void>>? _routeObserver;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupEventListeners();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Subscribe to route changes
    _routeObserver ??= RouteObserver<ModalRoute<void>>();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      _routeObserver?.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    _disableProtection();
    WidgetsBinding.instance.removeObserver(this);
    _eventSubscription?.cancel();
    
    if (_routeObserver != null) {
      final modalRoute = ModalRoute.of(context);
      if (modalRoute is PageRoute) {
        _routeObserver?.unsubscribe(this);
      }
    }
    
    super.dispose();
  }

  // RouteAware callbacks
  @override
  void didPush() {
    // Screen was pushed - enable protection
    _enableProtection();
  }

  @override
  void didPopNext() {
    // Previous screen popped, this screen is now visible
    _enableProtection();
  }

  @override
  void didPop() {
    // This screen was popped
    _disableProtection();
  }

  @override
  void didPushNext() {
    // Another screen was pushed on top of this one
    _disableProtection();
  }

  // App lifecycle observer
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (!mounted) return;

    switch (state) {
      case AppLifecycleState.inactive:
        // App is inactive (incoming call, app switcher, etc.)
        if (widget.mode == ProtectionMode.strict) {
          setState(() => _showBlurOverlay = true);
        }
        break;
        
      case AppLifecycleState.paused:
        // App is in background
        if (widget.mode == ProtectionMode.strict) {
          setState(() => _showBlurOverlay = true);
        }
        break;
        
      case AppLifecycleState.resumed:
        // App is back in foreground
        setState(() => _showBlurOverlay = false);
        break;
        
      case AppLifecycleState.detached:
        // App is being terminated
        _disableProtection();
        break;
        
      case AppLifecycleState.hidden:
        // App is hidden (iOS)
        if (widget.mode == ProtectionMode.strict) {
          setState(() => _showBlurOverlay = true);
        }
        break;
    }
  }

  void _setupEventListeners() {
    _eventSubscription = _protectionService.onEvent.listen((event) {
      if (!mounted) return;
      
      switch (event.event) {
        case ScreenProtectionEvent.screenshotAttempted:
          widget.onScreenshotAttempt?.call();
          _handleScreenshotAttempt();
          break;
          
        case ScreenProtectionEvent.recordingStarted:
          setState(() => _isRecording = true);
          widget.onRecordingStarted?.call();
          _handleRecordingStarted();
          break;
          
        case ScreenProtectionEvent.recordingStopped:
          setState(() => _isRecording = false);
          widget.onRecordingStopped?.call();
          break;
          
        case ScreenProtectionEvent.appSwitcherEntered:
          if (widget.mode == ProtectionMode.strict) {
            setState(() => _showBlurOverlay = true);
          }
          break;
          
        case ScreenProtectionEvent.appSwitcherExited:
          setState(() => _showBlurOverlay = false);
          break;
      }
    });
  }

  Future<void> _enableProtection() async {
    if (_protectionActive) return;
    
    await _protectionService.enableForCurrentScreen();
    
    if (mounted) {
      setState(() => _protectionActive = true);
    }
  }

  Future<void> _disableProtection() async {
    if (!_protectionActive) return;
    
    await _protectionService.disableForCurrentScreen();
    
    if (mounted) {
      setState(() {
        _protectionActive = false;
        _showBlurOverlay = false;
        _isRecording = false;
      });
    }
  }

  void _handleScreenshotAttempt() {
    // Default behavior: show a brief warning
    if (mounted && widget.onScreenshotAttempt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screenshots are not allowed on this screen'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleRecordingStarted() {
    // Default behavior: show warning
    if (mounted && widget.onRecordingStarted == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screen recording is not allowed on this screen'),
          duration: Duration(seconds: 3),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main content
        widget.child,
        
        // Blur overlay for strict mode (inactive/app switcher)
        if (_showBlurOverlay)
          AnimatedOpacity(
            opacity: _showBlurOverlay ? 1.0 : 0.0,
            duration: widget.animationDuration,
            child: Container(
              color: widget.overlayColor,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.security,
                      size: 48,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.protectionMessage ?? 'Content Protected',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (widget.mode == ProtectionMode.debug) ...[
                      const SizedBox(height: 8),
                      Text(
                        'ProtectedScreen: ACTIVE',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        
        // Recording indicator overlay
        if (_isRecording && Platform.isIOS)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Recording Detected',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Debug indicator
        if (widget.mode == ProtectionMode.debug && widget.showDebugIndicator)
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _protectionActive 
                    ? Colors.green.withOpacity(0.9)
                    : Colors.red.withOpacity(0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _protectionActive ? Icons.lock : Icons.lock_open,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _protectionActive ? 'PROTECTED' : 'UNPROTECTED',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Mixin for adding screen protection to existing stateful widgets
/// 
/// USAGE:
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ScreenProtectionMixin {
///   @override
///   void initState() {
///     super.initState();
///     enableScreenProtection();
///   }
/// 
///   @override
///   void dispose() {
///     disableScreenProtection();
///     super.dispose();
///   }
/// }
/// ```
mixin ScreenProtectionMixin<T extends StatefulWidget> on State<T> {
  final ScreenProtectionService _service = ScreenProtectionService();
  StreamSubscription<ScreenProtectionEventData>? _eventSubscription;

  /// Enable protection for this screen
  Future<void> enableScreenProtection() async {
    await _service.enableForCurrentScreen();
  }

  /// Disable protection for this screen
  Future<void> disableScreenProtection() async {
    await _service.disableForCurrentScreen();
  }

  /// Listen to protection events
  void listenToProtectionEvents(
    void Function(ScreenProtectionEventData) onEvent,
  ) {
    _eventSubscription = _service.onEvent.listen(onEvent);
  }

  /// Cancel event subscription
  void cancelProtectionEventSubscription() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    super.dispose();
  }
}
