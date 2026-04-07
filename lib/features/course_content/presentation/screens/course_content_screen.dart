import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CourseContentScreen extends StatefulWidget {
  final String courseTitle;
  final String instructorName;

  const CourseContentScreen({
    super.key,
    required this.courseTitle,
    required this.instructorName,
  });

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<bool> _isExpanded = [true, false]; // For chapters
  String _qaFilter = 'All'; // Sub-filter for Q&A tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          _buildProgressSection(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLecturesTab(),
                _buildExamsTab(),
                _buildQATab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        // Background Image
        Container(
          // height: 240,
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
        // Darkened Overlay with Gradient
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.7),
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.6),
              ],
            ),
          ),
        ),
        // Content
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(height: 20),
                // Title
                Text(
                  widget.courseTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.instructorName,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Course Progress',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const Text(
                '65%',
                style: TextStyle(
                  color: Color(0xFF3451E5),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.65,
              backgroundColor: Color(0xFFF1F1F1),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3451E5)),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F1F1))),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF3451E5),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF3451E5),
        indicatorWeight: 3,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
        tabs: const [
          Tab(text: 'Lectures & PDF'),
          Tab(text: 'Exams'),
          Tab(text: 'Q&A'),
        ],
      ),
    );
  }

  Widget _buildLecturesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildChapterItem(0, 'Chapter 1: Introduction'),
        const SizedBox(height: 20),
        _buildChapterItem(1, 'Chapter 2: Stack & Queue'),
      ],
    );
  }

  Widget _buildChapterItem(int index, String title) {
    bool isExpanded = _isExpanded[index];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Column(
        children: [
          ListTile(
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            trailing: Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
            onTap: () => setState(() => _isExpanded[index] = !isExpanded),
          ),
          if (isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFF1F1F1)),
            _buildLectureListItem(
              'What is Financial Accounting?',
              '45:30',
              'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400',
              true,
            ),
            const Divider(height: 1, color: Color(0xFFF1F1F1)),
            _buildLectureListItem(
              'Accounting Concepts & Principles',
              '52:15',
              'https://images.unsplash.com/photo-1454165833767-027ffcb7141b?w=400',
              true,
            ),
            const Divider(height: 1, color: Color(0xFFF1F1F1)),
            _buildPDFListItem('Chapter 1 Notes', '24 pages'),
          ],
        ],
      ),
    );
  }

  Widget _buildLectureListItem(String title, String duration, String imageUrl, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, width: 80, height: 60, fit: BoxFit.cover),
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.black, size: 14),
                  ),
                ),
              ),
              if (isCompleted)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2DBC77),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Watch',
                    style: TextStyle(
                      color: Color(0xFF3451E5),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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

  Widget _buildPDFListItem(String title, String pages) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.insert_drive_file, color: Color(0xFFFF4B4B), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(pages, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Row(
            children: [
              _buildSmallIconButton(FontAwesomeIcons.eye),
              const SizedBox(width: 8),
              _buildSmallIconButton(FontAwesomeIcons.download),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallIconButton(dynamic icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: FaIcon(icon as FaIconData, size: 14, color: Colors.grey[600]),
    );
  }

  Widget _buildExamsTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
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
                  'Midterm Exam - Data Structures',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text('30 Questions', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                    const SizedBox(width: 24),
                    Text('90 Minutes', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF263EE2),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('START EXAM', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQATab() {
    return Column(
      children: [
        _buildQASubFilters(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              if (_qaFilter == 'All' || _qaFilter == 'Ask Question') ...[
                _buildQuestionItem(
                  'Ahmed Hassan',
                  '2 hours ago',
                  'Can you explain the difference between merge sort and quick sort?',
                  'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
                  response: {
                    'name': 'Dr. Sarah Ahmed',
                    'role': 'Instructor',
                    'time': '1 hour ago',
                    'text': 'Great question! Merge sort always has O(n log n) complexity, while quick sort has average O(n log n) but worst case O(n²). Merge sort is stable, quick sort is not.',
                  },
                ),
                _buildQuestionItem(
                  'Fatima Ali',
                  '5 hours ago',
                  'What\'s the best way to implement a priority queue?',
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100',
                  isWaiting: true,
                ),
              ],
              if (_qaFilter == 'All' || _qaFilter == 'Voice') ...[
                _buildVoiceItem(
                  'Ahmed',
                  '18:35',
                  'Short voice question linked to 12:48 in the live explanation.',
                  '12:48',
                  '00:09 / 00:21',
                  0.4,
                ),
                _buildVoiceItem(
                  'Beatrice',
                  '19:00',
                  'Short voice question linked to 12:48 in the live explanation.',
                  '12:48',
                  '00:12 / 00:25',
                  0.5,
                  avatarLabel: 'B',
                ),
              ],
              if (_qaFilter == 'All' || _qaFilter == 'Comments') ...[
                _buildCommentItem(
                  'Ahmed',
                  '18:35',
                  'Great explanation! The merge sort example is much clearer now.',
                  '4:45',
                  avatarLabel: 'A',
                ),
                _buildCommentItem(
                  'Fatima',
                  '18:36',
                  'Can you repeat the last part?',
                  '2:30',
                  avatarLabel: 'F',
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
        if (_qaFilter == 'Comments' || _qaFilter == 'Voice') _buildTimestampLinkUI(),
        _buildQABottomBar(),
      ],
    );
  }

  Widget _buildQASubFilters() {
    final filters = ['All', 'Ask Question', 'Comments', 'Voice'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: filters.map((filter) {
              bool isSelected = _qaFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () => setState(() => _qaFilter = filter),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0F2FF) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? const Color(0xFF3451E5) : Colors.grey,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionItem(
    String name,
    String time,
    String text,
    String avatarUrl, {
    Map<String, String>? response,
    bool isWaiting = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(text, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
          ),
          if (response != null) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 40),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Color(0xFF263EE2),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child:
                                Text('D', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(response['name']!,
                                style: const TextStyle(color: Color(0xFF263EE2), fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF263EE2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(response['role']!,
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(response['time']!, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      response['text']!,
                      style: TextStyle(color: Colors.grey[800], fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (isWaiting) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 52),
              child: Row(
                children: [
                  const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Waiting for instructor response...',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVoiceItem(String name, String time, String text, String timestamp, String duration, double progress,
      {String? avatarLabel}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(avatarLabel ?? name[0],
                      style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 8),
              Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                children: [
                  TextSpan(text: text.replaceAll(timestamp, '')),
                  TextSpan(
                      text: timestamp,
                      style: const TextStyle(color: Color(0xFF3451E5), fontWeight: FontWeight.bold)),
                  const TextSpan(text: ' in the live explanation.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 44),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F8FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_arrow_rounded, color: Color(0xFF263EE2)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF263EE2)),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(duration, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(String name, String time, String text, String timestamp, {String? avatarLabel}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(avatarLabel ?? name[0],
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    children: [
                      TextSpan(
                          text: '$timestamp ',
                          style: const TextStyle(color: Color(0xFF3451E5), fontWeight: FontWeight.bold)),
                      TextSpan(text: text),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampLinkUI() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Linked timestamp', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text('18:35', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            ],
          ),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFF1F1F1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Jump to moment',
                style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQABottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F1F1))),
      ),
      child: SafeArea(
        top: false,
        child: _qaFilter == 'Voice' ? _buildVoiceBottomBar() : _buildMessageBottomBar(),
      ),
    );
  }

  Widget _buildMessageBottomBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F8FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: _qaFilter == 'Comments' ? 'Write a comment...' : 'Type here...',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildCircleActionButton(Icons.mic_none, const Color(0xFF263EE2)),
        const SizedBox(width: 12),
        _buildCircleActionButton(Icons.send_rounded, const Color(0xFF263EE2)),
      ],
    );
  }

  Widget _buildVoiceBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_arrow_rounded, color: Color(0xFF263EE2)),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: const LinearProgressIndicator(
                value: 0.6,
                backgroundColor: Colors.white,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF263EE2)),
                minHeight: 4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text('00:18', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(width: 16),
          const Icon(Icons.delete_outline, color: Color(0xFFFF4B4B), size: 20),
          const SizedBox(width: 16),
          _buildCircleActionButton(Icons.mic, const Color(0xFF263EE2)),
          const SizedBox(width: 16),
          _buildCircleActionButton(Icons.send_rounded, const Color(0xFF263EE2)),
        ],
      ),
    );
  }

  Widget _buildCircleActionButton(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}
