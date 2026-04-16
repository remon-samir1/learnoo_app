import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/download_service.dart';
import '../../../../core/widgets/watermark_overlay.dart';
import '../../../../core/widgets/subscription_badge.dart';

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
  String? _errorMessage;
  int _totalPages = 0;
  int _currentPage = 0;
  PDFViewController? _pdfViewController;
  
  // Download service
  final DownloadService _downloadService = DownloadService();
  ValueNotifier<DownloadProgress>? _downloadNotifier;
  
  // User info for watermark
  String _userName = '';
  String _userId = '';
  bool _isSubscribed = true;
  bool _showWatermark = true;
  double _watermarkOpacity = 0.15;

  @override
  void initState() {
    super.initState();
    _downloadAndOpenPdf();
  }

  Future<void> _downloadAndOpenPdf() async {
    try {
      final fileName = '${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
      
      // Initialize progress notifier
      _downloadNotifier = _downloadService.getProgressNotifier(widget.pdfUrl, fileName);
      
      final result = await _downloadService.downloadFile(
        url: widget.pdfUrl,
        fileName: fileName,
        subDirectory: 'temp',
      );

      if (mounted) {
        if (result.status == DownloadStatus.completed && result.localPath != null) {
          setState(() {
            _localFilePath = result.localPath;
            _isLoading = false;
          });
        } else if (result.status == DownloadStatus.failed) {
          setState(() {
            _errorMessage = result.errorMessage ?? 'course.failed_load_pdf'.tr();
            _isLoading = false;
          });
        } else if (result.status == DownloadStatus.cancelled) {
          setState(() {
            _errorMessage = 'course.download_cancelled'.tr();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'course.failed_load_pdf'.tr(args: [e.toString()]);
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _downloadToDevice() async {
    final fileName = '${widget.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}.pdf';
    
    try {
      final result = await _downloadService.downloadFile(
        url: widget.pdfUrl,
        fileName: fileName,
        subDirectory: 'downloads',
      );

      if (mounted) {
        if (result.status == DownloadStatus.completed && result.localPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('course.pdf_saved'.tr(args: [fileName])),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'share.share'.tr(),
                onPressed: () => _sharePdf(result.localPath!),
                textColor: Colors.white,
              ),
            ),
          );
        } else if (result.status == DownloadStatus.failed) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.errorMessage ?? 'course.download_failed'.tr()),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'course.retry'.tr(),
                onPressed: _downloadToDevice,
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
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'course.retry'.tr(),
              onPressed: _downloadToDevice,
              textColor: Colors.white,
            ),
          ),
        );
      }
    }
  }

  Future<void> _sharePdf(String filePath) async {
    await Share.shareUri(Uri.parse(filePath));
  }

  Future<void> _shareUrl() async {
    await Share.shareUri(Uri.parse(widget.pdfUrl));
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
          // Share URL button
          IconButton(
            onPressed: _shareUrl,
            icon: const FaIcon(FontAwesomeIcons.shareNodes, size: 18),
            tooltip: 'share.share_link'.tr(),
          ),
          // Download progress or download button
          ValueListenableBuilder<DownloadProgress>(
            valueListenable: _downloadNotifier ?? ValueNotifier(
              DownloadProgress(url: widget.pdfUrl, fileName: widget.title),
            ),
            builder: (context, progress, child) {
              if (progress.status == DownloadStatus.downloading) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      value: progress.progress > 0 ? progress.progress : null,
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                );
              }
              return IconButton(
                onPressed: _downloadToDevice,
                icon: const FaIcon(FontAwesomeIcons.download, size: 18),
                tooltip: 'course.download_pdf'.tr(),
              );
            },
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
      return Stack(
        children: [
          PDFView(
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
          ),
          // Watermark overlay
          if (_showWatermark)
            WatermarkOverlay(
              userName: _userName.isNotEmpty ? _userName : 'Guest User',
              userId: _userId.isNotEmpty ? _userId : '0',
              opacity: _watermarkOpacity,
              mode: WatermarkMode.diagonal,
            ),
        ],
      );
    }

    return Center(
      child: Text('course.unable_load_pdf'.tr()),
    );
  }
}
