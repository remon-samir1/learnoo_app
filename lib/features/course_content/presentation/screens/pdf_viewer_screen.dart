import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// For Android SDK version detection
import 'package:device_info_plus/device_info_plus.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  String? _localFilePath;
  bool _isLoading = true;
  bool _isDownloading = false;
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;

  @override
  void initState() {
    super.initState();
    _downloadAndOpenPdf();
  }

  Future<void> _downloadAndOpenPdf() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final fileName = '${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
      final filePath = '${tempDir.path}/$fileName';

      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }

      final dio = Dio();
      await dio.download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            debugPrint('Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );

      if (mounted) {
        setState(() {
          _localFilePath = filePath;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadToDevice() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      // Check Android SDK version
      if (Platform.isAndroid) {
        final sdkVersion = int.tryParse(
          RegExp(r'API (\d+)').firstMatch(await _getAndroidVersion() ?? '')?.group(1) ?? '0',
        ) ?? 0;

        // For Android 10+ (API 29+), use app directory and share
        // For Android 9 and below (API 28-), request storage permission
        if (sdkVersion < 29) {
          final status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Storage permission denied'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }
      }

      // Download to app directory first
      final fileName = '${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
      late final String downloadPath;

      if (Platform.isAndroid) {
        // Use app documents directory (works on all Android versions)
        final dir = await getApplicationDocumentsDirectory();
        downloadPath = dir.path;
      } else {
        final dir = await getApplicationDocumentsDirectory();
        downloadPath = dir.path;
      }

      final downloadFilePath = '$downloadPath/$fileName';

      final dio = Dio();
      await dio.download(widget.pdfUrl, downloadFilePath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF saved to app storage: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _sharePdf(downloadFilePath),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _sharePdf(String filePath) async {
    // Share functionality would require share_plus package
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality coming soon'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Future<String?> _getAndroidVersion() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return 'API ${androidInfo.version.sdkInt}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2137D6),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_isDownloading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            IconButton(
              onPressed: _downloadToDevice,
              icon: const FaIcon(FontAwesomeIcons.download, size: 18),
              tooltip: 'Download PDF',
            ),
        ],
        bottom: _totalPages > 0
            ? PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Page ${_currentPage + 1} of $_totalPages',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF2137D6)),
            SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _downloadAndOpenPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2137D6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_localFilePath != null) {
      return PDFView(
        filePath: _localFilePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: false,
        onRender: (pages) {
          setState(() {
            _totalPages = pages!;
          });
        },
        onViewCreated: (controller) {
          _pdfViewController = controller;
        },
        onPageChanged: (page, total) {
          setState(() {
            _currentPage = page!;
          });
        },
        onError: (error) {
          setState(() {
            _errorMessage = 'Error loading PDF: $error';
          });
        },
      );
    }

    return const Center(
      child: Text('Unable to load PDF'),
    );
  }
}
