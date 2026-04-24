import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

/// Tracks video watch time and triggers view count API when threshold is reached
class VideoViewTracker extends ChangeNotifier {
  final String chapterId;
  final int viewByMinute;
  final Function(int watchedMinutes) onViewCounted;
  
  VideoPlayerController? _controller;
  Timer? _trackingTimer;
  
  // Tracking state
  int _watchedSeconds = 0;
  bool _viewCounted = false;
  bool _isTracking = false;
  bool _wasPlaying = false;
  Duration _lastPosition = Duration.zero;
  DateTime? _lastTickTime;
  
  // Lifecycle state
  bool _isInForeground = true;
  bool _isDisposed = false;
  
  // Persistence keys
  late final String _prefsKeyWatched;
  late final String _prefsKeyCounted;
  late final String _prefsKeyTimestamp;
  
  VideoViewTracker({
    required this.chapterId,
    required this.viewByMinute,
    required this.onViewCounted,
  }) {
    _prefsKeyWatched = 'video_watch_${chapterId}';
    _prefsKeyCounted = 'video_counted_${chapterId}';
    _prefsKeyTimestamp = 'video_timestamp_${chapterId}';
    _loadPersistedProgress();
  }
  
  int get watchedSeconds => _watchedSeconds;
  int get requiredSeconds => viewByMinute > 0 ? viewByMinute * 60 : 10;
  int get remainingSeconds => (requiredSeconds - _watchedSeconds).clamp(0, requiredSeconds);
  bool get viewCounted => _viewCounted;
  double get progress => (_watchedSeconds / requiredSeconds).clamp(0.0, 1.0);
  
  /// Attach to video controller and start tracking
  void attach(VideoPlayerController controller) {
    _controller = controller;
    _startTracking();
  }
  
  /// Detach from controller (e.g., when switching videos)
  void detach() {
    _pauseTracking();
    _controller = null;
  }
  
  /// Handle app lifecycle changes
  void onAppLifecycleStateChanged(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isInForeground = true;
        if (_controller?.value.isPlaying == true) {
          _startTracking();
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _isInForeground = false;
        _pauseTracking();
        _persistProgress();
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
    _lastTickTime = DateTime.now();
    _wasPlaying = false;
    
    // Use timer-based tracking for more reliable foreground detection
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    
    debugPrint('[VideoViewTracker] Started tracking for chapter $chapterId');
  }
  
  /// Pause tracking
  void _pauseTracking() {
    if (!_isTracking) return;
    
    _isTracking = false;
    _trackingTimer?.cancel();
    _lastTickTime = null;
    
    // Save final position snapshot
    if (_controller != null) {
      _lastPosition = _controller!.value.position;
    }
    
    _persistProgress();
    debugPrint('[VideoViewTracker] Paused tracking. Watched: $_watchedSeconds seconds');
  }
  
  /// Timer tick - check if video is playing and accumulate time
  void _onTick() {
    if (_isDisposed || !_isInForeground || _viewCounted) {
      _trackingTimer?.cancel();
      return;
    }
    
    if (_controller == null) return;
    
    final value = _controller!.value;
    final isPlaying = value.isPlaying;
    final position = value.position;
    
    // Only count when actually playing
    if (isPlaying) {
      // On first play after pause/seek, reset position reference
      if (!_wasPlaying) {
        _lastPosition = position;
        debugPrint('[VideoViewTracker] First play tick at $position');
      }
      
      // Calculate time diff - only count forward progress up to 1 second
      final diff = position - _lastPosition;
      final seconds = diff.inSeconds;
      
      // Only count if time progressed reasonably (not seeking)
      if (seconds >= 0 && seconds <= 2) {
        _watchedSeconds += seconds > 0 ? seconds : 1;
        _checkThreshold();
      } else {
        // User seeked - don't count, just update reference
        debugPrint('[VideoViewTracker] Seek detected: $seconds seconds, not counting');
      }
      
      _lastPosition = position;
    }
    
    _wasPlaying = isPlaying;
    notifyListeners();
  }
  
  /// Check if we've reached the required watch time
  void _checkThreshold() {
    if (_viewCounted) return;
    
    debugPrint('[VideoViewTracker] Progress: $_watchedSeconds / $requiredSeconds seconds');
    
    if (_watchedSeconds >= requiredSeconds) {
      _markAsViewed();
    }
  }
  
  /// Mark video as viewed - NOTE: API call is handled by inline tracking in LectureDetailScreen
  Future<void> _markAsViewed() async {
    if (_viewCounted) return;
    
    _viewCounted = true;
    _isTracking = false;
    _trackingTimer?.cancel();
    
    await _persistProgress();
    
    debugPrint('[VideoViewTracker] View threshold reached for chapter $chapterId! Watched: $_watchedSeconds seconds');
    debugPrint('[VideoViewTracker] API call is handled by inline tracking system');
    
    // NOTE: We do NOT call onViewCounted here - the inline tracking system in 
    // LectureDetailScreen handles the actual API call to prevent double counting.
    // This tracker is used for persistence and lifecycle management only.
    
    notifyListeners();
  }
  
  /// Load persisted progress from SharedPreferences
  Future<void> _loadPersistedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if view was already counted
      final wasCounted = prefs.getBool(_prefsKeyCounted) ?? false;
      if (wasCounted) {
        _viewCounted = true;
        debugPrint('[VideoViewTracker] View already counted for chapter $chapterId');
        notifyListeners();
        return;
      }
      
      // Load watched seconds
      final savedSeconds = prefs.getInt(_prefsKeyWatched) ?? 0;
      final savedTimestamp = prefs.getInt(_prefsKeyTimestamp) ?? 0;
      
      if (savedSeconds > 0) {
        // Check if saved data is still valid (within same day)
        final savedDate = DateTime.fromMillisecondsSinceEpoch(savedTimestamp);
        final now = DateTime.now();
        final isSameDay = savedDate.year == now.year && 
                         savedDate.month == now.month && 
                         savedDate.day == now.day;
        
        if (isSameDay) {
          _watchedSeconds = savedSeconds;
          debugPrint('[VideoViewTracker] Restored progress: $_watchedSeconds seconds');
        } else {
          // Reset if different day
          debugPrint('[VideoViewTracker] Progress expired, resetting');
          await _clearPersistedProgress();
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('[VideoViewTracker] Error loading progress: $e');
    }
  }
  
  /// Persist current progress to SharedPreferences
  Future<void> _persistProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKeyWatched, _watchedSeconds);
      await prefs.setBool(_prefsKeyCounted, _viewCounted);
      await prefs.setInt(_prefsKeyTimestamp, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('[VideoViewTracker] Error persisting progress: $e');
    }
  }
  
  /// Clear persisted progress
  Future<void> _clearPersistedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKeyWatched);
      await prefs.remove(_prefsKeyCounted);
      await prefs.remove(_prefsKeyTimestamp);
    } catch (e) {
      debugPrint('[VideoViewTracker] Error clearing progress: $e');
    }
  }
  
  /// Reset all progress (e.g., when re-watching same video in new session)
  Future<void> reset() async {
    _pauseTracking();
    _watchedSeconds = 0;
    _viewCounted = false;
    _wasPlaying = false;
    _lastPosition = Duration.zero;
    await _clearPersistedProgress();
    notifyListeners();
    debugPrint('[VideoViewTracker] Reset for chapter $chapterId');
  }
  
  /// Dispose tracker
  void _dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _pauseTracking();
    _controller = null;
    debugPrint('[VideoViewTracker] Disposed for chapter $chapterId');
  }
  
  @override
  void dispose() {
    _dispose();
    super.dispose();
  }
}
