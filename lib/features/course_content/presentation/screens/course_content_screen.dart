import 'package:flutter/material.dart';
import '../widgets/course_header.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
          CourseHeader(
            title: widget.courseTitle,
            subtitle: widget.instructorName,
            chips: [
              CourseChipData(
                icon: Icons.play_circle_outline,
                label: '4 Lectures',
              ),
              CourseChipData(
                icon: Icons.description_outlined,
                label: '4 Files',
              ),
              CourseChipData(
                icon: Icons.calendar_today_outlined,
                label: '3 Exams',
              ),
            ],
          ),
          const SizedBox(height: 8),
          PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Material(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF3451E5),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF3451E5),
                indicatorWeight: 3,
                labelPadding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow_outlined, size: 18),
                        SizedBox(width: 4),
                        Text('Lectures'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam_outlined, size: 18),
                        SizedBox(width: 4),
                        Text('Live'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.description_outlined, size: 18),
                        SizedBox(width: 4),
                        Text('Files'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 18),
                        SizedBox(width: 4),
                        Text('Exams'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 18),
                        SizedBox(width: 4),
                        Text('Community'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F1)),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLecturesTab(),
                _buildLiveTab(),
                _buildFilesTab(),
                _buildExamsTab(),
                _buildCommunityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLecturesTab() {
    final lectures = [
      {
        'title': 'Introduction to Financial Accounting',
        'duration': '45:30',
        'viewsLeft': '2 views left',
        'isCompleted': true,
        'image':
            'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400',
      },
      {
        'title': 'Accounting Concepts and Principles',
        'duration': '52:15',
        'viewsLeft': '1 view left',
        'isCompleted': true,
        'image':
            'https://images.unsplash.com/photo-1454165833767-027ffcb7141b?w=400',
      },
      {
        'title': 'Recording Business Transactions',
        'duration': '38:45',
        'viewsLeft': 'Watch limit reached',
        'isCompleted': false,
        'image':
            'https://images.unsplash.com/photo-1507679799987-c7377f54b45d?w=400',
      },
      {
        'title': 'Preparing Financial Statements',
        'duration': '41:20',
        'viewsLeft': '1 view left',
        'isCompleted': false,
        'image':
            'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lectures.length,
      itemBuilder: (context, index) {
        final lecture = lectures[index];
        final bool isLimitReached =
            lecture['viewsLeft'] == 'Watch limit reached';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
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
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      lecture['image'] as String,
                      width: 100,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF3451E5),
                      size: 20,
                    ),
                  ),
                  if (lecture['isCompleted'] as bool)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2DBC77),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lecture['title'] as String,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          lecture['duration'] as String,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isLimitReached
                                ? const Color(0xFFFFF0F0)
                                : const Color(0xFFF0F2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            lecture['viewsLeft'] as String,
                            style: TextStyle(
                              color: isLimitReached
                                  ? const Color(0xFFFF4B4B)
                                  : const Color(0xFF3451E5),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveTab() {
    final liveSessions = [
      {
        'title': 'Weekly Review Session',
        'instructor': 'Dr. Ahmed',
        'time': 'Today, 6:00 PM • 90 min',
        'status': 'LIVE',
      },
      {
        'title': 'Q&A Session',
        'instructor': 'Dr. Ahmed',
        'time': 'Tomorrow, 4:00 PM • 60 min',
        'status': 'LIVE',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: liveSessions.length,
      itemBuilder: (context, index) {
        final session = liveSessions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFFFF4B4B),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Color(0xFFFF4B4B),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.sensors, color: Color(0xFF3451E5), size: 24),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                session['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                session['instructor'] as String,
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                session['time'] as String,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DBC77),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'JOIN LIVE',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilesTab() {
    final files = [
      {
        'title': 'Chapter 1 Notes',
        'pages': '24 pages',
        'size': '2.4 MB',
        'canDownload': false,
      },
      {
        'title': 'Chapter 2 Summary',
        'pages': '18 pages',
        'size': '1.8 MB',
        'canDownload': true,
      },
      {
        'title': 'Practice Problems',
        'pages': '12 pages',
        'size': '1.2 MB',
        'canDownload': false,
      },
      {
        'title': 'Formula Sheet',
        'pages': '4 pages',
        'size': '0.5 MB',
        'canDownload': true,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F1F1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFFFF4B4B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${file['pages']} • ${file['size']}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.visibility_outlined,
                    color: Color(0xFF3451E5),
                    size: 20,
                  ),
                  onPressed: () {},
                ),
              ),
              if (file['canDownload'] as bool) ...[
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F2FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.download_outlined,
                      color: Color(0xFF3451E5),
                      size: 20,
                    ),
                    onPressed: () {},
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildExamsTab() {
    final exams = [
      {
        'title': 'Quiz 1',
        'questions': '15 Questions',
        'duration': '30 min',
        'status': 'Available',
        'statusColor': const Color(0xFF2DBC77),
        'statusBg': const Color(0xFFF0FFF6),
        'buttonText': 'START EXAM',
        'buttonColor': const Color(0xFF3451E5),
      },
      {
        'title': 'Midterm Exam',
        'questions': '30 Questions',
        'duration': '90 min',
        'status': 'Upcoming',
        'statusColor': const Color(0xFFF2994A),
        'statusBg': const Color(0xFFFFF9F0),
        'buttonText': 'COMING SOON',
        'buttonColor': Colors.grey[400]!,
      },
      {
        'title': 'Final Exam',
        'questions': '50 Questions',
        'duration': '120 min',
        'status': 'Upcoming',
        'statusColor': const Color(0xFFF2994A),
        'statusBg': const Color(0xFFFFF9F0),
        'buttonText': 'COMING SOON',
        'buttonColor': Colors.grey[400]!,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exams.length,
      itemBuilder: (context, index) {
        final exam = exams[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F1F1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: exam['statusBg'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  exam['status'] as String,
                  style: TextStyle(
                    color: exam['statusColor'] as Color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                exam['title'] as String,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 16,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    exam['questions'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    exam['duration'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: exam['buttonText'] == 'START EXAM' ? () {} : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: exam['buttonColor'] as Color,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: exam['buttonColor'] as Color,
                  disabledForegroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  exam['buttonText'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommunityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F1F1)),
            ),
            child: Column(
              children: [
                const Text(
                  'Community',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Stay connected with course updates, links, and class discussions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildCommunityLink(
                      'Join WhatsApp Group',
                      const Color(0xFF25D366),
                      const Color(0xFFE8F9F0),
                      Icons.chat_bubble_outline,
                    ),
                    const SizedBox(width: 12),
                    _buildCommunityLink(
                      'Join Telegram Channel',
                      const Color(0xFF0088CC),
                      const Color(0xFFE5F3FA),
                      Icons.send,
                    ),
                    const SizedBox(width: 12),
                    _buildCommunityLink(
                      'Our Course Website',
                      const Color(0xFFFF4B4B),
                      const Color(0xFFFFF0F0),
                      Icons.language,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildPostItem(
            'Announcement',
            '10 min ago',
            'Live revision moved to Thursday',
            'The weekly revision session will be on Thursday at 8:00 PM instead of Wednesday. Please review Chapter 1 before joining.',
            const Color(0xFFF0F2FF),
            const Color(0xFF3451E5),
          ),
          const SizedBox(height: 16),
          _buildPostItem(
            'Exam update',
            '1 hour ago',
            'Quiz 2 opens tomorrow',
            'Quiz 2 will be available tomorrow at 6:00 PM. It focuses on accounting concepts and business transactions.',
            const Color(0xFFF0F2FF),
            const Color(0xFF3451E5),
          ),
          const SizedBox(height: 16),
          _buildPostItem(
            'Instruction',
            'Yesterday',
            'Important note for assignments',
            'Upload your practice sheet before Sunday. Late submissions will not be reviewed during the next live session.',
            const Color(0xFFF0F2FF),
            const Color(0xFF3451E5),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityLink(
    String label,
    Color color,
    Color bg,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostItem(
    String tag,
    String time,
    String title,
    String body,
    Color tagBg,
    Color tagColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    color: tagColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                time,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[200]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            ),
            child: const Text(
              'Reply',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
