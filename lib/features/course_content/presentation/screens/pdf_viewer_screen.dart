import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../core/services/download_service.dart';
import '../../../../core/widgets/watermark_wrapper.dart';
import '../../../../core/services/feature_manager.dart';
import '../../../../core/widgets/subscription_badge.dart';

enum DrawingMode { none, pen, highlighter, eraser }

class DrawPoint {
  final Offset offset;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;

  DrawPoint({
    required this.offset,
    required this.color,
    required this.strokeWidth,
    this.isHighlighter = false,
  });
}

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

  // Drawing/Annotation state
  DrawingMode _drawingMode = DrawingMode.none;
  Color _penColor = Colors.red;
  double _penWidth = 3.0;
  List<DrawPoint> _drawPoints = [];
  bool _showAnnotationToolbar = false;

  // Download service
  final DownloadService _downloadService = DownloadService();
  ValueNotifier<DownloadProgress>? _downloadNotifier;

  // Feature manager for watermark settings
  final FeatureManager _featureManager = FeatureManager();

  // User info for watermark
  String _userName = '';
  String _userId = '';
  bool _isSubscribed = true;

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
          // Annotation toggle button
          IconButton(
            onPressed: () {
              setState(() {
                _showAnnotationToolbar = !_showAnnotationToolbar;
                if (!_showAnnotationToolbar) {
                  _drawingMode = DrawingMode.none;
                }
              });
            },
            icon: FaIcon(
              _showAnnotationToolbar ? FontAwesomeIcons.penToSquare : FontAwesomeIcons.highlighter,
              size: 18,
              color: _showAnnotationToolbar ? Colors.orange : Colors.white,
            ),
            tooltip: 'pdf.annotation_tools'.tr(),
          ),
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
      return Column(
        children: [
          // Annotation Toolbar
          if (_showAnnotationToolbar)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drawing Tools
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        _buildDrawingToolButton(
                          FontAwesomeIcons.pen,
                          'pdf.pen'.tr(),
                          DrawingMode.pen,
                          Colors.red,
                        ),
                        _buildDrawingToolButton(
                          FontAwesomeIcons.highlighter,
                          'pdf.highlighter'.tr(),
                          DrawingMode.highlighter,
                          Colors.yellow,
                        ),
                        _buildDrawingToolButton(
                          FontAwesomeIcons.eraser,
                          'pdf.eraser'.tr(),
                          DrawingMode.eraser,
                          Colors.grey,
                        ),
                        const VerticalDivider(width: 20),
                        // Clear all button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _drawPoints.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.red.withOpacity(0.3)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const FaIcon(FontAwesomeIcons.trash, size: 20, color: Colors.red),
                                const SizedBox(height: 4),
                                Text(
                                  'pdf.clear'.tr(),
                                  style: const TextStyle(fontSize: 10, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Color and Width Selection
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        // Color picker
                        ...[Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange, Colors.black]
                            .map((color) => Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: GestureDetector(
                                    onTap: () => setState(() => _penColor = color),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _penColor == color ? Colors.black : Colors.transparent,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                        const VerticalDivider(width: 20),
                        // Stroke width slider
                        Text('pdf.stroke_width'.tr(), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 100,
                          child: Slider(
                            value: _penWidth,
                            min: 1,
                            max: 10,
                            onChanged: (value) => setState(() => _penWidth = value),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // PDF with Drawing Overlay
          Expanded(
            child: WatermarkWrapper(
              type: WatermarkType.files,
              studentCode: _userId.isNotEmpty ? _userId : null,
              featureManager: _featureManager,
              child: Stack(
                children: [
                  PDFView(
                    filePath: _localFilePath,
                    enableSwipe: _drawingMode == DrawingMode.none,
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
                  // Drawing Overlay
                  if (_showAnnotationToolbar)
                    GestureDetector(
                      onPanStart: _drawingMode == DrawingMode.none
                          ? null
                          : (details) {
                              setState(() {
                                if (_drawingMode == DrawingMode.eraser) {
                                  _eraseNearbyPoints(details.localPosition);
                                } else {
                                  _drawPoints.add(DrawPoint(
                                    offset: details.localPosition,
                                    color: _penColor,
                                    strokeWidth: _penWidth,
                                    isHighlighter: _drawingMode == DrawingMode.highlighter,
                                  ));
                                }
                              });
                            },
                      onPanUpdate: _drawingMode == DrawingMode.none
                          ? null
                          : (details) {
                              setState(() {
                                if (_drawingMode == DrawingMode.eraser) {
                                  _eraseNearbyPoints(details.localPosition);
                                } else {
                                  _drawPoints.add(DrawPoint(
                                    offset: details.localPosition,
                                    color: _penColor,
                                    strokeWidth: _penWidth,
                                    isHighlighter: _drawingMode == DrawingMode.highlighter,
                                  ));
                                }
                              });
                            },
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: _DrawingPainter(_drawPoints),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Center(
      child: Text('course.unable_load_pdf'.tr()),
    );
  }

  Widget _buildDrawingToolButton(
    dynamic icon,
    String label,
    DrawingMode mode,
    Color defaultColor,
  ) {
    final isSelected = _drawingMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => setState(() => _drawingMode = isSelected ? DrawingMode.none : mode),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? defaultColor.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? defaultColor : Colors.grey.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FaIcon(
                icon,
                size: 20,
                color: isSelected ? defaultColor : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? defaultColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _eraseNearbyPoints(Offset position) {
    final eraseRadius = _penWidth * 5;
    setState(() {
      _drawPoints.removeWhere((point) {
        return (point.offset - position).distance < eraseRadius;
      });
    });
  }
}

class _DrawingPainter extends CustomPainter {
  final List<DrawPoint> points;

  _DrawingPainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    for (int i = 0; i < points.length - 1; i++) {
      final point = points[i];
      final nextPoint = points[i + 1];

      // Skip if the points are too far apart (new stroke)
      if ((point.offset - nextPoint.offset).distance > 50) continue;

      final paint = Paint()
        ..color = point.isHighlighter
            ? point.color.withOpacity(0.3)
            : point.color
        ..strokeWidth = point.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(point.offset, nextPoint.offset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
