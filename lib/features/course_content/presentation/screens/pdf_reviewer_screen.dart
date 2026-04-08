import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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

class _PdfReviewerScreenState extends State<PdfReviewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  bool _isLoading = false;
  double _downloadProgress = 0;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.download, size: 20),
            onPressed: _isLoading ? null : _downloadPdf,
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.highlighter, size: 20),
            onPressed: () {
              // Note: Basic SfPdfViewer supports text selection and copy.
              // For full ink annotation, syncfusion_flutter_pdf is used for backend,
              // but UI for drawing requires SfPdfViewer.annotationSettings or custom implementation.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Long press text to highlight or add notes')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SfPdfViewer.network(
            widget.pdfUrl,
            controller: _pdfViewerController,
            key: _pdfViewerKey,
            enableTextSelection: true,
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              if (details.selectedText != null) {
                // Future implementation: Show annotation toolbar
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
                      'Downloading... ${( _downloadProgress * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
