import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../../../core/network/api_constants.dart';
import '../../data/chapter_repository.dart';

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
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  
  bool _isLoadingChapter = true;
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
  
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChapterDetails();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
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
    
    setState(() {
      _currentTime = _formatDuration(position);
      if (duration.inSeconds > 0) {
        _progress = position.inSeconds / duration.inSeconds;
      }
      _isPlaying = _videoController!.value.isPlaying;
    });
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
      onTap: _openAskMoment,
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
          
          return _buildAttachmentItem(name, size, extension, isLocked);
        }).toList(),
      ],
    );
  }

  Widget _buildAttachmentItem(String name, String size, String extension, bool isLocked) {
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
              color: const Color(0xFFEDEDFF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              isLocked ? FontAwesomeIcons.lock : FontAwesomeIcons.paperclip,
              color: const Color(0xFF3451E5),
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
          if (!isLocked)
            GestureDetector(
              onTap: () {},
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
          final title = attrs['title']?.toString() ?? 'Quiz';
          final maxAttempts = attrs['max_attempts'] as int? ?? 0;
          final duration = attrs['duration'] as int? ?? 0;
          
          return _buildQuizCard(title, maxAttempts, duration);
        }).toList(),
      ],
    );
  }

  Widget _buildQuizCard(String title, int maxAttempts, int duration) {
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
              onPressed: () {},
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

  Widget _buildDiscussionPanel() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Column(
        children: [
          const Spacer(),
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text(
                        'Discussions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _closeDiscussionPanel,
                        icon: const FaIcon(FontAwesomeIcons.xmark, size: 20),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _discussions.isEmpty
                      ? const Center(
                          child: Text(
                            'No discussions yet',
                            style: TextStyle(
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _discussions.length,
                          itemBuilder: (context, index) {
                            final discussion = _discussions[index];
                            final attrs = discussion['attributes'] ?? {};
                            final content = attrs['content']?.toString() ?? '';
                            final type = attrs['type']?.toString() ?? 'text';
                            
                            return _buildDiscussionItem(content, type);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscussionItem(String content, String type) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDFF),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              type == 'voice' ? FontAwesomeIcons.microphone : FontAwesomeIcons.comment,
              color: const Color(0xFF3451E5),
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
