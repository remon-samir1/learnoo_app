import 'dart:io';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/services/connectivity_service.dart';
import 'profile_screen.dart';
import 'verification_method_screen.dart';
import '../../data/auth_repository.dart';
import '../../../../features/home/presentation/screens/main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final _authRepository = AuthRepository();
  final Dio _dio = Dio();
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static const int _downloadNotificationId = 100;

  @override
  void initState() {
    super.initState();
    _initNotifications();
    _checkForUpdates();
  }

  Future<void> _initNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _notificationsPlugin.initialize(initSettings);
  }

  Future<void> _showDownloadNotification(int progress, String status) async {
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'Download Updates',
      channelDescription: 'Shows download progress for app updates',
      importance: Importance.low,
      priority: Priority.low,
      showProgress: true,
      maxProgress: 100,
      progress: progress,
      ongoing: true,
      autoCancel: false,
    );
    final iosDetails = DarwinNotificationDetails(
      subtitle: status,
    );
    final notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notificationsPlugin.show(
      _downloadNotificationId,
      'Downloading Update',
      progress > 0 ? '$progress% - $status' : status,
      notificationDetails,
    );
  }

  Future<void> _cancelDownloadNotification() async {
    await _notificationsPlugin.cancel(_downloadNotificationId);
  }

  /// First check for app updates, then proceed with auth
  Future<void> _checkForUpdates() async {
    // Artificial delay for splash effect
    await Future.delayed(const Duration(seconds: 2));

    final updateInfo = await _authRepository.checkForUpdate();

    if (updateInfo != null && updateInfo['hasUpdate'] == true) {
      if (mounted) {
        _showUpdateDialog(updateInfo);
      }
    } else {
      // No update needed, proceed with auth check
      _checkAuth();
    }
  }

  /// Show update dialog with optional skip based on is_force_update
  void _showUpdateDialog(Map<String, dynamic> updateInfo) {
    final isForceUpdate = updateInfo['isForceUpdate'] ?? false;
    final versionName = updateInfo['versionName'] ?? '';
    final fileSize = updateInfo['fileSize'] ?? '';
    final downloadUrl = updateInfo['downloadUrl'] ?? '';

    showDialog(
      context: context,
      barrierDismissible: !isForceUpdate,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => WillPopScope(
          onWillPop: () async => !isForceUpdate && !_isDownloading,
          child: AlertDialog(
            title: Text('update_available'.tr()),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${'new_version'.tr()}: $versionName'),
                if (fileSize != null && fileSize.isNotEmpty)
                  Text('${'file_size'.tr()}: $fileSize'),
                const SizedBox(height: 16),
                Text(
                  isForceUpdate
                      ? 'force_update_message'.tr()
                      : 'optional_update_message'.tr(),
                  style: const TextStyle(fontSize: 14),
                ),
                if (_isDownloading) ...[
                  const SizedBox(height: 16),
                  LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
                  const SizedBox(height: 8),
                  Text(
                    '${(_downloadProgress * 100).toStringAsFixed(0)}% - $_downloadStatus',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isForceUpdate && !_isDownloading)
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _checkAuth();
                  },
                  child: Text('skip'.tr()),
                ),
              ElevatedButton(
                onPressed: _isDownloading
                    ? null
                    : () async {
                        if (downloadUrl.isEmpty) {
                          _showError('Download link is not available. Please try again later.');
                          return;
                        }
                        final hasPermission = await _checkAndRequestInstallPermission();
                        if (hasPermission && mounted) {
                          _downloadAndInstallApk(downloadUrl, setDialogState);
                        }
                      },
                child: _isDownloading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${(_downloadProgress * 100).toStringAsFixed(0)}%'),
                        ],
                      )
                    : Text('update_now'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Download APK and show progress, then install
  Future<void> _downloadAndInstallApk(String downloadUrl, [void Function(void Function())? setDialogState]) async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadStatus = 'Starting download...';
    });
    // Trigger dialog rebuild to show loading state immediately
    setDialogState?.call(() {});

    // Show toast notification that download is starting
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Starting download...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      // Show initial download notification
      await _showDownloadNotification(0, 'Starting download...');

      // Get app-specific cache directory (no storage permission needed)
      final Directory cacheDir = await getTemporaryDirectory();
      final String fileName = 'learnoo_update.apk';
      final String savePath = '${cacheDir.path}/$fileName';

      // Delete old file if exists
      final oldFile = File(savePath);
      if (await oldFile.exists()) {
        await oldFile.delete();
      }

      // Download file with progress
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total > 0) {
            final progress = (received / total * 100).toInt();
            final status = '${_formatBytes(received)} / ${_formatBytes(total)}';
            setState(() {
              _downloadProgress = received / total;
              _downloadStatus = status;
            });
            // Update dialog progress immediately
            setDialogState?.call(() {});
            // Update notification progress
            _showDownloadNotification(progress, status);
          }
        },
      );

      setState(() {
        _isDownloading = false;
        _downloadStatus = 'Download complete. Installing...';
      });
      setDialogState?.call(() {});
      await _showDownloadNotification(100, 'Download complete. Installing...');

      // Close the update dialog
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Install the APK
      await _installApk(savePath);
      await _cancelDownloadNotification();
    } catch (e) {
      setState(() {
        _isDownloading = false;
      });
      setDialogState?.call(() {});
      await _cancelDownloadNotification();
      _showError('Download failed: $e');
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }

  /// Install APK file
  Future<void> _installApk(String filePath) async {
    try {
      final result = await OpenFile.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );

      if (result.type != ResultType.done) {
        // Show manual install dialog if automatic install fails
        _showManualInstallDialog(filePath, result.message);
      }
    } catch (e) {
      _showManualInstallDialog(filePath, e.toString());
    }
  }

  /// Show dialog to manually install APK when automatic install fails
  void _showManualInstallDialog(String filePath, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Install Update'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('The APK has been downloaded but automatic install failed.'),
            const SizedBox(height: 8),
            Text(
              'File location: $filePath',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (errorMessage.isNotEmpty)
              Text(
                '\nError: $errorMessage',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            const SizedBox(height: 16),
            const Text(
              'Please enable "Install unknown apps" permission for this app in Settings, then try again.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkAuth();
            },
            child: const Text('Continue to App'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Try opening the file again
              await OpenFile.open(filePath);
            },
            child: const Text('Try Install Again'),
          ),
        ],
      ),
    );
  }

  /// Check and request install unknown apps permission on Android
  Future<bool> _checkAndRequestInstallPermission() async {
    if (!Platform.isAndroid) return true;

    final status = await Permission.requestInstallPackages.status;
    if (status.isGranted) return true;

    final result = await Permission.requestInstallPackages.request();
    if (result.isGranted) return true;

    if (result.isPermanentlyDenied && mounted) {
      final shouldOpenSettings = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('permission_required'.tr()),
          content: Text('install_unknown_apps_permission_message'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('open_settings'.tr()),
            ),
          ],
        ),
      );
      if (shouldOpenSettings == true) {
        await openAppSettings();
      }
    }
    return false;
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _checkAuth() async {
    final token = await _authRepository.getToken();
    
    // No token found → go to login/register
    if (token == null) {
      _navigateToProfile();
      return;
    }

    // Check internet connectivity
    final hasInternet = await ConnectivityService().hasConnection();
    
    // No internet but token exists → allow entry (offline mode)
    if (!hasInternet) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
      return;
    }

    // Internet available → validate token with API
    final result = await _authRepository.getProfile();
    if (result['success']) {
      final profileData = result['data'];

      // Check if the user has verified their email or phone.
      // If both are null, the account is unverified — send to verification flow.
      final attributes = profileData?['attributes'] ?? profileData;
      final emailVerifiedAt = attributes?['email_verified_at'];
      final phoneVerifiedAt = attributes?['phone_verified_at'];
      final isVerified = emailVerifiedAt != null || phoneVerifiedAt != null;

      if (!isVerified) {
        // User registered but never verified — redirect to verification
        if (mounted) {
          final email = profileData?['email'] ?? '';
          final phone = profileData?['phone'] ?? '';
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VerificationMethodScreen(
                token: token,
                email: email,
                phone: phone,
              ),
            ),
          );
        }
        return;
      }

      // Token valid and user verified → go to home
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } else {
      // API validation failed (401/403) → token is invalid, logout and go to login
      final statusCode = result['statusCode'];
      if (statusCode == 401 || statusCode == 403) {
        await _authRepository.deleteToken();
      }
      _navigateToProfile();
    }
  }

  void _navigateToProfile() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/student_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Blue Overlay (Using semi-transparent primary blue)
          Positioned.fill(
            child: Container(
              color: AppColors.primaryBlue.withValues(alpha: 0.85),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppLogo(size: 100),
                const SizedBox(height: 15),
                const Text(
                  'Learnoo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'auth.academic_journey'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
