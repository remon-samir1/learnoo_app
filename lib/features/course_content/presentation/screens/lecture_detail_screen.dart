import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LectureDetailScreen extends StatelessWidget {
  final String title;
  final String subtitle;

  const LectureDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVideoHeader(context),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainInfo(),
                  const SizedBox(height: 24),
                  _buildAccessCards(),
                  const SizedBox(height: 32),
                  _buildDescription(),
                  const SizedBox(height: 32),
                  _buildAttachments(),
                  const SizedBox(height: 32),
                  _buildLinkedExams(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoHeader(BuildContext context) {
    return Stack(
      children: [
        // Video Preview Image
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=800',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Darkened Overlay for Controls
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
        // Top Controls: Back and Share
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                _buildCircleControlButton(
                  icon: FontAwesomeIcons.arrowLeft,
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                _buildCircleControlButton(
                  icon: FontAwesomeIcons.shareNodes,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
        // Center Play Button
        Positioned.fill(
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.play,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        // Bottom Controls
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            children: [
              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Stack(
                        children: [
                          Container(
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Container(
                            height: 3,
                            width: 80, // Simulation of progress
                            decoration: BoxDecoration(
                              color: const Color(0xFF3451E5),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Time and Control Icons
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.play, color: Colors.white, size: 14),
                    const SizedBox(width: 12),
                    const Text(
                      '2:15 / 52:10',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    const Spacer(),
                    const FaIcon(FontAwesomeIcons.volumeHigh, color: Colors.white, size: 14),
                    const SizedBox(width: 16),
                    const FaIcon(FontAwesomeIcons.gear, color: Colors.white, size: 14),
                    const SizedBox(width: 16),
                    const FaIcon(FontAwesomeIcons.magnifyingGlassPlus, color: Colors.white, size: 14),
                    const SizedBox(width: 16),
                    const FaIcon(FontAwesomeIcons.expand, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircleControlButton({required dynamic icon, required VoidCallback onPressed}) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: FaIcon(icon as FaIconData, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildMainInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            '3/13/2026, 11:13:37 PM',
            style: TextStyle(
              color: Color(0xFF3451E5),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAccessCards() {
    return Column(
      children: [
        // Watch Access Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Watch Access',
                style: TextStyle(color: Color(0xFF3451E5), fontSize: 13, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                '2 Remaining Views',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937)),
              ),
              SizedBox(height: 8),
              Text(
                'You can watch this lecture 2 more times before access is locked.',
                style: TextStyle(color: Color(0xFF3451E5), fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Re-purchase Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F1F1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Need more access?',
                style: TextStyle(color: Color(0xFFFF4B4B), fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Buy this lecture again to unlock more views and continue learning.',
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF07171),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Re-purchase Lecture', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        SizedBox(height: 12),
        Text(
          'In this lecture, we\'ll dive deep into arrays and lists, covering their implementation, time complexity, and common operations. You\'ll learn when to use each data structure and understand their trade-offs.',
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _buildAttachments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Attachments',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 16),
        _buildAttachmentItem('Lecture Slides.pdf', '2.4 MB'),
        const SizedBox(height: 12),
        _buildAttachmentItem('Code Examples.zip', '1.8 MB'),
      ],
    );
  }

  Widget _buildAttachmentItem(String name, String size) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEDEDFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(FontAwesomeIcons.paperclip, color: Color(0xFF3451E5), size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(size, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const FaIcon(FontAwesomeIcons.download, color: Colors.grey, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedExams() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Linked Exams',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 8),
        const Text(
          'Take the quiz related to this lecture after finishing the video.',
          style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F9F0).withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2DBC77).withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Quick Quiz 01', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2DBC77),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Available Now',
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.users, size: 12, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('10 Questions', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(width: 16),
                  const FaIcon(FontAwesomeIcons.clock, size: 12, color: Colors.grey),
                  const SizedBox(width: 6),
                  const Text('8 min', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.grey[200]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 44),
                      ),
                      child: const Text('VIEW DETAILS', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2DBC77),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(0, 44),
                        elevation: 0,
                      ),
                      child: const Text('START QUIZ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
