import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:dio/dio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:async';
import '../../../../core/network/api_constants.dart';
import '../../../../core/services/download_service.dart';
import '../../../../core/services/encrypted_video_service.dart';
import '../../../../core/widgets/subscription_badge.dart';
import '../../../../core/widgets/watermark_wrapper.dart';
import '../../../../core/services/feature_manager.dart';
import '../../../../core/services/user_progress_service.dart';
import '../../../../core/services/video_watch_tracker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/chapter_repository.dart';
import '../../data/discussion_repository.dart';
import '../../../exams/presentation/screens/quiz_screen.dart';
import '../../../exams/models/quiz_models.dart';
import '../../../exams/data/exam_repository.dart';

/// Types of video errors for user-friendly messaging
enum VideoErrorType {
  network,
  source,
  unknown,
}

/// Maps video player errors to user-friendly messages
class VideoErrorMapper {
  static const List<String> _networkErrorKeywords = [
    'timeout',
    'connection',
    'socket',
    'network',
    'failed to load',
    'unable to load',
    'internet',
    'unreachable',
    'refused',
    'failed host lookup',
    'offline',
  ];

  static const List<String> _sourceErrorKeywords = [
    'invalid url',
    '404',
    'not found',
    'unavailable',
    'forbidden',
    '403',
    'format',
    'unsupported',
  ];

  static VideoErrorType mapError(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();
    if (_networkErrorKeywords.any((keyword) => lowerError.contains(keyword))) {
      return VideoErrorType.network;
    }
    if (_sourceErrorKeywords.any((keyword) => lowerError.contains(keyword))) {
      return VideoErrorType.source;
    }
    return VideoErrorType.unknown;
  }

  static String getUserMessage(VideoErrorType type, String fallbackKey) {
    switch (type) {
      case VideoErrorType.network:
        return 'course.no_internet'.tr();
      case VideoErrorType.source:
        return 'course.video_unavailable'.tr();
      case VideoErrorType.unknown:
        return fallbackKey.tr();
    }
  }
}

/// Manages video controller lifecycle and state
class VideoControllerHandler {
  VideoPlayerController? _controller;
  ChewieController? _chewieController;
  bool _isRetrying = false;
  bool _listenerAdded = false;

  VideoPlayerController? get controller => _controller;
  ChewieController? get chewieController => _chewieController;
  bool get isRetrying => _isRetrying;

  void setRetrying(bool value) => _isRetrying = value;

  Future<bool> checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> dispose() async {
    if (_listenerAdded && _controller != null) {
      _controller!.removeListener(_emptyListener);
    }
    _listenerAdded = false;
    _chewieController?.dispose();
    _controller?.dispose();
    _chewieController = null;
    _controller = null;
  }

  void _emptyListener() {}

  Future<VideoPlayerController?> initializeFromFile({
    required File videoFile,
    required VoidCallback onError,
    required VoidCallback onBufferingStart,
    required VoidCallback onBufferingEnd,
  }) async {
    await dispose();

    _controller = VideoPlayerController.file(videoFile);

    _controller!.addListener(() {
      if (_controller == null) return;

      final value = _controller!.value;

      if (value.hasError) {
        onError();
      }

      if (value.isBuffering) {
        onBufferingStart();
      } else {
        onBufferingEnd();
      }
    });
    _listenerAdded = true;

    await _controller!.initialize();
    return _controller;
  }

