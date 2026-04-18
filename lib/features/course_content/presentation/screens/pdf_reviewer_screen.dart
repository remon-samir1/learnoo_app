import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as pdf_lib;

class PdfReviewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PdfReviewerScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  @override
  State<PdfReviewerScreen> createState() => _PdfReviewerScreenState();
}

enum AnnotationMode { none, highlight, underline, squiggly, strikethrough, ink }

class _PdfReviewerScreenState extends State<PdfReviewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoading = false;
  double _downloadProgress = 0;

  // Annotation state
  AnnotationMode _currentAnnotationMode = AnnotationMode.none;
  Color _annotationColor = Colors.yellow;
  bool _showAnnotationToolbar = false;

  // Available annotation colors
  final List<Color> _annotationColors = [
    Colors.yellow,
    Colors.green,
    Colors.red,
    Colors.blue,
    Colors.purple,
    Colors.orange,
  ];

  Future<void> _downloadPdf() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Storage permission denied')),
              );
            }
            return;
          }
        }
      }

      setState(() {
        _isLoading = true;
        _downloadProgress = 0;
      });

      final directory = Platform.isAndroid
          ? await getExternalStorageDirectory()
          : await getApplicationDocumentsDirectory();
      
      final fileName = '${widget.title.replaceAll(' ', '_')}.pdf';
      final filePath = '${directory!.path}/$fileName';

      await Dio().download(
        widget.pdfUrl,
        filePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = count / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Downloaded to $filePath')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error downloading: $e')),
        );
      }
    }
  }

  void _setAnnotationMode(AnnotationMode mode) {
    setState(() {
      _currentAnnotationMode = mode;
    });
  }

  void _setAnnotationColor(Color color) {
    setState(() {
      _annotationColor = color;
    });
  }

  AnnotationMode _getAnnotationModeFromSelection() {
    switch (_currentAnnotationMode) {
      case AnnotationMode.highlight:
        return AnnotationMode.highlight;
      case AnnotationMode.underline:
        return AnnotationMode.underline;
      case AnnotationMode.squiggly:
        return AnnotationMode.squiggly;
      case AnnotationMode.strikethrough:
        return AnnotationMode.strikethrough;
      default:
        return AnnotationMode.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: FaIcon(
              _showAnnotationToolbar ? FontAwesomeIcons.penToSquare : FontAwesomeIcons.highlighter,
              size: 20,
              color: _showAnnotationToolbar ? Colors.orange : null,
            ),
            onPressed: () {
              setState(() {
                _showAnnotationToolbar = !_showAnnotationToolbar;
                if (!_showAnnotationToolbar) {
                  _currentAnnotationMode = AnnotationMode.none;
                }
              });
            },
            tooltip: 'pdf.annotation_tools'.tr(),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.download, size: 20),
            onPressed: _isLoading ? null : _downloadPdf,
          ),
        ],
      ),
      body: Column(
        children: [
          // Annotation Toolbar
          if (_showAnnotationToolbar)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
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
                  // Annotation Type Selection
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        _buildAnnotationModeButton(
                          FontAwesomeIcons.highlighter,
                          'pdf.highlight'.tr(),
                          AnnotationMode.highlight,
                          Colors.yellow,
                        ),
                        _buildAnnotationModeButton(
                          FontAwesomeIcons.underline,
                          'pdf.underline'.tr(),
                          AnnotationMode.underline,
                          Colors.blue,
                        ),
                        _buildAnnotationModeButton(
                          FontAwesomeIcons.strikethrough,
                          'pdf.strikethrough'.tr(),
                          AnnotationMode.strikethrough,
                          Colors.red,
                        ),
                        _buildAnnotationModeButton(
                          FontAwesomeIcons.pen,
                          'pdf.ink'.tr(),
                          AnnotationMode.ink,
                          Colors.purple,
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Color Selection
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: _annotationColors.map((color) {
                        final isSelected = _annotationColor == color;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: GestureDetector(
                            onTap: () => _setAnnotationColor(color),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, color: Colors.black, size: 18)
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          // PDF Viewer
          Expanded(
            child: Stack(
              children: [
                SfPdfViewer.network(
                  widget.pdfUrl,
                  controller: _pdfViewerController,
                  key: _pdfViewerKey,
                  enableTextSelection: true,
                  enableDocumentLinkAnnotation: true,
                  enableHyperlinkNavigation: true,
                  onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
                    if (details.selectedText != null && _currentAnnotationMode != AnnotationMode.none) {
                      // Apply annotation when text is selected
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('pdf.text_selected'.tr(args: [details.selectedText!.substring(0, details.selectedText!.length > 20 ? 20 : details.selectedText!.length)])),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                if (_isLoading)
                  Container(
                    color: Colors.black26,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'course.downloading'.tr(args: [(_downloadProgress * 100).toStringAsFixed(0)]),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnotationModeButton(
    FaIconData icon,
    String label,
    AnnotationMode mode,
    Color defaultColor,
  ) {
    final isSelected = _currentAnnotationMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: () => _setAnnotationMode(isSelected ? AnnotationMode.none : mode),
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
}
