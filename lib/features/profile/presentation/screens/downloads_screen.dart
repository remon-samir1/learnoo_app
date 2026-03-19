import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildDownloadItem(
                  'Arrays and Lists',
                  'Data Structures',
                  '245 MB',
                  '52:15',
                  'https://images.unsplash.com/photo-1516116216624-53e697fedbea?w=200',
                  isVideo: true,
                ),
                const SizedBox(height: 16),
                _buildDownloadItem(
                  'Chapter 1 Notes',
                  'Data Structures',
                  '12 MB',
                  '24 pages',
                  null,
                  isVideo: false,
                ),
                const SizedBox(height: 16),
                _buildDownloadItem(
                  'Neural Networks',
                  'Machine Learning',
                  '382 MB',
                  '1:24:30',
                  'https://images.unsplash.com/photo-1501504905252-473c47e087f8?w=200',
                  isVideo: true,
                ),
                const SizedBox(height: 32),
                _buildDeleteAllButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A75FF), Color(0xFF8E7CFF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  const Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(right: 48),
                        child: Text(
                          'Downloads',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const FaIcon(FontAwesomeIcons.hardDrive, color: Colors.white, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'Storage Used',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13),
                          ),
                        ],
                      ),
                      const Text(
                        '639 MB',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 0.4,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadItem(
    String title,
    String subject,
    String size,
    String duration,
    String? imageUrl, {
    required bool isVideo,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 60,
            decoration: BoxDecoration(
              color: isVideo ? Colors.black12 : const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(10),
              image: imageUrl != null
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: Center(
              child: FaIcon(
                isVideo ? FontAwesomeIcons.video : FontAwesomeIcons.fileLines,
                color: isVideo ? Colors.white : const Color(0xFFFF4B4B),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937)),
                ),
                Text(
                  subject,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '$size  •  $duration',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const IconButton(
              onPressed: null,
              icon: Icon(Icons.delete_outline, color: Color(0xFFFF4B4B), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteAllButton() {
    return Container(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.delete_outline, size: 18),
        label: const Text('Delete All Downloads'),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFF4B4B),
          backgroundColor: const Color(0xFFFFF1F1),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }
}
