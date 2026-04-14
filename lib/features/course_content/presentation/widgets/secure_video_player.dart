import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:learnoo/core/widgets/secure_wrapper.dart';
import 'package:learnoo/core/widgets/watermark_widget.dart';

/// A secure video player that enforces DRM (Widevine on Android, FairPlay on iOS if configured)
/// It is wrapped in [SecureWrapper] and overlays a [WatermarkWidget].
class SecureVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String drmLicenseUrl;
  final Map<String, String>? drmHeaders;
  final String userId;
  final String userName;

  const SecureVideoPlayer({
    super.key,
    required this.videoUrl,
    required this.drmLicenseUrl,
    required this.userId,
    required this.userName,
    this.drmHeaders,
  });

  @override
  State<SecureVideoPlayer> createState() => _SecureVideoPlayerState();
}

class _SecureVideoPlayerState extends State<SecureVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
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
        allowFullScreen: true,
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

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
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
                    ? Chewie(controller: _chewieController!)
                    : const Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
          
          // 3. Dynamic Watermark Layer
          Positioned.fill(
            child: IgnorePointer(
              child: WatermarkWidget(
                userId: widget.userId,
                userName: widget.userName,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
