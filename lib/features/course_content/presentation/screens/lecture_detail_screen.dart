import 'package:flutter/material.dart';
import 'dart:io';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import '../../../../core/network/api_constants.dart';
import '../../data/chapter_repository.dart';
import '../../data/discussion_repository.dart';
import 'pdf_viewer_screen.dart';
import '../../../exams/presentation/screens/quiz_screen.dart';
import '../../../exams/models/quiz_models.dart';
import '../../../exams/data/exam_repository.dart';

class LectureDetailScreen extends StatefulWidget {
  final String lectureId;
  final String lectureTitle;
  final String chapterId;
  final String chapterTitle;

  const LectureDetailScreen({
    super.key,
    required this.lectureId,
    required this.lectureTitle,
    required this.chapterId,
    required this.chapterTitle,
  });

  @override
  State<LectureDetailScreen> createState() => _LectureDetailScreenState();
}

class _LectureDetailScreenState extends State<LectureDetailScreen> {
  final _chapterRepository = ChapterRepository();
  final _discussionRepository = DiscussionRepository();
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  
  bool _isLoadingChapter = true;
  bool _isLoadingDiscussions = false;
  bool _isInitializingVideo = false;
  Map<String, dynamic>? _chapterData;
  
  bool _isLocked = true;
  bool _canWatch = false;
  bool _isActivated = false;
  int _maxViews = 5;
  int _currentViews = 0;
  String _videoUrl = '';
  String _duration = '00:00';
  List<dynamic> _attachments = [];
  List<dynamic> _quizzes = [];
  List<dynamic> _discussions = [];

  bool _isPlaying = false;
  double _progress = 0.0;
  String _currentTime = '0:00';
  String _totalTime = '0:00';
  
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

  @override
  void initState() {
    super.initState();
    _loadChapterDetails();
    _loadDiscussions();
    
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
  void dispose() {
    // Update user progress before leaving
    _updateProgressBeforeLeaving();

    _videoController?.dispose();
    _chewieController?.dispose();
    _commentController.dispose();
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
    super.dispose();
  }

  void _updateProgressBeforeLeaving() {
    final chapterId = int.tryParse(widget.chapterId);
    if (chapterId == null) return;

    final progressSeconds = _videoController?.value.position.inSeconds ?? 0;
    final totalSeconds = _videoController?.value.duration.inSeconds ?? 0;
    final isCompleted = totalSeconds > 0 && progressSeconds >= totalSeconds - 5;

    // Fire-and-forget: don't await, just send the request
    _chapterRepository.updateUserProgress(
      chapterId: chapterId,
      progressSeconds: progressSeconds,
      isCompleted: isCompleted,
    );
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
            const SnackBar(
              content: Text('Microphone permission is required to record voice notes'),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        const SnackBar(content: Text('Discussion posted successfully')),
      );
    } else if (mounted) {
      setState(() => _isLoadingDiscussions = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to post discussion')),
      );
    }
  }

