// lib/core/services/screen_protection_service.dart
// Production-grade screen protection service for Flutter
// 
// ARCHITECTURE OVERVIEW:
// - Uses MethodChannel for native platform communication
// - Maintains global protection state
// - Tracks per-screen protection via reference counting
// - Handles app lifecycle transitions automatically
//
// PLATFORM DIFFERENCES:
// - Android: FLAG_SECURE provides hard blocking of screenshots, screen recording, and recent apps
// - iOS: Best-effort protection using detection + overlay (no true blocking API exists)

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Protection mode for a screen
enum ScreenProtectionMode {
  /// No protection
  none,
  
  /// Protect only this specific screen
  local,
  
  /// Global protection (affects all screens)
  global,
}

/// Screen protection event types (iOS only - Android uses FLAG_SECURE)
enum ScreenProtectionEvent {
  /// Screenshot was attempted (iOS detection only)
  screenshotAttempted,
  
  /// Screen recording started (iOS detection only)
  recordingStarted,
  
  /// Screen recording stopped (iOS detection only)
  recordingStopped,
  
  /// App entered app switcher (iOS only)
  appSwitcherEntered,
  
  /// App left app switcher (iOS only)
  appSwitcherExited,
}

/// Data for protection events
class ScreenProtectionEventData {
  final ScreenProtectionEvent event;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  ScreenProtectionEventData({
    required this.event,
    this.metadata,
  }) : timestamp = DateTime.now();
}

/// Production-grade screen protection service
/// 
/// Features:
/// - Global protection (entire app)
/// - Per-screen protection (selective)
/// - Automatic lifecycle management
/// - Event callbacks for iOS detection
/// - Reference counting for nested screens
/// 
/// LIMITATIONS:
/// - Android: FLAG_SECURE is hardware-level blocking - cannot be bypassed
/// - iOS: No true blocking API exists. Detection + overlay is best-effort only.
/// - iOS: Screen recording detection has latency (1-2 seconds typical)
/// - iOS: App switcher screenshot cannot be blocked, only blurred
class ScreenProtectionService {
  // Singleton instance
  static final ScreenProtectionService _instance = ScreenProtectionService._internal();
  factory ScreenProtectionService() => _instance;
  ScreenProtectionService._internal();

  // Method channel for native communication
  static const MethodChannel _channel = MethodChannel(
    'com.learnoo.screen_protection',
    StandardMethodCodec(),
  );

  // Event channel for iOS events (streaming)
  static const EventChannel _eventChannel = EventChannel(
    'com.learnoo.screen_protection/events',
  );

  // State tracking
  bool _isGlobalEnabled = false;
  int _protectedScreenCount = 0;
  bool _isInitialized = false;
  StreamSubscription<dynamic>? _eventSubscription;

  // Event stream controller for Flutter listeners
  final StreamController<ScreenProtectionEventData> _eventController = 
      StreamController<ScreenProtectionEventData>.broadcast();

  /// Public event stream for protection events (iOS mainly)
  Stream<ScreenProtectionEventData> get onEvent => _eventController.stream;

  /// Whether global protection is currently enabled
  bool get isGlobalEnabled => _isGlobalEnabled;

  /// Whether any protection is currently active (global OR local screens)
  bool get isProtectionActive => _isGlobalEnabled || _protectedScreenCount > 0;

  /// Number of screens currently requesting protection
  int get protectedScreenCount => _protectedScreenCount;

  /// Initialize the service and set up event listeners
  /// Call this in main() before runApp()
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Set up method call handler for native -> Flutter calls
    _channel.setMethodCallHandler(_handleMethodCall);

