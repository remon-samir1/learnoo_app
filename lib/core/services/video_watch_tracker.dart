import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Tracks actual watch time for video view counting
/// Calls onThresholdReached when view_by_minute threshold is met
/// Designed for: POST /chapter/{chapter_id}/view after required minutes
class VideoWatchTracker extends ChangeNotifier {
  final String chapterId;
  final int viewByMinute;
  final VoidCallback? onThresholdReached;
  
  VideoPlayerController? _controller;
  Timer? _trackingTimer;
  
  // Tracking state
  int _watchedSeconds = 0;
  bool _viewCounted = false;
  bool _isTracking = false;
  bool _wasPlaying = false;
  Duration _lastPosition = Duration.zero;
  
  // Lifecycle state
  bool _isInForeground = true;
  bool _isDisposed = false;
  bool _isPaused = false;
  
  VideoWatchTracker({
    required this.chapterId,
    required this.viewByMinute,
    this.onThresholdReached,
  }) {
    if (viewByMinute <= 0) {
      debugPrint('[VideoWatchTracker] Warning: viewByMinute is $viewByMinute, view will be counted immediately');
    }
  }
  
  int get watchedSeconds => _watchedSeconds;
  int get requiredSeconds => viewByMinute > 0 ? viewByMinute * 60 : 10;
  int get remainingSeconds => (requiredSeconds - _watchedSeconds).clamp(0, requiredSeconds);
  bool get viewCounted => _viewCounted;
  bool get isTracking => _isTracking;
  double get progress => _watchedSeconds / requiredSeconds;
  
  /// Attach to video controller
  void attach(VideoPlayerController controller) {
    if (_isDisposed) return;
    
    _controller = controller;
    
    // Listen to controller value changes
    controller.addListener(_onControllerUpdate);
    
    // If already playing, start tracking
    if (controller.value.isPlaying && _isInForeground && !_isPaused) {
      _startTracking();
    }
    
    debugPrint('[VideoWatchTracker] Attached to controller for chapter $chapterId');
  }
  
  /// Detach from controller
  void detach() {
    _controller?.removeListener(_onControllerUpdate);
    _pauseTracking();
    _controller = null;
    debugPrint('[VideoWatchTracker] Detached from controller');
  }
  
  /// Handle video controller state changes
  void _onControllerUpdate() {
    if (_isDisposed || _controller == null) return;
    
    final value = _controller!.value;
    final isPlaying = value.isPlaying;
    
    // Start/stop tracking based on play state
    if (isPlaying && _isInForeground && !_isPaused && !_viewCounted) {
      if (!_isTracking) {
        _startTracking();
      }
    } else if (!isPlaying && _isTracking) {
      _pauseTracking();
    }
  }
  
  /// Handle app lifecycle changes
  void onAppLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        // Resume tracking if video is playing
        if (_controller?.value.isPlaying == true && !_viewCounted && !_isPaused) {
          _startTracking();
        }
        break;
        
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _isInForeground = false;
        _pauseTracking();
        break;
        
      case AppLifecycleState.detached:
        _dispose();
        break;
    }
  }
  
  /// Start tracking watch time
  void _startTracking() {
    if (_isTracking || _viewCounted || _isDisposed) return;
    if (_controller == null) return;
    
    _isTracking = true;
    _lastPosition = _controller!.value.position;
    _wasPlaying = false;
    
    // Use 1-second timer for accurate tracking
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    
    debugPrint('[VideoWatchTracker] Started tracking for chapter $chapterId');
    notifyListeners();
  }
  
  /// Pause tracking
  void _pauseTracking() {
    if (!_isTracking) return;
    
    _isTracking = false;
    _trackingTimer?.cancel();
    
    // Capture final position
    if (_controller != null) {
      _lastPosition = _controller!.value.position;
    }
    
    debugPrint('[VideoWatchTracker] Paused tracking. Watched: $_watchedSeconds / ${requiredSeconds}s');
    notifyListeners();
  }
  
  /// Manual pause (e.g., when user explicitly pauses)
  void userPaused() {
    _isPaused = true;
    _pauseTracking();
  }
  
  /// Manual resume (e.g., when user resumes playback)
  void userResumed() {
    _isPaused = false;
    if (_isInForeground && _controller?.value.isPlaying == true && !_viewCounted) {
      _startTracking();
    }
  }
  
  /// Handle seek - reset tracking to avoid counting skipped time
  void onSeek(Duration newPosition) {
    if (_isTracking) {
      // When seeking, update last position to new position
      // This prevents counting the skipped time
      _lastPosition = newPosition;
      debugPrint('[VideoWatchTracker] Seek detected: position reset to $newPosition');
    }
  }
  
  /// Timer tick - accumulate watch time
  void _onTick() {
    if (_isDisposed || !_isInForeground || _viewCounted || !_isTracking) {
      _trackingTimer?.cancel();
      return;
    }
    
    if (_controller == null) return;
    
    final value = _controller!.value;
    final isPlaying = value.isPlaying;
    final position = value.position;
    
    // Only count when actually playing
    if (isPlaying) {
      // On first play tick after pause, reset reference
      if (!_wasPlaying) {
        _lastPosition = position;
      }
      
      // Calculate time difference
      final diff = position - _lastPosition;
      final seconds = diff.inSeconds;
      
      // Only count reasonable increments (0-2 seconds)
      // This filters out:
      // - Negative values (seeking backward)
      // - Large jumps (seeking forward)
      // - Buffering delays
      if (seconds >= 0 && seconds <= 2) {
        _watchedSeconds += seconds > 0 ? seconds : 1;
        _checkThreshold();
      } else if (seconds > 2) {
        // Likely a seek forward - don't count
        debugPrint('[VideoWatchTracker] Skipped counting: jump of $seconds seconds (seek detected)');
      }
      
      _lastPosition = position;
    }
    
    _wasPlaying = isPlaying;
    notifyListeners();
  }
  
  /// Check if threshold reached
  void _checkThreshold() {
    if (_viewCounted) return;
    
    final required = requiredSeconds;
    
    if (_watchedSeconds >= required) {
      _markAsViewed();
    } else {
      // Debug progress every 10 seconds
      if (_watchedSeconds % 10 == 0) {
        debugPrint('[VideoWatchTracker] Progress: $_watchedSeconds / ${required}s (${((_watchedSeconds / required) * 100).toStringAsFixed(0)}%)');
      }
    }
  }
  
  /// Mark as viewed and trigger callback
  void _markAsViewed() {
    if (_viewCounted) return;
    
    _viewCounted = true;
    _isTracking = false;
    _trackingTimer?.cancel();
    
    debugPrint('[VideoWatchTracker] VIEW COUNTED for chapter $chapterId! Total watched: $_watchedSeconds seconds');
    
    // Trigger callback
    onThresholdReached?.call();
    
    notifyListeners();
  }
  
  /// Reset tracker for re-watching
  void reset() {
    _pauseTracking();
    _watchedSeconds = 0;
    _viewCounted = false;
    _wasPlaying = false;
    _lastPosition = Duration.zero;
    notifyListeners();
    debugPrint('[VideoWatchTracker] Reset for chapter $chapterId');
  }
  
  /// Dispose tracker
  void _dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    detach();
    _trackingTimer?.cancel();
    _trackingTimer = null;
    
    debugPrint('[VideoWatchTracker] Disposed for chapter $chapterId');
  }
  
  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}
