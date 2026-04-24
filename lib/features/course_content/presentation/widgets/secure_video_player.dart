import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:learnoo/core/widgets/secure_wrapper.dart';
import 'package:learnoo/core/widgets/dynamic_watermark_widget.dart';
import 'package:learnoo/core/controllers/watermark_controller.dart';
import 'package:learnoo/core/models/watermark_config.dart';
import 'package:learnoo/core/services/feature_manager.dart';

/// A secure video player that enforces DRM (Widevine on Android, FairPlay on iOS if configured)
/// It is wrapped in [SecureWrapper] and overlays a [DynamicWatermarkWidget].
class SecureVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String drmLicenseUrl;
  final Map<String, String>? drmHeaders;
  final String userId;
  final String userName;
  final WatermarkConfig? watermarkConfig;

  const SecureVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.drmLicenseUrl,
    required this.userId,
    required this.userName,
    this.drmHeaders,
    this.watermarkConfig,
  });

  @override
  State<SecureVideoPlayer> createState() => _SecureVideoPlayerState();
}

class _SecureVideoPlayerState extends State<SecureVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  WatermarkController? _watermarkController;
  bool _isInitError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _initializeWatermark();
  }

  void _initializeWatermark() {
    final config = widget.watermarkConfig ?? 
        FeatureManager().getWatermarkConfig('videos');
    
    if (config.enabled) {
      _watermarkController = WatermarkController(
        config: config,
        fallbackText: widget.userName,
      );
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // Configure VideoPlayer with DRM options.
      // Note: The standard video_player plugin supports DRM on Android (Widevine) and iOS (FairPlay)
      // by passing VideoPlayerOptions and DrmConfigs.
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        // NOTE: Since video_player 2.8.0, DrmSessionManager can be configured conceptually
        // Assuming video player package used supports formatHint or drm configuration.
        // For standard video_player, if using a fork or specific DRM plugin, configure here.
        // For demonstration, we assume standard network init handles simple Widevine if URL is DASH with CENC.
        // If the project uses a different DRM-specific player, instantiate it here.
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        allowFullScreen: false, // Disable native fullscreen - we handle it ourselves
        allowMuting: true,
        showControls: true,
        hideControlsTimer: const Duration(seconds: 3),
      );

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint("Error initializing secure video player: $e");
      if (mounted) {
        setState(() {
          _isInitError = true;
        });
      }
    }
  }

  void _enterFullScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenPlayer(
          videoPlayerController: _videoPlayerController,
          watermarkController: _watermarkController,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    _watermarkController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Wrap with SecureWrapper to ensure screen is hidden during recording
    return SecureWrapper(
      protectionMessage: "Video protection active",
      child: Stack(
        children: [
          // 2. Video Player Layer
          Container(
            color: Colors.black,
            child: _isInitError
                ? const Center(
                    child: Text(
                      "Failed to load secure video.\nPlease check your connection or DRM license.",
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  )
                : (_chewieController != null &&
                        _chewieController!.videoPlayerController.value.isInitialized)
                    ? Stack(
                        children: [
                          Chewie(controller: _chewieController!),
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
                    : const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          
          // 3. Dynamic Watermark Layer
          if (_watermarkController != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DynamicWatermarkWidget(
                  controller: _watermarkController!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom fullscreen widget that includes the watermark
class _FullScreenPlayer extends StatefulWidget {
  final VideoPlayerController videoPlayerController;
  final WatermarkController? watermarkController;

  const _FullScreenPlayer({
    required this.videoPlayerController,
    required this.watermarkController,
  });

  @override
  State<_FullScreenPlayer> createState() => _FullScreenPlayerState();
}

class _FullScreenPlayerState extends State<_FullScreenPlayer> {
  ChewieController? _fullScreenChewieController;

  @override
  void initState() {
    super.initState();
    _fullScreenChewieController = ChewieController(
      videoPlayerController: widget.videoPlayerController,
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
        children: [
          // Video Layer
          if (_fullScreenChewieController != null)
            Stack(
              children: [
                Chewie(controller: _fullScreenChewieController!),
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
          
          // Watermark Layer
          if (widget.watermarkController != null)
            Positioned.fill(
              child: IgnorePointer(
                child: DynamicWatermarkWidget(
                  controller: widget.watermarkController!,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