  Future<void> _loadChapterDetails() async {
    if (widget.chapterId.isEmpty) {
      setState(() {
        _isLoadingChapter = false;
        _errorMessage = 'Invalid chapter ID';
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
          _duration = attributes['duration']?.toString() ?? '00:00';
          _totalTime = _duration;
          
          final attachments = attributes['attachments'] as List<dynamic>? ?? [];
          _attachments = attachments;
          if (attachments.isNotEmpty) {
            // Find the video attachment (extension mp4)
            final videoAttachment = attachments.firstWhere(
              (a) => (a['attributes']?['extension']?.toString().toLowerCase() == 'mp4'),
              orElse: () => attachments.first,
            );
            
            final attachmentAttrs = videoAttachment['attributes'] ?? {};
            String path = attachmentAttrs['path']?.toString() ?? '';
            
            // Fix backslashes in URL and ensure it's absolute
            if (path.isNotEmpty) {
              path = path.replaceAll('\\', '/');
              if (!path.startsWith('http')) {
                _videoUrl = '${ApiConstants.baseUrl}$path';
              } else {
                _videoUrl = path;
              }
            }
          }
          
          _quizzes = attributes['quizzes'] as List<dynamic>? ?? [];
          _discussions = attributes['discussions'] as List<dynamic>? ?? [];
          
          _isLoadingChapter = false;
          
          if (!_isLocked && _videoUrl.isNotEmpty) {
            _initializeVideoPlayer();
          }
        });
      } else if (mounted) {
        setState(() {
          _isLoadingChapter = false;
          _errorMessage = result['message'] ?? 'Failed to load chapter';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingChapter = false;
          _errorMessage = 'Connection error: $e';
        });
      }
    }
  }

  Future<void> _initializeVideoPlayer() async {
    if (_videoUrl.isEmpty) return;
    
    setState(() => _isInitializingVideo = true);
    
    try {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(_videoUrl));
      await _videoController!.initialize();
      
      if (mounted) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController!,
          autoPlay: false,
          looping: false,
          aspectRatio: _videoController!.value.aspectRatio,
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            );
          },
        );

        setState(() {
          _isInitializingVideo = false;
          _totalTime = _formatDuration(_videoController!.value.duration);
        });
        
        _videoController!.addListener(_videoListener);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializingVideo = false;
          _errorMessage = 'Failed to load video: $e';
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _videoController == null) return;
    
    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;
    final isPlaying = _videoController!.value.isPlaying;
    
    // Only update state if values actually changed to reduce rebuilds
    final newTime = _formatDuration(position);
    final newProgress = duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0.0;
    
    if (newTime != _currentTime || newProgress != _progress || isPlaying != _isPlaying) {
      setState(() {
        _currentTime = newTime;
        _progress = newProgress;
        _isPlaying = isPlaying;
      });
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

  Future<void> _activateCode(String code) async {
    if (code.isEmpty) return;

    final result = await _chapterRepository.activateCode(code);
    
    if (mounted) {
      if (result['success']) {
        setState(() {
          _isLocked = false;
          _canWatch = true;
        });
        
        _loadChapterDetails();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chapter unlocked successfully!'),
            backgroundColor: Color(0xFF2DBC77),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Invalid activation code'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  void _showActivationCodeDialog() {
    final codeController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.lock, color: Color(0xFFFF4B4B), size: 20),
            SizedBox(width: 10),
            Text('Chapter Locked'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This chapter is locked. Please enter your activation code to unlock it.',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: 'Enter activation code (e.g., ABCD-1234)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const FaIcon(FontAwesomeIcons.key, size: 16),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              if (code.isNotEmpty) {
                Navigator.pop(context);
                _activateCode(code);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3451E5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Unlock'),
          ),
        ],
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
          Column(
            children: [
              _buildVideoPlayer(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                _errorMessage ?? 'An error occurred',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              if (isLockedError) ...[
                const SizedBox(height: 8),
                Text(
                  '$_currentViews / $_maxViews views used',
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
                  label: const Text('Enter Activation Code'),
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
                  label: const Text('Retry'),
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

  Widget _buildVideoPlayer() {
    return Container(
      height: 220,
      width: double.infinity,
      color: Colors.black,
      child: _chewieController != null && _videoController != null && _videoController!.value.isInitialized
          ? Chewie(controller: _chewieController!)
          : _isInitializingVideo
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : _isLocked
                  ? Container(
                      color: const Color(0xFF1F2937),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.lock, color: Colors.white, size: 48),
                            const SizedBox(height: 16),
                            const Text(
                              'Chapter Locked',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_currentViews / $_maxViews views used',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _showActivationCodeDialog,
                              icon: const FaIcon(FontAwesomeIcons.key, size: 14),
                              label: const Text('Unlock Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3451E5),
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _videoUrl.isEmpty
                      ? Container(
                          color: const Color(0xFF1F2937),
                          child: const Center(
                            child: FaIcon(FontAwesomeIcons.film, color: Colors.white, size: 48),
                          ),
                        )
                      : (_errorMessage != null)
                          ? Container(
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
                                      label: const Text('Retry Video'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3451E5),
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : !_canWatch
                          ? Container(
                              color: const Color(0xFF1F2937),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const FaIcon(FontAwesomeIcons.circlePlay, color: Colors.white54, size: 48),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Views Exhausted',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$_currentViews / $_maxViews views used',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'You have reached the maximum number of views for this chapter.',
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
                          : Container(
                              color: const Color(0xFF1F2937),
                              child: const Center(
                                child: Text('Video unavailable', style: TextStyle(color: Colors.white)),
                              ),
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
              'Ask about this moment ($_currentTime)',
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _currentViews >= _maxViews
                    ? const Color(0xFFFFF0F0)
                    : const Color(0xFFE8F9F0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_currentViews / $_maxViews views used',
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
              'Duration: $_duration',
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
        const Text(
          'Attachments',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 12),
        ..._attachments.map((attachment) {
          final attrs = attachment['attributes'] ?? {};
          final name = attrs['name']?.toString() ?? 'Attachment';
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
                  '$size bytes · $extension',
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
    );
  }

  void _openPdf(String path, String name) {
    String pdfUrl = path;
    if (!pdfUrl.startsWith('http')) {
      pdfUrl = '${ApiConstants.baseUrl}$pdfUrl';
    }
    pdfUrl = pdfUrl.replaceAll('\\', '/');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfUrl: pdfUrl,
          title: name,
        ),
      ),
    );
  }

  Future<void> _downloadPdf(String path, String name) async {
    String fileUrl = path;
    if (!fileUrl.startsWith('http')) {
      fileUrl = '${ApiConstants.baseUrl}$fileUrl';
    }
    fileUrl = fileUrl.replaceAll('\\', '/');

    try {
      final dio = Dio();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';

      await dio.download(fileUrl, filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to $filePath'),
            backgroundColor: const Color(0xFF2DBC77),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  Future<void> _downloadFile(String path, String name) async {
    String fileUrl = path;
    if (!fileUrl.startsWith('http')) {
      fileUrl = '${ApiConstants.baseUrl}$fileUrl';
    }
    fileUrl = fileUrl.replaceAll('\\', '/');

    try {
      final dio = Dio();
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${name.replaceAll(RegExp(r'[^a-zA-Z0-9.]'), '_')}';

      await dio.download(fileUrl, filePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to $filePath'),
            backgroundColor: const Color(0xFF2DBC77),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: const Color(0xFFFF4B4B),
          ),
        );
      }
    }
  }

  Widget _buildLinkedQuizzes() {
    if (_quizzes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Linked Quizzes',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Take the quiz related to this chapter after finishing the video.',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 12),
        ..._quizzes.map((quiz) {
          final attrs = quiz['attributes'] ?? {};
          final id = quiz['id']?.toString() ?? '';
          final title = attrs['title']?.toString() ?? 'Quiz';
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
                child: const Text(
                  'Available',
                  style: TextStyle(
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
                '$maxAttempts attempts',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(width: 16),
              FaIcon(FontAwesomeIcons.clock, size: 12, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '$duration min',
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
              child: const Text(
                'START QUIZ',
                style: TextStyle(
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
        const SnackBar(
          content: Text('Invalid quiz ID'),
          backgroundColor: Color(0xFFFF4B4B),
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
          content: Text(attemptResult['message'] ?? 'Failed to start quiz'),
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
                        const Text(
                          'Ask about this moment',
                          style: TextStyle(
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
          _buildTabItem('All Discussions', 'all'),
          _buildTabItem('Comment', 'comment'),
          _buildTabItem('Voice', 'voice'),
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
                'About  $_currentTime',
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
                hintText: 'Write a comment about this moment...',
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
                _discussionTab == 'comment' ? 'Post Comment' : 'Post Voice Note',
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
            _isRecording ? 'Recording...' : 'Tap to record voice note',
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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFFD1D5DB)),
          SizedBox(height: 16),
          Text(
            'No discussions yet',
            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'Be the first to start a conversation!',
            style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 13),
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
                          TextSpan(text: type == 'text' ? content : 'Voice question linked to moment'),
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
                  child: const Text(
                    'Instructor',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
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