    // Set up event channel listener for streaming events (iOS)
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      _handleEventChannelData,
      onError: (error) {
        debugPrint('[ScreenProtection] Event channel error: $error');
      },
    );

    _isInitialized = true;
    debugPrint('[ScreenProtection] Service initialized');
  }

  /// Dispose the service and clean up resources
  void dispose() {
    _eventSubscription?.cancel();
    _eventController.close();
    _channel.setMethodCallHandler(null);
    _isInitialized = false;
  }

  /// Handle method calls from native platforms
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onScreenshot':
        _emitEvent(ScreenProtectionEvent.screenshotAttempted);
        break;
      case 'onRecordingStarted':
        _emitEvent(ScreenProtectionEvent.recordingStarted);
        break;
      case 'onRecordingStopped':
        _emitEvent(ScreenProtectionEvent.recordingStopped);
        break;
      case 'onAppSwitcherEntered':
        _emitEvent(ScreenProtectionEvent.appSwitcherEntered);
        break;
      case 'onAppSwitcherExited':
        _emitEvent(ScreenProtectionEvent.appSwitcherExited);
        break;
      default:
        throw MissingPluginException('Method ${call.method} not implemented');
    }
  }

  /// Handle event channel data
  void _handleEventChannelData(dynamic data) {
    if (data is Map) {
      final eventType = data['event'] as String?;
      final metadata = data['metadata'] as Map<dynamic, dynamic>?;
      
      switch (eventType) {
        case 'screenshot':
          _emitEvent(ScreenProtectionEvent.screenshotAttempted, metadata: metadata?.cast<String, dynamic>());
          break;
        case 'recording_started':
          _emitEvent(ScreenProtectionEvent.recordingStarted, metadata: metadata?.cast<String, dynamic>());
          break;
        case 'recording_stopped':
          _emitEvent(ScreenProtectionEvent.recordingStopped, metadata: metadata?.cast<String, dynamic>());
          break;
        case 'app_switcher_entered':
          _emitEvent(ScreenProtectionEvent.appSwitcherEntered, metadata: metadata?.cast<String, dynamic>());
          break;
        case 'app_switcher_exited':
          _emitEvent(ScreenProtectionEvent.appSwitcherExited, metadata: metadata?.cast<String, dynamic>());
          break;
      }
    }
  }

  /// Emit an event to the stream
  void _emitEvent(ScreenProtectionEvent event, {Map<String, dynamic>? metadata}) {
    final eventData = ScreenProtectionEventData(
      event: event,
      metadata: metadata,
    );
    _eventController.add(eventData);
    debugPrint('[ScreenProtection] Event: ${event.name}');
  }

  /// Enable protection for the entire app (global)
  /// 
  /// This affects all screens and persists until disabled.
  /// On Android: Sets FLAG_SECURE on the main window
  /// On iOS: Enables best-effort detection + overlay for all screens
  Future<void> enableGlobalProtection() async {
    if (!_isInitialized) {
      throw StateError('ScreenProtectionService not initialized. Call initialize() first.');
    }

    try {
      await _channel.invokeMethod('enableGlobalProtection');
      _isGlobalEnabled = true;
      debugPrint('[ScreenProtection] Global protection enabled');
    } on PlatformException catch (e) {
      debugPrint('[ScreenProtection] Failed to enable global protection: ${e.message}');
      rethrow;
    }
  }

  /// Disable global protection
  /// 
  /// Note: Individual screens with local protection will remain protected.
  Future<void> disableGlobalProtection() async {
    if (!_isInitialized) return;

    try {
      await _channel.invokeMethod('disableGlobalProtection');
      _isGlobalEnabled = false;
      debugPrint('[ScreenProtection] Global protection disabled');
    } on PlatformException catch (e) {
      debugPrint('[ScreenProtection] Failed to disable global protection: ${e.message}');
      rethrow;
    }
  }

  /// Enable protection for the current screen only
  /// 
  /// Use this in didPush (navigation) or initState for screens
  /// that need protection. The service uses reference counting,
  /// so multiple protected screens work correctly.
  /// 
  /// On Android: Adds FLAG_SECURE when count > 0
  /// On iOS: Shows overlay when count > 0 (unless global already active)
  Future<void> enableForCurrentScreen() async {
    if (!_isInitialized) {
      throw StateError('ScreenProtectionService not initialized. Call initialize() first.');
    }

    try {
      _protectedScreenCount++;
      
      // Only notify native if this is the first protected screen and global is off
      if (_protectedScreenCount == 1 && !_isGlobalEnabled) {
        await _channel.invokeMethod('enableLocalProtection');
      }
      
      debugPrint('[ScreenProtection] Local protection enabled (count: $_protectedScreenCount)');
    } on PlatformException catch (e) {
      _protectedScreenCount--; // Rollback on failure
      debugPrint('[ScreenProtection] Failed to enable local protection: ${e.message}');
      rethrow;
    }
  }

  /// Disable protection for the current screen
  /// 
  /// Use this in didPop (navigation) or dispose.
  /// Must match every enableForCurrentScreen() call.
  Future<void> disableForCurrentScreen() async {
    if (!_isInitialized) return;
    if (_protectedScreenCount <= 0) return;

    try {
      _protectedScreenCount--;
      
      // Only notify native if count reached 0 and global is off
      if (_protectedScreenCount == 0 && !_isGlobalEnabled) {
        await _channel.invokeMethod('disableLocalProtection');
      }
      
      debugPrint('[ScreenProtection] Local protection disabled (count: $_protectedScreenCount)');
    } on PlatformException catch (e) {
      _protectedScreenCount++; // Rollback on failure
      debugPrint('[ScreenProtection] Failed to disable local protection: ${e.message}');
      rethrow;
    }
  }

  /// Get current protection status from native layer
  /// Useful for debugging and UI state sync
  Future<Map<String, dynamic>> getProtectionStatus() async {
    if (!_isInitialized) {
      return {'initialized': false};
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getProtectionStatus');
      return result?.cast<String, dynamic>() ?? {};
    } on PlatformException catch (e) {
      debugPrint('[ScreenProtection] Failed to get status: ${e.message}');
      return {'error': e.message};
    }
  }

  /// Enable secure mode with blur overlay (iOS mainly)
  /// 
  /// This shows a blur/overlay view when app is inactive or in app switcher.
  /// On Android: Uses standard FLAG_SECURE (blur not needed)
  /// On iOS: Adds blur overlay view
  Future<void> enableBlurOverlay({double blurRadius = 20.0}) async {
    if (!_isInitialized) return;
    if (!Platform.isIOS) return; // Android uses FLAG_SECURE instead

    try {
      await _channel.invokeMethod('enableBlurOverlay', {
        'blurRadius': blurRadius,
      });
      debugPrint('[ScreenProtection] Blur overlay enabled');
    } on PlatformException catch (e) {
      debugPrint('[ScreenProtection] Failed to enable blur overlay: ${e.message}');
    }
  }

  /// Disable blur overlay
  Future<void> disableBlurOverlay() async {
    if (!_isInitialized) return;
    if (!Platform.isIOS) return;

    try {
      await _channel.invokeMethod('disableBlurOverlay');
      debugPrint('[ScreenProtection] Blur overlay disabled');
    } on PlatformException catch (e) {
      debugPrint('[ScreenProtection] Failed to disable blur overlay: ${e.message}');
    }
  }
}

/// Extension for easier access
extension ScreenProtectionServiceExtension on BuildContext {
  /// Quick access to the screen protection service
  ScreenProtectionService get screenProtection => ScreenProtectionService();
}