  Future<VideoPlayerController?> initialize({
    required String videoUrl,
    required VoidCallback onError,
    required VoidCallback onBufferingStart,
    required VoidCallback onBufferingEnd,
  }) async {
    await dispose();

    _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));

    _controller!.addListener(() {
      if (_controller == null) return;

      final value = _controller!.value;

      if (value.hasError) {
        onError();
      }

      if (value.isBuffering) {
        onBufferingStart();
      } else {
        onBufferingEnd();
      }
    });
    _listenerAdded = true;

    await _controller!.initialize();
    return _controller;
  }

  void createChewie({
    required bool autoPlay,
    required VoidCallback onError,
  }) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _chewieController = ChewieController(
      videoPlayerController: _controller!,
      autoPlay: autoPlay,
      looping: false,
      aspectRatio: _controller!.value.aspectRatio,
      allowFullScreen: false,
      allowMuting: true,
      showControls: true,
      hideControlsTimer: const Duration(seconds: 3),
      errorBuilder: (context, errorMessage) {
        final errorType = VideoErrorMapper.mapError(errorMessage);
        final userMessage = VideoErrorMapper.getUserMessage(
          errorType,
          'course.something_went_wrong',
        );
        return Center(
          child: Text(
            userMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}

class LectureDetailScreen extends StatefulWidget {
  final String lectureId;
  final String lectureTitle;
  final String chapterId;
  final String chapterTitle;
  final String courseId;
  final String? offlineVideoPath;
  final String? offlineVideoKey;
  final int initialPosition;

  const LectureDetailScreen({
    super.key,
    required this.lectureId,
    required this.lectureTitle,
    required this.chapterId,
    required this.chapterTitle,
    required this.courseId,
    this.offlineVideoPath,
    this.offlineVideoKey,
    this.initialPosition = 0,
  });

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen>
    with WidgetsBindingObserver {
  final _chapterRepository = ChapterRepository();
  final _discussionRepository = DiscussionRepository();
  final _featureManager = FeatureManager();
  final _authRepository = AuthRepository();
  final _userProgressService = UserProgressService();
  final _videoHandler = VideoControllerHandler();

  VideoPlayerController? get _videoController => _videoHandler.controller;
  ChewieController? get _chewieController => _videoHandler.chewieController;

  /// Tracker for view counting after view_by_minute threshold
  VideoWatchTracker? _watchTracker;

  String _userId = '';

  /// Ensures progress is saved only once on exit
  bool _progressSaved = false;

  /// Ensures view is counted only once per session
  bool _viewCountApiCalled = false;
  
  bool _isLoadingChapter = true;
  bool _isLoadingDiscussions = false;
  bool _isOfflineMode = false;
  Map<String, dynamic>? _chapterData;

  bool _isLocked = true;
  bool _canWatch = false;
  bool _isActivated = false;
  int _maxViews = 5;
  int _currentViews = 0;
  int _viewByMinute = 0; // Minutes required to count a view
  String _videoUrl = '';
  String _duration = '00:00';
  List<dynamic> _attachments = [];
  List<dynamic> _quizzes = [];
  List<dynamic> _discussions = [];

  bool _isPlaying = false;
  double _progress = 0.0;
  String _currentTime = '0:00';
  String _totalTime = '0:00';

  // Legacy view tracking state (kept for backward compatibility)
  bool _viewCounted = false;
  bool _isCountingView = false;
  int _watchedSeconds = 0;
  Duration _lastPosition = Duration.zero;
  bool _wasPlaying = false;

  // Video state management
  bool _isVideoLoading = false;
  bool _isBuffering = false;
  bool _hasVideoError = false;
  VideoErrorType _videoErrorType = VideoErrorType.unknown;
  bool _isRetrying = false;

  // Legacy slow internet detection (kept for compatibility)
  bool _hasSlowInternet = false;
  DateTime? _bufferingStartTime;
  Timer? _bufferingTimer;
  static const Duration _slowInternetThreshold = Duration(seconds: 8);

  // Video quality control
  String _currentQuality = 'auto'; // 'auto', '720p', '480p', '360p'
  Map<String, String> _videoQualityUrls = {};
  bool _showQualitySelector = false;
  
  bool _showDiscussionPanel = false;
  String _discussionTab = 'all'; // 'all', 'comment', 'voice'
  final _commentController = TextEditingController();
  
  // Voice recording
  final _audioRecorder = AudioRecorder();
  final _audioPlayer = AudioPlayer();
  final _recordedPlayer = AudioPlayer(); // Added for playing the recorded file
  bool _isRecording = false;
  String? _recordedPath;
  Duration _recordDuration = Duration.zero;
  
  // Use ValueNotifiers for audio positions to avoid excessive setState calls
  final _recordedPosition = ValueNotifier<Duration>(Duration.zero);
  final _recordedTotalDuration = ValueNotifier<Duration>(Duration.zero);
  StreamSubscription<RecordState>? _recordSub;
  StreamSubscription<Duration>? _recordedPositionSub;
  StreamSubscription<Duration>? _recordedDurationSub;
  
  // For list audio playback
  String? _currentlyPlayingUrl;
  final _listAudioPosition = ValueNotifier<Duration>(Duration.zero);
  final _listAudioDuration = ValueNotifier<Duration>(Duration.zero);
  StreamSubscription<Duration>? _listPositionSub;
  StreamSubscription<Duration>? _listDurationSub;

  String? _errorMessage;
  
  // Embedded PDF state
  String? _selectedPdfUrl;
  String? _selectedPdfTitle;
  String? _localPdfPath;
  bool _isPdfLoading = false;
  final DownloadService _pdfDownloadService = DownloadService();
  ValueNotifier<DownloadProgress>? _pdfDownloadNotifier;

  // Video download state
  final _encryptedVideoService = EncryptedVideoService();
  ValueNotifier<EncryptedDownloadProgress>? _downloadProgressNotifier;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  
  // Network connectivity check
  bool _isOnline = true;

  Future<void> _loadUserData() async {
    final result = await _authRepository.getProfile();
    if (result['success'] && mounted) {
      final userId = result['data']['id']?.toString() ?? '';
      setState(() {
        _userId = userId;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUserData();
    _encryptedVideoService.loadDownloadedVideos();
    // Check if offline mode
    if (widget.offlineVideoPath != null && widget.offlineVideoKey != null) {
      setState(() {
        _isOfflineMode = true;
        _isLocked = false;
        _canWatch = true;
        _isLoadingChapter = false;
        _videoUrl = 'offline'; // Placeholder to indicate offline video
      });
      _initializeOfflineVideo();
    } else {
      _loadChapterDetails();
      _loadDiscussions();
      // Check download status after a short delay to ensure service is loaded
      Future.delayed(const Duration(milliseconds: 500), () {
        _checkDownloadStatus();
      });
    }

    // Listen for recording state changes
    _recordSub = _audioRecorder.onStateChanged().listen((state) {
      if (state == RecordState.record) {
        // Start timer or update UI
      }
    });

    // Listen for recorded player position
    _recordedPositionSub = _recordedPlayer.onPositionChanged.listen((p) {
      _recordedPosition.value = p;
    });

    _recordedDurationSub = _recordedPlayer.onDurationChanged.listen((d) {
      _recordedTotalDuration.value = d;
    });

    _recordedPlayer.onPlayerComplete.listen((_) {
      _recordedPosition.value = Duration.zero;
    });

    // Listen for list player
    _listPositionSub = _audioPlayer.onPositionChanged.listen((p) {
      _listAudioPosition.value = p;
    });
    _listDurationSub = _audioPlayer.onDurationChanged.listen((d) {
      _listAudioDuration.value = d;
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _currentlyPlayingUrl = null);
      }
      _listAudioPosition.value = Duration.zero;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _watchTracker?.onAppLifecycleStateChanged(state);

    // Save progress when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _saveProgressOnExit();
    }
  }

  /// Initialize video view tracker
  void _initViewTracker() {
    if (_isOfflineMode || _viewByMinute <= 0) return;

    _watchTracker?.dispose();
    _watchTracker = VideoWatchTracker(
      chapterId: widget.chapterId,
      viewByMinute: _viewByMinute,
      onThresholdReached: () async {
        await _onViewThresholdReached();
      },
    );

    // Attach to video controller when available
    if (_videoController != null && _videoController!.value.isInitialized) {
      _watchTracker!.attach(_videoController!);
    }
  }

  /// Called when view_by_minute threshold is reached
  /// Calls POST /chapter/{chapter_id}/view API
  Future<void> _onViewThresholdReached() async {
    if (_viewCountApiCalled) return;
    _viewCountApiCalled = true;

    final chapterId = int.tryParse(widget.chapterId);
    if (chapterId == null) return;

    // Calculate watched minutes from the tracker
    final watchedMinutes = (_watchTracker?.watchedSeconds ?? 0) ~/ 60;

    debugPrint('[LectureDetail] View threshold reached. Calling view count API...');

    final result = await _chapterRepository.incrementViewCount(
      chapterId: chapterId,
      watchedMinutes: watchedMinutes > 0 ? watchedMinutes : _viewByMinute,
    );

    if (result['success'] && mounted) {
      setState(() {
        _currentViews = result['current_views'] ?? _currentViews + 1;
        _viewCounted = true;
      });
      debugPrint('[LectureDetail] View counted successfully. Current views: $_currentViews');
    } else {
      // Reset flag so we can retry
      _viewCountApiCalled = false;
      debugPrint('[LectureDetail] Failed to count view: ${result['message']}');
    }
  }

  /// API call to increment view count
  Future<void> _incrementViewCount(int watchedMinutes) async {
    final chapterId = int.tryParse(widget.chapterId);
    if (chapterId == null) return;

    final result = await _chapterRepository.incrementViewCount(
      chapterId: chapterId,
      watchedMinutes: watchedMinutes,
    );

    if (result['success'] && mounted) {
      setState(() {
        _currentViews = result['current_views'] ?? _currentViews + 1;
      });
      debugPrint('[LectureDetail] View counted successfully. Current views: $_currentViews');
    } else {
      debugPrint('[LectureDetail] Failed to count view: ${result['message']}');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Save progress before leaving (sync, with timeout safety)
    _saveProgressOnExit();

    // Dispose view tracker
    _watchTracker?.dispose();

    // Dispose video handler (includes controllers and listeners)
    _videoHandler.dispose();

    _commentController.dispose();
    _bufferingTimer?.cancel();
    _recordSub?.cancel();
    _recordedPositionSub?.cancel();
    _recordedDurationSub?.cancel();
    _listPositionSub?.cancel();
    _listDurationSub?.cancel();
    _recordedPosition.dispose();
    _recordedTotalDuration.dispose();
    _listAudioPosition.dispose();
    _listAudioDuration.dispose();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _recordedPlayer.dispose();
    if (_downloadProgressNotifier != null) {
      _encryptedVideoService.disposeNotifier(_videoUrl);
    }

    // Clean up temp offline video file
    if (_isOfflineMode) {
      _cleanupTempOfflineVideo();
    }

    super.dispose();
  }

  Future<void> _cleanupTempOfflineVideo() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/offline_video_${widget.chapterId}.mp4';
      final tempFile = File(tempFilePath);
      if (await tempFile.exists()) {
        await tempFile.delete();
        debugPrint('Cleaned up temp offline video file');
      }
    } catch (e) {
      debugPrint('Error cleaning up temp offline video: $e');
    }
  }

  /// Save progress on exit with lifecycle safety
  /// Calls POST /user-progress with lecture_id
  void _saveProgressOnExit() {
    // Prevent duplicate calls
    if (_progressSaved) return;
    _progressSaved = true;

    // Don't save if video was never played
    if (_isLocked || !_canWatch) return;
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    final currentPosition = _videoController!.value.position.inSeconds;
    final totalDuration = _videoController!.value.duration.inSeconds;

    // Validate data
    if (widget.lectureId.isEmpty || totalDuration <= 0) return;

    debugPrint('[LectureDetail] Saving progress on exit: lectureId=${widget.lectureId}, position=$currentPosition, duration=$totalDuration');

    // Use immediate send (no debounce) for exit scenario
    // Fire-and-forget with timeout protection
    _userProgressService.sendProgress(
      lectureId: widget.lectureId,
      currentPosition: currentPosition,
      totalDuration: totalDuration,
      immediate: true,
    ).timeout(const Duration(seconds: 5), onTimeout: () {
      debugPrint('[LectureDetail] Progress save timed out (expected on rapid exit)');
      return {'success': false, 'timeout': true};
    }).catchError((e) {
      debugPrint('[LectureDetail] Error saving progress: $e');
      return {'success': false, 'error': e.toString()};
    });
  }

  /// Legacy method - kept for compatibility but now uses lecture-based tracking
  /// This is called for chapter-based progress (backward compatibility)
  void _updateProgressBeforeLeaving() {
    // Delegate to new lecture-based progress saving
    _saveProgressOnExit();
  }

  void _checkDownloadStatus() {
    final videoId = '${widget.courseId}_${widget.chapterId}';
    final isDownloaded = _encryptedVideoService.isVideoDownloaded(videoId);
    debugPrint('Checking download status for videoId: $videoId, isDownloaded: $isDownloaded');
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }
  }

  Future<void> _downloadVideo() async {
    debugPrint('Download button clicked - videoUrl: $_videoUrl, isLocked: $_isLocked, canWatch: $_canWatch, isOfflineMode: $_isOfflineMode');

    if (!mounted) {
      debugPrint('Cannot download: widget not mounted');
      return;
    }

    // For offline mode, video is already downloaded
    if (_isOfflineMode) {
      debugPrint('Cannot download in offline mode');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('course.video_already_downloaded'.tr()),
            backgroundColor: const Color(0xFF2DBC77),
          ),
        );
      }
      return;
    }

    if (_videoUrl.isEmpty) {
      debugPrint('Cannot download: video URL is empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video URL not available'),
            backgroundColor: Color(0xFFFF4B4B),
          ),
        );
      }
      return;
    }

    if (_isLocked) {
      debugPrint('Cannot download: chapter is locked');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unlock the chapter to download video'),
            backgroundColor: Color(0xFFFF4B4B),
          ),
        );
      }
      return;
    }

    if (!_canWatch) {
      debugPrint('Cannot download: cannot watch video');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot download this video'),
            backgroundColor: Color(0xFFFF4B4B),
          ),
        );
      }
      return;
    }

    final videoId = '${widget.courseId}_${widget.chapterId}';
    debugPrint('Attempting to download video: $videoId');

    // Check if already downloaded
    if (_encryptedVideoService.isVideoDownloaded(videoId)) {
      debugPrint('Video already downloaded: $videoId');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('course.video_already_downloaded'.tr()),
            backgroundColor: const Color(0xFF2DBC77),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Show download started toast
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('course.download_started'.tr()),
        backgroundColor: const Color(0xFF3451E5),
        duration: const Duration(seconds: 2),
      ),
    );

    // Set up progress notifier
    final fileName = 'video_${videoId}.enc';
    _downloadProgressNotifier = _encryptedVideoService.getProgressNotifier(_videoUrl, fileName);

    if (mounted) {
      setState(() => _isDownloading = true);
    }

    // Listen for progress updates
    _downloadProgressNotifier!.addListener(() {
      final progress = _downloadProgressNotifier!.value;
      if (progress.status == EncryptedDownloadStatus.completed) {
        if (mounted) {
          setState(() {
            _isDownloaded = true;
            _isDownloading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('course.video_downloaded'.tr()),
              backgroundColor: const Color(0xFF2DBC77),
            ),
          );
        }
      } else if (progress.status == EncryptedDownloadStatus.failed) {
        if (mounted) {
          setState(() => _isDownloading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(progress.errorMessage ?? 'course.download_failed'.tr()),
              backgroundColor: const Color(0xFFFF4B4B),
            ),
          );
        }
      }
    });

    // Start download with current view count
    try {
      debugPrint('Starting download for videoId: $videoId, URL: $_videoUrl');
      await _encryptedVideoService.downloadVideo(
        url: _videoUrl,
        chapterId: widget.chapterId,
        chapterTitle: widget.chapterTitle,
        lectureTitle: widget.lectureTitle,
        courseId: widget.courseId,
        duration: _duration,
        currentViews: _currentViews,
        maxViews: _maxViews,
      );
      debugPrint('Download method completed for videoId: $videoId');
    } catch (e) {
      debugPrint('Error during download: $e');
      if (mounted) {
        setState(() => _isDownloading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download error: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  void _cancelDownload() {
    if (_isDownloading) {
      _encryptedVideoService.cancelDownload(_videoUrl);
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _loadDiscussions() async {
    setState(() => _isLoadingDiscussions = true);
    try {
      final result = await _discussionRepository.getDiscussions(
        chapterId: int.tryParse(widget.chapterId),
      );
      if (result['success'] && mounted) {
        setState(() {
          _discussions = result['data'] ?? [];
          _isLoadingDiscussions = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingDiscussions = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDiscussions = false);
    }
  }

  Future<void> _startRecording() async {
    debugPrint('Start recording clicked');
    try {
      // Use the record package's built-in permission check
      final hasPermission = await _audioRecorder.hasPermission();
      debugPrint('Has permission: $hasPermission');

      if (hasPermission) {
        debugPrint('Has permission, starting recording...');
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: path);
        debugPrint('Recording started at path: $path');
        
        setState(() {
          _isRecording = true;
          _recordedPath = null;
        });
      } else {
        debugPrint('Permission denied');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('course.mic_permission_required'.tr()),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('course.error_msg'.tr(args: [e.toString()]))),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    debugPrint('Stop recording clicked');
    try {
      final path = await _audioRecorder.stop();
      debugPrint('Recording stopped. Path: $path');
      setState(() {
        _isRecording = false;
        _recordedPath = path;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  Future<void> _postDiscussion() async {
    if (widget.chapterId.isEmpty) return;
    
    final chapterId = int.tryParse(widget.chapterId);
    if (chapterId == null) return;

    final moment = _videoController?.value.position.inSeconds ?? 0;
    
    setState(() => _isLoadingDiscussions = true);

    Map<String, dynamic> result;
    if (_discussionTab == 'voice' && _recordedPath != null) {
      result = await _discussionRepository.postDiscussion(
        chapterId: chapterId,
        type: 'voice',
        content: '',
        moment: moment,
        voiceFile: File(_recordedPath!),
      );
    } else {
      if (_commentController.text.trim().isEmpty) {
        setState(() => _isLoadingDiscussions = false);
        return;
      }
      result = await _discussionRepository.postDiscussion(
        chapterId: chapterId,
        type: 'text',
        content: _commentController.text.trim(),
        moment: moment,
      );
    }

    if (result['success'] && mounted) {
      _commentController.clear();
      _recordedPath = null;
      _discussionTab = 'all';
      await _loadDiscussions();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('course.discussion_posted'.tr())),
      );
    } else if (mounted) {
      setState(() => _isLoadingDiscussions = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'course.failed_post_discussion'.tr())),
      );
    }
  }

  Future<void> _loadChapterDetails() async {
    if (widget.chapterId.isEmpty) {
      setState(() {
        _isLoadingChapter = false;
        _errorMessage = 'course.invalid_chapter_id'.tr();
      });
      return;
    }

    setState(() => _isLoadingChapter = true);
    try {
      final result = await _chapterRepository.getChapterById(widget.chapterId);
      if (result['success'] && mounted) {
        final data = result['data'] ?? {};
        final attributes = data['attributes'] ?? {};
        
        setState(() {
          _chapterData = data;
          _isLocked = attributes['is_locked'] as bool? ?? true;
          _canWatch = attributes['can_watch'] as bool? ?? false;
          _isActivated = attributes['is_activated'] as bool? ?? false;
          _maxViews = attributes['max_views'] as int? ?? 5;
          _currentViews = attributes['current_user_views'] as int? ?? 0;
          _viewByMinute = attributes['view_by_minute'] as int? ?? 0;
          _duration = attributes['duration']?.toString() ?? '00:00';
          _totalTime = _duration;
          
          // Get video URL from attributes (new API response structure)
          String video = attributes['video']?.toString() ?? '';
          if (video.isNotEmpty) {
            video = video.replaceAll('\\', '/');
            if (!video.startsWith('http')) {
              if (!video.startsWith('/')) {
                video = '/$video';
              }
              _videoUrl = '${ApiConstants.baseUrl}$video';
            } else {
              _videoUrl = video;
            }
          }
          
          // Parse available video quality URLs
          _parseQualityUrls(attributes);

          final attachments = attributes['attachments'] as List<dynamic>? ?? [];
          _attachments = attachments;
          
          _quizzes = attributes['quizzes'] as List<dynamic>? ?? [];
          _discussions = attributes['discussions'] as List<dynamic>? ?? [];
          
          _isLoadingChapter = false;

          // Initialize view tracker
          _initViewTracker();

          if (!_isLocked && _videoUrl.isNotEmpty) {
            _initializeVideoPlayer();
          }

          // Check if video is already downloaded
          _checkDownloadStatus();
        });
      } else if (mounted) {
        setState(() {
          _isLoadingChapter = false;
          _errorMessage = result['message'] ?? 'course.failed_load_chapter'.tr();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingChapter = false;
          _errorMessage = 'course.connection_error'.tr(args: [e.toString()]);
        });
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoUrl.isEmpty) return;

    // Check connectivity before initializing
    final hasInternet = await _videoHandler.checkConnectivity();
    if (!hasInternet && !_isOfflineMode) {
      setState(() {
        _hasVideoError = true;
        _videoErrorType = VideoErrorType.network;
        _isVideoLoading = false;
      });
      return;
    }

    setState(() {
      _isVideoLoading = true;
      _hasVideoError = false;
      _videoErrorType = VideoErrorType.unknown;
    });

    try {
      await _videoHandler.initialize(
        videoUrl: _videoUrl,
        onError: _onVideoError,
        onBufferingStart: () => setState(() => _isBuffering = true),
        onBufferingEnd: () => setState(() => _isBuffering = false),
      );

      if (!mounted) return;

      _videoHandler.createChewie(
        autoPlay: false,
        onError: _onVideoError,
      );

      setState(() {
        _isVideoLoading = false;
        _totalTime = _formatDuration(_videoController!.value.duration);
      });

      // Seek to initial position if provided
      if (widget.initialPosition > 0) {
        final initialDuration = Duration(seconds: widget.initialPosition);
        await _videoController!.seekTo(initialDuration);
      }

      // Add our video listener for progress tracking
      _videoController!.addListener(_videoListener);

      // Attach view tracker to video controller
      _watchTracker?.attach(_videoController!);
    } catch (e) {
      _onVideoErrorWithMessage(e.toString());
    }
  }

  void _onVideoError() {
    if (!mounted) return;
    final error = _videoController?.value.errorDescription ?? '';
    _onVideoErrorWithMessage(error);
  }

  void _onVideoErrorWithMessage(String errorMessage) {
    if (!mounted) return;

    final errorType = VideoErrorMapper.mapError(errorMessage);

    setState(() {
      _isVideoLoading = false;
      _isBuffering = false;
      _hasVideoError = true;
      _videoErrorType = errorType;

      // Legacy compatibility
      if (errorType == VideoErrorType.network) {
        _hasSlowInternet = true;
      }
    });
  }

  Future<void> _retryVideo() async {
    if (_videoHandler.isRetrying) return;

    _videoHandler.setRetrying(true);

    setState(() {
      _isRetrying = true;
      _hasVideoError = false;
      _videoErrorType = VideoErrorType.unknown;
      _hasSlowInternet = false;
    });

    // Re-check connectivity before retry
    final hasInternet = await _videoHandler.checkConnectivity();

    if (!hasInternet && !_isOfflineMode) {
      setState(() {
        _hasVideoError = true;
        _videoErrorType = VideoErrorType.network;
        _isRetrying = false;
      });
      _videoHandler.setRetrying(false);
      return;
    }

    // Dispose old controller safely
    await _videoHandler.dispose();

    // Reinitialize
    await _initializeVideoPlayer();

    if (mounted) {
      setState(() => _isRetrying = false);
    }
    _videoHandler.setRetrying(false);
  }

  String _getVideoErrorMessage() {
    return VideoErrorMapper.getUserMessage(
      _videoErrorType,
      'course.something_went_wrong',
    );
  }

  /// Switch video quality
  Future<void> _switchQuality(String quality) async {
    if (_videoQualityUrls.isEmpty || !_videoQualityUrls.containsKey(quality)) return;

    final newUrl = _videoQualityUrls[quality]!;
    if (newUrl == _videoUrl) return;

    // Save current position
    final currentPosition = _videoController?.value.position ?? Duration.zero;
    final wasPlaying = _isPlaying;

    setState(() {
      _currentQuality = quality;
      _videoUrl = newUrl;
      _showQualitySelector = false;
      _hasSlowInternet = false;
      _hasVideoError = false;
    });

    // Dispose old controllers via handler
    await _videoHandler.dispose();

    // Initialize with new quality
    await _initializeVideoPlayerWithPosition(currentPosition, wasPlaying);
  }
  
  /// Initialize video player with a specific starting position
  Future<void> _initializeVideoPlayerWithPosition(Duration startPosition, bool autoPlay) async {
    if (_videoUrl.isEmpty) return;

    // Check connectivity before initializing
    final hasInternet = await _videoHandler.checkConnectivity();
    if (!hasInternet && !_isOfflineMode) {
      setState(() {
        _hasVideoError = true;
        _videoErrorType = VideoErrorType.network;
        _isVideoLoading = false;
      });
      return;
    }

    setState(() {
      _isVideoLoading = true;
      _hasVideoError = false;
      _videoErrorType = VideoErrorType.unknown;
    });

    try {
      await _videoHandler.initialize(
        videoUrl: _videoUrl,
        onError: _onVideoError,
        onBufferingStart: () => setState(() => _isBuffering = true),
        onBufferingEnd: () => setState(() => _isBuffering = false),
      );

      if (!mounted) return;

      // Seek to saved position
      if (startPosition > Duration.zero) {
        await _videoController!.seekTo(startPosition);
      }

      _videoHandler.createChewie(
        autoPlay: autoPlay,
        onError: _onVideoError,
      );

      setState(() {
        _isVideoLoading = false;
        _totalTime = _formatDuration(_videoController!.value.duration);
      });

      // Add our video listener for progress tracking
      _videoController!.addListener(_videoListener);

      // Attach view tracker to video controller
      if (!_isOfflineMode) {
        _watchTracker?.attach(_videoController!);
      }
    } catch (e) {
      _onVideoErrorWithMessage(e.toString());
    }
  }

  /// Parse quality URLs from chapter data
  void _parseQualityUrls(Map<String, dynamic> attributes) {
    _videoQualityUrls = {};
    
    // Main video URL as 'auto' quality
    String mainVideo = attributes['video']?.toString() ?? '';
    if (mainVideo.isNotEmpty) {
      mainVideo = mainVideo.replaceAll('\\', '/');
      if (!mainVideo.startsWith('http')) {
        if (!mainVideo.startsWith('/')) {
          mainVideo = '/$mainVideo';
        }
        mainVideo = '${ApiConstants.baseUrl}$mainVideo';
      }
      _videoQualityUrls['auto'] = mainVideo;
    }
    
    // Check for quality variants in video_qualities field
    final qualities = attributes['video_qualities'] as Map<String, dynamic>?;
    if (qualities != null) {
      qualities.forEach((quality, url) {
        if (url != null && url.toString().isNotEmpty) {
          var videoUrl = url.toString().replaceAll('\\', '/');
          if (!videoUrl.startsWith('http')) {
            if (!videoUrl.startsWith('/')) {
              videoUrl = '/$videoUrl';
            }
            videoUrl = '${ApiConstants.baseUrl}$videoUrl';
          }
          _videoQualityUrls[quality] = videoUrl;
        }
      });
    }
    
    // Also check for nested video qualities
    final videoData = attributes['video'];
    if (videoData is Map<String, dynamic>) {
      videoData.forEach((key, value) {
        if (key != 'url' && value != null && value.toString().isNotEmpty) {
          var videoUrl = value.toString().replaceAll('\\', '/');
          if (!videoUrl.startsWith('http')) {
            if (!videoUrl.startsWith('/')) {
              videoUrl = '/$videoUrl';
            }
            videoUrl = '${ApiConstants.baseUrl}$videoUrl';
          }
          if (!_videoQualityUrls.containsKey(key)) {
            _videoQualityUrls[key] = videoUrl;
          }
        }
      });
    }
  }

  Future<void> _initializeOfflineVideo() async {
    if (widget.offlineVideoPath == null || widget.offlineVideoKey == null) return;

    // Load downloaded video to check view counts
    await _encryptedVideoService.loadDownloadedVideos();
    final videoId = '${widget.courseId}_${widget.chapterId}';
    final downloadedVideo = _encryptedVideoService.getDownloadedVideo(videoId);

    if (downloadedVideo != null) {
      // Check if views are exhausted
      if (downloadedVideo.currentViews >= downloadedVideo.maxViews) {
        debugPrint('Views exhausted for video: $videoId. Deleting downloaded video.');
        // Delete the downloaded video
        await _encryptedVideoService.deleteDownloadedVideo(videoId);
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
            _hasVideoError = true;
            _videoErrorType = VideoErrorType.source;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Views exhausted. Downloaded video has been deleted.'),
              backgroundColor: Color(0xFFFF4B4B),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isVideoLoading = true;
      _hasVideoError = false;
    });

    try {
      debugPrint('Initializing offline video from: ${widget.offlineVideoPath}');

      // Decrypt the video file
      final encryptedFile = File(widget.offlineVideoPath!);
      if (!await encryptedFile.exists()) {
        throw Exception('Downloaded video file not found');
      }

      // Read encrypted data
      final encryptedData = await encryptedFile.readAsBytes();

      // Decrypt data using XOR
      final keyBytes = base64.decode(widget.offlineVideoKey!);
      final decryptedData = Uint8List(encryptedData.length);
      for (var i = 0; i < encryptedData.length; i++) {
        decryptedData[i] = encryptedData[i] ^ keyBytes[i % keyBytes.length];
      }

      // Write to temp file for playback
      final tempDir = await getTemporaryDirectory();
      final tempFilePath = '${tempDir.path}/offline_video_${widget.chapterId}.mp4';
      final tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(decryptedData);

      // Initialize video player with temp file via handler
      await _videoHandler.initializeFromFile(
        videoFile: tempFile,
        onError: _onVideoError,
        onBufferingStart: () => setState(() => _isBuffering = true),
        onBufferingEnd: () => setState(() => _isBuffering = false),
      );

      if (mounted) {
        _videoHandler.createChewie(
          autoPlay: false,
          onError: _onVideoError,
        );

        setState(() {
          _isVideoLoading = false;
          _totalTime = _formatDuration(_videoController!.value.duration);
          _duration = _totalTime;
        });

        // Seek to initial position if provided
        if (widget.initialPosition > 0) {
          final initialDuration = Duration(seconds: widget.initialPosition);
          await _videoController!.seekTo(initialDuration);
        }

        // Add listener for progress tracking
        _videoController!.addListener(_videoListener);

        // Reset view tracking AFTER adding listener, using actual video position
        _viewCounted = false;
        _watchedSeconds = 0;
        _lastPosition = _videoController!.value.position;
      }
    } catch (e) {
      debugPrint('Error initializing offline video: $e');
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
          _hasVideoError = true;
          _videoErrorType = VideoErrorType.source;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;

    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;
    final isPlaying = _videoController!.value.isPlaying;
    final isBuffering = _videoController!.value.isBuffering;

    // Detect slow internet based on buffering state
    _detectSlowInternet(isBuffering, isPlaying);

    // Track watch time for view counting
    // Only count time when video is actually playing
    if (isPlaying && !_isOfflineMode && !_viewCounted) {
      // If just started playing (transition from paused to playing),
      // reset _lastPosition to current position so we only count from now
      if (!_wasPlaying) {
        _lastPosition = position;
        debugPrint('Started tracking watch time from position: $position');
      }

      // Calculate time difference since last position
      final diff = position - _lastPosition;
      if (diff.inSeconds > 0 && diff.inSeconds < 5) {
        // Only count reasonable increments (avoid seeking jumps)
        _watchedSeconds += diff.inSeconds;
        debugPrint('Watch time: $_watchedSeconds / ${_viewByMinute * 60} seconds needed');
        _checkAndCountView();
      }
    }
    _lastPosition = position;
    _wasPlaying = isPlaying;

    // Only update state if values actually changed to reduce rebuilds
    final newTime = _formatDuration(position);
    final newProgress = duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0.0;

    if (newTime != _currentTime || newProgress != _progress || isPlaying != _isPlaying || isBuffering != _isBuffering) {
      setState(() {
        _currentTime = newTime;
        _progress = newProgress;
        _isPlaying = isPlaying;
        _isBuffering = isBuffering;
      });
    }
  }

  /// Detect slow internet connection based on buffering duration
  void _detectSlowInternet(bool isBuffering, bool isPlaying) {
    if (isBuffering && isPlaying) {
      // Video is trying to play but buffering
      if (_bufferingStartTime == null) {
        _bufferingStartTime = DateTime.now();
        _startBufferingTimer();
      }
    } else {
      // Video is playing smoothly or paused - reset buffering state
      _bufferingStartTime = null;
      _bufferingTimer?.cancel();
      if (_hasSlowInternet) {
        setState(() => _hasSlowInternet = false);
      }
    }
  }

  /// Start timer to detect slow internet after threshold
  void _startBufferingTimer() {
    _bufferingTimer?.cancel();
    _bufferingTimer = Timer(_slowInternetThreshold, () {
      if (mounted && _bufferingStartTime != null) {
        setState(() => _hasSlowInternet = true);
      }
    });
  }

  /// Check if error is network-related
  bool _isNetworkError(String errorMessage) {
    final networkErrorKeywords = [
      'timeout', 'connection', 'socket', 'network', 
      'failed to load', 'unable to load', 'internet',
      'unreachable', 'refused', 'failed host lookup'
    ];
    final lowerError = errorMessage.toLowerCase();
    return networkErrorKeywords.any((keyword) => lowerError.contains(keyword));
  }

  /// Retry video with lower quality when slow internet detected
  Future<void> _retryWithLowerQuality() async {
    if (_currentQuality == 'auto' && _videoQualityUrls.containsKey('480p')) {
      await _switchQuality('480p');
    } else if (_currentQuality == '480p' && _videoQualityUrls.containsKey('360p')) {
      await _switchQuality('360p');
    } else {
      // Just retry with same quality
      await _initializeVideoPlayer();
    }
  }

  /// Check if watched time exceeds view_by_minute threshold and count view
  void _checkAndCountView() {
    if (_viewCounted) return;

    int requiredSeconds;
    if (_viewByMinute <= 0) {
      // If view_by_minute is 0, count view after 10 seconds of watching
      // to avoid counting accidental clicks
      requiredSeconds = 10;
    } else {
      requiredSeconds = _viewByMinute * 60;
    }

    if (_watchedSeconds >= requiredSeconds) {
      _viewCounted = true;
      _incrementViewCountInternal();
    }
  }

  /// Call API to increment view count
  Future<void> _incrementViewCountInternal() async {
    // Prevent concurrent API calls
    if (_isCountingView) return;
    _isCountingView = true;

    final chapterId = int.tryParse(widget.chapterId);
    if (chapterId == null) {
      _isCountingView = false;
      return;
    }

    try {
      final result = await _chapterRepository.incrementViewCount(
        chapterId: chapterId,
        watchedMinutes: (_watchedSeconds / 60).ceil(),
      );

      if (result['success'] && mounted) {
        setState(() {
          _currentViews = result['current_views'] ?? _currentViews + 1;
        });
        debugPrint('View counted successfully. Current views: $_currentViews');
        
        // Also save progress immediately after view is counted
        _updateProgressBeforeLeaving();
      } else {
        debugPrint('Failed to count view: ${result['message']}');
      }
    } finally {
      _isCountingView = false;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _togglePlay() {
    if (_videoController == null) return;
    
    setState(() {
      if (_isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _seekTo(double value) {
    if (_videoController == null) return;
    
    final duration = _videoController!.value.duration;
    final position = Duration(seconds: (value * duration.inSeconds).round());
    _videoController!.seekTo(position);
  }

  Future<void> _activateCode({
    required String code,
    required int itemId,
    required String itemType,
  }) async {
    if (code.isEmpty) return;

    final result = await _chapterRepository.activateCode(
      code: code,
      itemId: itemId,
      itemType: itemType,
    );
    
    if (mounted) {
      if (result['success']) {
        setState(() {
          _isLocked = false;
          _canWatch = true;
        });
        
        _loadChapterDetails();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('course.chapter_unlocked'.tr()),
            backgroundColor: const Color(0xFF2DBC77),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'course.invalid_activation_code'.tr()),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  void _showActivationCodeDialog() {
    final codeController = TextEditingController();
    String selectedType = 'chapter';

    // course_id is passed directly from the chapter list API via widget parameter
    final courseId = int.tryParse(widget.courseId);

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 320),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
        return ScaleTransition(scale: curved, child: FadeTransition(opacity: animation, child: child));
      },
      pageBuilder: (context, animation, secondaryAnimation) => StatefulBuilder(
        builder: (context, setDialogState) => Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3451E5).withValues(alpha: 0.18),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Gradient Header ──────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3451E5), Color(0xFF6C47FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Column(
                      children: [
                        // Lock badge
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                          ),
                          child: const Center(
                            child: FaIcon(FontAwesomeIcons.lock, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'course.chapter_locked'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'course.enter_activation_code'.tr(),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Body ─────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Scope label
                        Text(
                          'course.apply_code_to'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Scope toggle chips
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setDialogState(() => selectedType = 'chapter'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selectedType == 'chapter'
                                        ? const Color(0xFF3451E5)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedType == 'chapter'
                                          ? const Color(0xFF3451E5)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.book,
                                        size: 13,
                                        color: selectedType == 'chapter' ? Colors.white : const Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'course.this_chapter'.tr(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selectedType == 'chapter' ? Colors.white : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setDialogState(() => selectedType = 'course'),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: selectedType == 'course'
                                        ? const Color(0xFF3451E5)
                                        : const Color(0xFFF3F4F6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: selectedType == 'course'
                                          ? const Color(0xFF3451E5)
                                          : const Color(0xFFE5E7EB),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      FaIcon(
                                        FontAwesomeIcons.layerGroup,
                                        size: 13,
                                        color: selectedType == 'course' ? Colors.white : const Color(0xFF6B7280),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        'course.full_course'.tr(),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selectedType == 'course' ? Colors.white : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Code field label
                        Text(
                          'course.activation_code'.tr(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: codeController,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            letterSpacing: 1.5,
                            color: Color(0xFF111827),
                          ),
                          decoration: InputDecoration(
                            hintText: 'course.eg_code'.tr(),
                            hintStyle: const TextStyle(
                              letterSpacing: 0.5,
                              color: Color(0xFFD1D5DB),
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(10),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const FaIcon(FontAwesomeIcons.key, size: 14, color: Color(0xFF3451E5)),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF9FAFB),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xFF3451E5), width: 2),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Action Buttons ────────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  foregroundColor: const Color(0xFF6B7280),
                                ),
                                child: Text(
                                  'course.cancel'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF3451E5), Color(0xFF6C47FF)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF3451E5).withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    final code = codeController.text.trim();
                                    if (code.isNotEmpty) {
                                      Navigator.pop(context);
                                      final itemId = selectedType == 'chapter'
                                          ? int.tryParse(widget.chapterId) ?? 0
                                          : courseId ?? 0;
                                      if (itemId > 0) {
                                        _activateCode(
                                          code: code,
                                          itemId: itemId,
                                          itemType: selectedType,
                                        );
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Unable to determine item ID'),
                                            backgroundColor: Color(0xFFFF4B4B),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  icon: const FaIcon(FontAwesomeIcons.unlockKeyhole, size: 14, color: Colors.white),
                                  label: Text(
                                    'course.unlock_now'.tr(),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openAskMoment() {
    setState(() => _showDiscussionPanel = true);
  }

  void _closeDiscussionPanel() {
    setState(() => _showDiscussionPanel = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingChapter) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null && _chapterData == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _buildVideoPlayer(),
              if (_selectedPdfUrl != null)
                Expanded(
                  child: _buildEmbeddedPdfViewer(),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAskButton(),
                        const SizedBox(height: 20),
                        _buildLectureHeader(),
                        const SizedBox(height: 24),
                        _buildAttachmentsSection(),
                        const SizedBox(height: 24),
                        _buildLinkedQuizzes(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showDiscussionPanel) _buildDiscussionPanel(),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                height: 220,
                width: double.infinity,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        height: 20,
                        width: 200,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final isLockedError = _errorMessage?.toLowerCase().contains('locked') == true ||
        _isLocked ||
        _errorMessage?.toLowerCase().contains('activate') == true;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                isLockedError ? FontAwesomeIcons.lock : FontAwesomeIcons.circleExclamation,
                color: isLockedError ? const Color(0xFF3451E5) : const Color(0xFFFF4B4B),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'course.an_error_occurred'.tr(),
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (isLockedError) ...[
                const SizedBox(height: 8),
                Text(
                  'course.views_used'.tr(args: [_currentViews.toString(), _maxViews.toString()]),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              if (isLockedError)
                ElevatedButton.icon(
                  onPressed: _showActivationCodeDialog,
                  icon: const FaIcon(FontAwesomeIcons.key, size: 14),
                  label: Text('course.enter_activation_code_btn'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3451E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _loadChapterDetails,
                  icon: const FaIcon(FontAwesomeIcons.rotateRight, size: 14),
                  label: Text('course.retry'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3451E5),
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _enterFullScreen() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenVideoPlayer(
          videoController: _videoController!,
          chewieController: _chewieController!,
          userId: _userId,
          featureManager: _featureManager,
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          if (_chewieController != null && _videoController != null && _videoController!.value.isInitialized)
            Stack(
              children: [
                WatermarkWrapper(
                  type: WatermarkType.chapters,
                  studentCode: _userId.isNotEmpty ? _userId : null,
                  featureManager: _featureManager,
                  child: Chewie(controller: _chewieController!),
                ),
                // Buffering indicator overlay
                if (_isBuffering)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.3),
                      child: const Center(
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                // Fullscreen toggle button
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _enterFullScreen,
                  ),
                ),
              ],
            )
          else if (_isVideoLoading || _isRetrying)
            const Center(child: CircularProgressIndicator(color: Colors.white))
          else if (_hasVideoError)
            Container(
              color: const Color(0xFF1F2937),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      _videoErrorType == VideoErrorType.network
                          ? FontAwesomeIcons.wifi
                          : FontAwesomeIcons.circleExclamation,
                      color: _videoErrorType == VideoErrorType.network
                          ? Colors.orange
                          : const Color(0xFFFF4B4B),
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _getVideoErrorMessage(),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _retryVideo,
                      icon: _isRetrying
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const FaIcon(FontAwesomeIcons.rotateRight, size: 14),
                      label: Text('course.retry'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3451E5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_isLocked)
            Container(
              color: const Color(0xFF1F2937),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.lock, color: Colors.white, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'course.chapter_locked'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'course.views_used'.tr(args: [_currentViews.toString(), _maxViews.toString()]),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showActivationCodeDialog,
                      icon: const FaIcon(FontAwesomeIcons.key, size: 14),
                      label: Text('course.unlock_now'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3451E5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_videoUrl.isEmpty)
            Container(
              color: const Color(0xFF1F2937),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.film, color: Colors.white, size: 48),
              ),
            )
          else if (_errorMessage != null)
            Container(
              color: const Color(0xFF1F2937),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.circleExclamation, color: Color(0xFFFF4B4B), size: 48),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _initializeVideoPlayer,
                      icon: const FaIcon(FontAwesomeIcons.rotateRight, size: 14),
                      label: Text('course.retry_video'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3451E5),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!_canWatch)
            Container(
              color: const Color(0xFF1F2937),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(FontAwesomeIcons.circlePlay, color: Colors.white54, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'course.views_exhausted'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'course.views_used'.tr(args: [_currentViews.toString(), _maxViews.toString()]),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'course.max_views_reached'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              color: const Color(0xFF1F2937),
              child: Center(
                child: Text('course.video_unavailable'.tr(), style: const TextStyle(color: Colors.white)),
              ),
            ),
          // Slow internet indicator overlay
          if (_hasSlowInternet && !_isOfflineMode)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: _buildSlowInternetWidget(),
              ),
            ),
          
          // Quality selector overlay
          if (_showQualitySelector && !_isOfflineMode && _videoQualityUrls.length > 1)
            Positioned.fill(
              child: Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: Center(
                  child: _buildQualitySelector(),
                ),
              ),
            ),
          
          // Download button overlay - show when video is available
          // In offline mode, show downloaded indicator instead
          if (_isOfflineMode)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF2DBC77).withValues(alpha: 0.8),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.check, color: Colors.white, size: 16),
                ),
              ),
            )
          else if (_videoUrl.isNotEmpty && !_isLocked && _canWatch)
            Positioned(
              top: 12,
              right: 52, // Move left to make room for quality button
              child: _buildDownloadButton(),
            ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required FaIconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FaIcon(icon, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  /// Widget to display when slow internet is detected
  Widget _buildSlowInternetWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated buffering indicator
          SizedBox(
            height: 48,
            width: 48,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const FaIcon(
            FontAwesomeIcons.wifi,
            color: Colors.orange,
            size: 32,
          ),
          const SizedBox(height: 16),
          Text(
            'course.slow_internet_title'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'course.slow_internet_message'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          // Show quality reduction suggestion if available
          if (_videoQualityUrls.length > 1 && (_currentQuality == 'auto' || _currentQuality == '720p'))
            ElevatedButton.icon(
              onPressed: _retryWithLowerQuality,
              icon: const FaIcon(FontAwesomeIcons.circleDown, size: 14),
              label: Text('course.switch_to_lower_quality'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3451E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () {
              setState(() => _hasSlowInternet = false);
              _initializeVideoPlayer();
            },
            icon: const FaIcon(FontAwesomeIcons.rotateRight, size: 14, color: Colors.white70),
            label: Text(
              'course.retry'.tr(),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  /// Quality button displayed in header
  Widget _buildQualityButton() {
    final qualityLabel = _getQualityDisplayLabel(_currentQuality);
    final bool hasMultipleQualities = _videoQualityUrls.length > 1;
    
    return GestureDetector(
      onTap: () {
        if (hasMultipleQualities) {
          setState(() => _showQualitySelector = !_showQualitySelector);
        }
      },
      child: Container(
        height: 32,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: hasMultipleQualities 
              ? const Color(0xFF3451E5).withValues(alpha: 0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: hasMultipleQualities
              ? Border.all(color: const Color(0xFF3451E5).withValues(alpha: 0.3))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.gear,
              color: hasMultipleQualities ? const Color(0xFF3451E5) : Colors.grey[500],
              size: 12,
            ),
            const SizedBox(width: 6),
            Text(
              qualityLabel,
              style: TextStyle(
                color: hasMultipleQualities ? const Color(0xFF3451E5) : Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasMultipleQualities) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down,
                color: const Color(0xFF3451E5).withValues(alpha: 0.7),
                size: 14,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Get display label for quality
  String _getQualityDisplayLabel(String quality) {
    switch (quality) {
      case 'auto':
        return 'course.quality_auto'.tr();
      case '1080p':
        return '1080p';
      case '720p':
        return '720p';
      case '480p':
        return '480p';
      case '360p':
        return '360p';
      case '240p':
        return '240p';
      default:
        return quality.toUpperCase();
    }
  }

  /// Quality selector dialog/popup
  Widget _buildQualitySelector() {
    final qualities = _videoQualityUrls.keys.toList()..sort((a, b) {
      // Sort by quality priority: auto > 1080p > 720p > 480p > 360p > 240p
      final priority = {'auto': 0, '1080p': 1, '720p': 2, '480p': 3, '360p': 4, '240p': 5};
      return (priority[a] ?? 99).compareTo(priority[b] ?? 99);
    });
    
    // If no qualities available, just show current quality info
    if (qualities.isEmpty) {
      qualities.add(_currentQuality);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.gear,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'course.video_quality'.tr(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showQualitySelector = false),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 8),
          ...qualities.map((quality) {
            final isSelected = quality == _currentQuality;
            return GestureDetector(
              onTap: () => _switchQuality(quality),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3451E5) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (isSelected)
                      const FaIcon(
                        FontAwesomeIcons.check,
                        color: Colors.white,
                        size: 14,
                      )
                    else
                      const SizedBox(width: 14),
                    const SizedBox(width: 12),
                    Text(
                      _getQualityDisplayLabel(quality),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    if (quality == 'auto')
                      Text(
                        'course.recommended'.tr(),
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildDownloadButton() {
    // Show downloading progress
    if (_isDownloading && _downloadProgressNotifier != null) {
      return ValueListenableBuilder<EncryptedDownloadProgress>(
        valueListenable: _downloadProgressNotifier!,
        builder: (context, progress, child) {
          return GestureDetector(
            onTap: _cancelDownload,
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress.progress,
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                    const FaIcon(FontAwesomeIcons.xmark, color: Colors.white, size: 12),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Show downloaded icon if already downloaded
    if (_isDownloaded) {
      return Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF2DBC77).withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: FaIcon(FontAwesomeIcons.check, color: Colors.white, size: 16),
        ),
      );
    }

    // Show download button
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          debugPrint('Download button tapped - starting download');
          _downloadVideo();
        },
        customBorder: const CircleBorder(),
        splashColor: Colors.white.withValues(alpha: 0.3),
        highlightColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: FaIcon(FontAwesomeIcons.download, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildAskButton() {
    return GestureDetector(
      onTap: () {
        debugPrint('Ask button clicked');
        _openAskMoment();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF3451E5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.solidCommentDots, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Text(
              'course.ask_about_moment'.tr(args: [_currentTime]),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.lectureTitle,
                style: const TextStyle(
                  color: Color(0xFF3451E5),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            // Quality button in header (reliable click area)
            // if (_chewieController != null && _videoController != null && 
            //     _videoController!.value.isInitialized && !_isOfflineMode)
            //   Padding(
            //     padding: const EdgeInsets.only(right: 8),
            //     child: _buildQualityButton(),
            //   ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _currentViews >= _maxViews
                    ? const Color(0xFFFFF0F0)
                    : const Color(0xFFE8F9F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'course.views_used'.tr(args: [_currentViews.toString(), _maxViews.toString()]),
                style: TextStyle(
                  color: _currentViews >= _maxViews
                      ? const Color(0xFFFF4B4B)
                      : const Color(0xFF2DBC77),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.chapterTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.grey[400]),
            const SizedBox(width: 6),
            Text(
              'course.duration_label'.tr(args: [_duration]),
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_isLocked)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.lock, size: 12, color: Color(0xFFFF4B4B)),
                    SizedBox(width: 4),
                    Text(
                      'Locked',
                      style: TextStyle(
                        color: Color(0xFFFF4B4B),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            if (_isActivated)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F9F0),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  children: [
                    FaIcon(FontAwesomeIcons.check, size: 12, color: Color(0xFF2DBC77)),
                    SizedBox(width: 4),
                    Text(
                      'Activated',
                      style: TextStyle(
                        color: Color(0xFF2DBC77),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachmentsSection() {
    if (_attachments.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'course.attachments'.tr(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        ..._attachments.map((attachment) {
          final attrs = attachment['attributes'] ?? {};
          final name = attrs['name']?.toString() ?? 'course.attachment'.tr();
          final size = attrs['size']?.toString() ?? '0';
          final extension = attrs['extension']?.toString() ?? '';
          final isLocked = attrs['is_locked'] as bool? ?? false;
          final path = attrs['path']?.toString() ?? '';

          return _buildAttachmentItem(name, size, extension, isLocked, path);
        }).toList(),
      ],
    );
  }

  Widget _buildAttachmentItem(String name, String size, String extension, bool isLocked, String? path) {
    final isPdf = extension.toLowerCase() == 'pdf';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPdf ? const Color(0xFFFFE4E1) : const Color(0xFFEDEDFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              isLocked ? FontAwesomeIcons.lock : (isPdf ? FontAwesomeIcons.filePdf : FontAwesomeIcons.paperclip),
              color: isPdf ? const Color(0xFFE74C3C) : const Color(0xFF3451E5),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'course.attachment_size_ext'.tr(args: [size, extension]),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!isLocked && isPdf && path != null && path.isNotEmpty)
            Row(
              children: [
                // View PDF button
                GestureDetector(
                  onTap: () => _openPdf(path, name),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3451E5),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const FaIcon(FontAwesomeIcons.eye, color: Colors.white, size: 16),
                  ),
                ),
                // Share button
                GestureDetector(
                  onTap: () => _shareAttachment(path, name),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const FaIcon(FontAwesomeIcons.shareNodes, color: Color(0xFF25D366), size: 16),
                  ),
                ),
                // Download button
                GestureDetector(
                  onTap: () => _downloadPdf(path, name),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const FaIcon(FontAwesomeIcons.download, color: Color(0xFF6B7280), size: 16),
                  ),
                ),
              ],
            )
          else if (!isLocked)
            Row(
              children: [
                // Share button for non-PDF attachments
                GestureDetector(
                  onTap: () {
                    if (path != null && path.isNotEmpty) {
                      _shareAttachment(path, name);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const FaIcon(FontAwesomeIcons.shareNodes, color: Color(0xFF25D366), size: 16),
                  ),
                ),
                // Download button for non-PDF attachments
                GestureDetector(
                  onTap: () {
                    if (path != null && path.isNotEmpty) {
                      _downloadFile(path, name);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const FaIcon(FontAwesomeIcons.download, color: Color(0xFF6B7280), size: 16),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _openPdf(String path, String name) {
    String pdfUrl = path;
    pdfUrl = pdfUrl.replaceAll('\\', '/');
    if (!pdfUrl.startsWith('http')) {
      if (!pdfUrl.startsWith('/')) {
        pdfUrl = '/$pdfUrl';
      }
      pdfUrl = '${ApiConstants.baseUrl}$pdfUrl';
    }

    setState(() {
      _selectedPdfUrl = pdfUrl;
      _selectedPdfTitle = name;
      _isPdfLoading = true;
      _localPdfPath = null;
    });

    _downloadAndSetPdf(pdfUrl, name);
  }

  Future<void> _downloadAndSetPdf(String url, String title) async {
    try {
      final fileName = '${title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
      _pdfDownloadNotifier = _pdfDownloadService.getProgressNotifier(url, fileName);
      
      final result = await _pdfDownloadService.downloadFile(
        url: url,
        fileName: fileName,
        subDirectory: 'temp',
      );

      if (mounted && _selectedPdfUrl == url) {
        if (result.status == DownloadStatus.completed && result.localPath != null) {
          setState(() {
            _localPdfPath = result.localPath;
            _isPdfLoading = false;
          });
        } else if (result.status == DownloadStatus.failed) {
          setState(() {
            _isPdfLoading = false;
            _errorMessage = result.errorMessage ?? 'course.failed_load_pdf'.tr();
          });
        }
      }
    } catch (e) {
      if (mounted && _selectedPdfUrl == url) {
        setState(() {
          _isPdfLoading = false;
          _errorMessage = 'course.failed_load_pdf'.tr(args: [e.toString()]);
        });
      }
    }
  }

  void _closePdf() {
    setState(() {
      _selectedPdfUrl = null;
      _selectedPdfTitle = null;
      _localPdfPath = null;
      _isPdfLoading = false;
    });
  }

  Future<void> _downloadPdf(String path, String name) async {
    String fileUrl = path;
    fileUrl = fileUrl.replaceAll('\\', '/');
    if (!fileUrl.startsWith('http')) {
      if (!fileUrl.startsWith('/')) {
        fileUrl = '/$fileUrl';
      }
      fileUrl = '${ApiConstants.baseUrl}$fileUrl';
    }

    try {
      final dio = Dio();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';

      await dio.download(fileUrl, filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('course.downloaded_to'.tr(args: [filePath])),
            backgroundColor: const Color(0xFF2DBC77),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('course.download_failed'.tr(args: [e.toString()])),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(String path, String name) async {
    String fileUrl = path;
    fileUrl = fileUrl.replaceAll('\\', '/');
    if (!fileUrl.startsWith('http')) {
      if (!fileUrl.startsWith('/')) {
        fileUrl = '/$fileUrl';
      }
      fileUrl = '${ApiConstants.baseUrl}$fileUrl';
    }

    try {
      final downloadService = DownloadService();
      final result = await downloadService.downloadFile(
        url: fileUrl,
        fileName: name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_'),
        subDirectory: 'downloads',
      );

      if (mounted) {
        if (result.status == DownloadStatus.completed && result.localPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('course.downloaded'.tr(args: [name])),
              backgroundColor: const Color(0xFF2DBC77),
              action: SnackBarAction(
                label: 'share.share'.tr(),
                onPressed: () => _shareFile(result.localPath!, name),
                textColor: Colors.white,
              ),
            ),
          );
        } else if (result.status == DownloadStatus.failed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'course.download_failed'.tr()),
              backgroundColor: const Color(0xFFFF4B4B),
              action: SnackBarAction(
                label: 'course.retry'.tr(),
                onPressed: () => _downloadFile(path, name),
                textColor: Colors.white,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('course.download_failed'.tr(args: [e.toString()])),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  Future<void> _shareAttachment(String path, String name) async {
    String fileUrl = path;
    fileUrl = fileUrl.replaceAll('\\', '/');
    if (!fileUrl.startsWith('http')) {
      if (!fileUrl.startsWith('/')) {
        fileUrl = '/$fileUrl';
      }
      fileUrl = '${ApiConstants.baseUrl}$fileUrl';
    }

    await Share.shareUri(Uri.parse(fileUrl));
  }

  Widget _buildEmbeddedPdfViewer() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Header for PDF viewer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
            ),
            child: Row(
              children: [
                const FaIcon(FontAwesomeIcons.filePdf, color: Color(0xFFE74C3C), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedPdfTitle ?? '',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isPdfLoading && _pdfDownloadNotifier != null)
                        ValueListenableBuilder<DownloadProgress>(
                          valueListenable: _pdfDownloadNotifier!,
                          builder: (context, progress, child) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: LinearProgressIndicator(
                                value: progress.progress > 0 ? progress.progress : null,
                                backgroundColor: Colors.grey[200],
                                color: const Color(0xFF3451E5),
                                minHeight: 2,
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _closePdf,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 16, color: Color(0xFF4B5563)),
                  ),
                ),
              ],
            ),
          ),
          // PDF Content
          Expanded(
            child: _isPdfLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF3451E5)))
                : _localPdfPath != null
                    ? WatermarkWrapper(
                        type: WatermarkType.files,
                        studentCode: _userId.isNotEmpty ? _userId : null,
                        featureManager: _featureManager,
                        child: PDFView(
                          filePath: _localPdfPath,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                          onError: (error) {
                            setState(() {
                              _errorMessage = 'Error loading PDF: $error';
                            });
                          },
                        ),
                      )
                    : Center(
                        child: Text(
                          'course.unable_load_pdf'.tr(),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareFile(String filePath, String name) async {
    await Share.shareUri(Uri.parse(filePath));
  }

  Widget _buildLinkedQuizzes() {
    if (_quizzes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'course.linked_quizzes'.tr(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'course.take_quiz_desc'.tr(),
          style: const TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        ..._quizzes.map((quiz) {
          final attrs = quiz['attributes'] ?? {};
          final id = quiz['id']?.toString() ?? '';
          final title = attrs['title']?.toString() ?? 'course.quiz'.tr();
          final maxAttempts = attrs['max_attempts'] as int? ?? 0;
          final duration = attrs['duration'] as int? ?? 0;
          final quizId = attrs['id'] as int? ?? 0;

          return _buildQuizCard(id, quizId, title, maxAttempts, duration, quiz);
        }).toList(),
      ],
    );
  }

  Widget _buildQuizCard(String id, int quizId, String title, int maxAttempts, int duration, dynamic quizData) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F9F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2DBC77).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF2DBC77),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'course.available'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              FaIcon(FontAwesomeIcons.listCheck, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'course.attempts'.tr(args: [maxAttempts.toString()]),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              FaIcon(FontAwesomeIcons.clock, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'course.duration_min'.tr(args: [duration.toString()]),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _startQuiz(quizId, quizData),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DBC77),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text(
                'course.start_quiz'.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startQuiz(int quizId, dynamic quizData) async {
    if (quizId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('course.invalid_quiz_id'.tr()),
          backgroundColor: const Color(0xFFFF4B4B),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2DBC77),
        ),
      ),
    );

    final examRepository = ExamRepository();

    // Start quiz attempt
    final attemptResult = await examRepository.startQuizAttempt(quizId);

    if (!mounted) return;
    Navigator.pop(context); // Close loading dialog

    if (attemptResult['success']) {
      final attempt = attemptResult['data'] as QuizAttempt;
      final quiz = Quiz.fromJson(quizData);

      // Navigate to quiz screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(
            quiz: quiz,
            attempt: attempt,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(attemptResult['message'] ?? 'course.failed_start_quiz'.tr()),
          backgroundColor: const Color(0xFFFF4B4B),
        ),
      );
    }
  }

  Widget _buildDiscussionPanel() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Column(
        children: [
          GestureDetector(
            onTap: _closeDiscussionPanel,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.15,
              color: Colors.transparent,
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 8, 0),
                    child: Row(
                      children: [
                        Text(
                          'course.ask_about_moment_title'.tr(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _closeDiscussionPanel,
                          icon: const Icon(Icons.close, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  _buildDiscussionTabs(),
                  if (_discussionTab != 'all') _buildDiscussionInput(),
                  Expanded(
                    child: _isLoadingDiscussions
                        ? _buildDiscussionSkeleton()
                        : _discussions.isEmpty
                            ? _buildEmptyDiscussions()
                            : _buildDiscussionsList(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildTabItem('course.all_discussions'.tr(), 'all'),
          _buildTabItem('course.comment'.tr(), 'comment'),
          _buildTabItem('course.voice'.tr(), 'voice'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, String tab) {
    bool isSelected = _discussionTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _discussionTab = tab),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF3451E5) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionInput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'course.about_moment'.tr(args: [_currentTime]),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _discussionTab == 'comment' ? 'comment' : 'voice',
                  style: const TextStyle(
                    color: Color(0xFF3451E5),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _discussionTab = 'all'),
                child: const Icon(Icons.close, size: 18, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_discussionTab == 'comment')
            TextField(
              controller: _commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'course.write_comment_moment'.tr(),
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            )
          else
            _buildVoiceRecorderUI(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _postDiscussion,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3451E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                _discussionTab == 'comment' ? 'course.post_comment'.tr() : 'course.post_voice_note'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRecorderUI() {
    if (_recordedPath != null) {
      return _buildRecordedPreview();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            _isRecording ? Icons.mic : Icons.mic_none,
            size: 48,
            color: _isRecording ? const Color(0xFF3451E5) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(height: 12),
          Text(
            _isRecording ? 'course.recording'.tr() : 'course.tap_to_record'.tr(),
            style: TextStyle(
              color: _isRecording ? const Color(0xFF3451E5) : const Color(0xFF6B7280),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  debugPrint('Record button tapped, isRecording: $_isRecording');
                  if (_isRecording) {
                    _stopRecording();
                  } else {
                    _startRecording();
                  }
                },
                borderRadius: BorderRadius.circular(32),
                child: Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3451E5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3451E5).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordedPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  if (_recordedPlayer.state == PlayerState.playing) {
                    await _recordedPlayer.pause();
                  } else {
                    await _recordedPlayer.play(DeviceFileSource(_recordedPath!));
                  }
                  setState(() {});
                },
                child: Icon(
                  _recordedPlayer.state == PlayerState.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: const Color(0xFF3451E5),
                  size: 32,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ValueListenableBuilder<Duration>(
                  valueListenable: _recordedTotalDuration,
                  builder: (context, totalDuration, child) {
                    return ValueListenableBuilder<Duration>(
                      valueListenable: _recordedPosition,
                      builder: (context, position, child) {
                        return LinearProgressIndicator(
                          value: totalDuration.inMilliseconds > 0
                              ? position.inMilliseconds / totalDuration.inMilliseconds
                              : 0.0,
                          backgroundColor: const Color(0xFFE5E7EB),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3451E5)),
                          borderRadius: BorderRadius.circular(4),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<Duration>(
                valueListenable: _recordedTotalDuration,
                builder: (context, totalDuration, child) {
                  return Text(
                    _formatDuration(totalDuration),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: () {
                  setState(() => _recordedPath = null);
                  _recordedPosition.value = Duration.zero;
                  _recordedTotalDuration.value = Duration.zero;
                  _recordedPlayer.stop();
                },
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 28),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    debugPrint('Re-record button tapped');
                    _startRecording();
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3451E5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic, color: Colors.white, size: 28),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _postDiscussion,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 56,
                    width: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3451E5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(radius: 20, backgroundColor: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 100, color: Colors.white),
                    const SizedBox(height: 8),
                    Container(height: 10, width: double.infinity, color: Colors.white),
                    const SizedBox(height: 4),
                    Container(height: 10, width: 150, color: Colors.white),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyDiscussions() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 16),
          Text(
            'course.no_discussions_yet'.tr(),
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'course.be_the_first_discussion'.tr(),
            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: _discussions.length,
      itemBuilder: (context, index) {
        final discussion = _discussions[index];
        final attributes = discussion['attributes'] ?? {};
        final user = attributes['user']?['data']?['attributes'] ?? {};
        final firstName = user['first_name'] ?? '';
        final lastName = user['last_name'] ?? '';
        final role = user['role'] ?? '';
        final content = attributes['content'] ?? '';
        final type = attributes['type'] ?? 'text';
        final moment = attributes['moment'] ?? 0;
        final createdAt = attributes['created_at'] ?? '';
        final replies = attributes['replies'] as List? ?? [];
        
        bool isInstructor = role.toLowerCase() == 'admin' || role.toLowerCase() == 'instructor';

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFE5E7EB),
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U',
                      style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$firstName $lastName',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(createdAt),
                              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 14, color: Color(0xFF4B5563), height: 1.5),
                        children: [
                          TextSpan(
                            text: '${_formatMoment(moment)} ',
                            style: const TextStyle(color: Color(0xFF3451E5), fontWeight: FontWeight.bold),
                          ),
                          TextSpan(text: type == 'text' ? content : 'course.voice_question_linked'.tr()),
                        ],
                      ),
                    ),
                    if (type == 'voice') ...[
                      const SizedBox(height: 12),
                      _buildAudioPlayer(content),
                    ],
                    if (replies.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...replies.map((reply) => _buildReplyItem(reply)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReplyItem(dynamic reply) {
    final attributes = reply['attributes'] ?? {};
    final user = attributes['user']?['data']?['attributes'] ?? {};
    final firstName = user['first_name'] ?? '';
    final lastName = user['last_name'] ?? '';
    final role = user['role'] ?? '';
    final content = attributes['content'] ?? '';
    
    bool isInstructor = role.toLowerCase() == 'admin' || role.toLowerCase() == 'instructor';

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: const Color(0xFF3451E5),
                child: Text(
                  firstName.isNotEmpty ? firstName[0].toUpperCase() : 'I',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$firstName $lastName',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3451E5)),
              ),
              if (isInstructor) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3451E5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'course.instructor'.tr(),
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.5),
          ),
        ],
      ),
    );
  }

  // Cache for audio durations to show before playback starts
  final Map<String, Duration> _audioDurations = {};

  Future<void> _fetchAudioDuration(String url) async {
    if (_audioDurations.containsKey(url)) return;
    
    try {
      final tempPlayer = AudioPlayer();
      await tempPlayer.setSource(UrlSource(url));
      final duration = await tempPlayer.getDuration();
      if (duration != null && mounted) {
        setState(() {
          _audioDurations[url] = duration;
        });
      }
      await tempPlayer.dispose();
    } catch (e) {
      debugPrint('Error fetching audio duration: $e');
    }
  }

  Widget _buildAudioPlayer(String url) {
    bool isThisPlaying = _currentlyPlayingUrl == url;
    
    // Fetch duration if not cached
    if (!isThisPlaying && !_audioDurations.containsKey(url)) {
      _fetchAudioDuration(url);
    }
    
    // Get the duration to display
    final Duration displayDuration = isThisPlaying
        ? _listAudioDuration.value
        : (_audioDurations[url] ?? Duration.zero);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              if (isThisPlaying && _audioPlayer.state == PlayerState.playing) {
                await _audioPlayer.pause();
              } else {
                if (_currentlyPlayingUrl != url) {
                  await _audioPlayer.stop();
                  setState(() => _currentlyPlayingUrl = url);
                  _listAudioPosition.value = Duration.zero;
                  _listAudioDuration.value = _audioDurations[url] ?? Duration.zero;
                }
                await _audioPlayer.play(UrlSource(url));
              }
              setState(() {});
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFF3451E5), shape: BoxShape.circle),
              child: Icon(
                (isThisPlaying && _audioPlayer.state == PlayerState.playing) ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ValueListenableBuilder<Duration>(
              valueListenable: _listAudioDuration,
              builder: (context, listDuration, child) {
                return ValueListenableBuilder<Duration>(
                  valueListenable: _listAudioPosition,
                  builder: (context, listPosition, child) {
                    return Column(
                      children: [
                        LinearProgressIndicator(
                          value: isThisPlaying && listDuration.inMilliseconds > 0
                              ? listPosition.inMilliseconds / listDuration.inMilliseconds
                              : 0.0,
                          backgroundColor: const Color(0xFFD1D5DB),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3451E5)),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isThisPlaying ? _formatDuration(listPosition) : '00:00',
                              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                            ),
                            Text(
                              _formatDuration(displayDuration),
                              style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoment(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(1, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${date.day}/${date.month}';
    } catch (e) {
      return '';
    }
  }
}

/// Fullscreen video player widget that maintains watermark overlay
class _FullScreenVideoPlayer extends StatefulWidget {
  final VideoPlayerController videoController;
  final ChewieController chewieController;
  final String userId;
  final FeatureManager featureManager;

  const _FullScreenVideoPlayer({
    required this.videoController,
    required this.chewieController,
    required this.userId,
    required this.featureManager,
  });

  @override
  State<_FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<_FullScreenVideoPlayer> {
  ChewieController? _fullScreenChewieController;

  @override
  void initState() {
    super.initState();
    _fullScreenChewieController = ChewieController(
      videoPlayerController: widget.videoController,
      autoPlay: true,
      looping: false,
      allowFullScreen: false,
      allowMuting: true,
      showControls: true,
      hideControlsTimer: const Duration(seconds: 3),
    );
  }

  void _exitFullScreen() {
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _fullScreenChewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Video Layer with watermark
          if (_fullScreenChewieController != null)
            WatermarkWrapper(
              type: WatermarkType.chapters,
              studentCode: widget.userId.isNotEmpty ? widget.userId : null,
              featureManager: widget.featureManager,
              child: Chewie(controller: _fullScreenChewieController!),
            ),
          // Exit fullscreen button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.fullscreen_exit, color: Colors.white),
              onPressed: _exitFullScreen,
            ),
          ),
        ],
      ),
    );
  }
}
