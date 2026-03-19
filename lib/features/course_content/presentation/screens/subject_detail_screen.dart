import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectTitle;
  final String subtitle;

  const SubjectDetailScreen({
    super.key,
    required this.subjectTitle,
    this.subtitle = 'Course Content',
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen>
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
      backgroundColor: const Color(0xFFFAFBFF),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _KeepAliveWrapper(child: _buildLecturesTab()),
                _KeepAliveWrapper(child: _buildLiveTab()),
                _KeepAliveWrapper(child: _buildFilesTab()),
                _KeepAliveWrapper(child: _buildExamsTab()),
                _KeepAliveWrapper(child: _buildCommunityTab()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5A75FF), Color(0xFF8E7CFF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
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
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subjectTitle,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeaderInfoCard(FontAwesomeIcons.play, '4 Lectures'),
                  _buildHeaderInfoCard(FontAwesomeIcons.fileLines, '4 Files'),
                  _buildHeaderInfoCard(FontAwesomeIcons.calendarCheck, '3 Exams'),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfoCard(dynamic icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          FaIcon(icon as FaIconData, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFF3F4F6), width: 1),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelColor: const Color(0xFF3451E5),
        unselectedLabelColor: const Color(0xFF6B7280),
        indicatorColor: const Color(0xFF3451E5),
        indicatorWeight: 2,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          _buildTabItem(FontAwesomeIcons.circlePlay, 'Lectures'),
          _buildTabItem(FontAwesomeIcons.video, 'Live'),
          _buildTabItem(FontAwesomeIcons.fileLines, 'Files'),
          _buildTabItem(FontAwesomeIcons.calendarCheck, 'Exams'),
          _buildTabItem(FontAwesomeIcons.calendarDays, 'Community'),
        ],
      ),
    );
  }

  Widget _buildTabItem(dynamic icon, String label) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon as FaIconData, size: 14),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildLecturesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildLectureCard(
          'Introduction to Financial Accounting',
          '45:30',
          '2 views left',
          'https://images.unsplash.com/photo-1554224155-1696413575b3?w=400',
          isCompleted: true,
        ),
        _buildLectureCard(
          'Accounting Concepts and Principles',
          '52:15',
          '1 view left',
          'https://images.unsplash.com/photo-1454165833767-027ffcb7141b?w=400',
          isCompleted: true,
        ),
        _buildLectureCard(
          'Recording Busine Transactions',
          '38:45',
          'Watch limit reached',
          'https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400',
          isWarning: true,
        ),
        _buildLectureCard(
          'Preparing Financial Statements',
          '41:20',
          '1 view left',
          'https://images.unsplash.com/photo-1554224154-26032ffc0d07?w=400',
        ),
      ],
    );
  }

  Widget _buildLectureCard(
    String title,
    String duration,
    String statusLabel,
    String imageUrl, {
    bool isCompleted = false,
    bool isWarning = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 100,
                  height: 75,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 75,
                      color: const Color(0xFFF3F4F6),
                      child: const Center(
                        child: Icon(Icons.image_not_supported, color: Color(0xFF9CA3AF), size: 24),
                      ),
                    );
                  },
                ),
              ),
              Positioned.fill(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Color(0xFF1F2937), size: 16),
                  ),
                ),
              ),
              if (isCompleted)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2DBC77),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 10),
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
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    FaIcon(FontAwesomeIcons.clock, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      duration,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isWarning ? const Color(0xFFFFF1F1) : const Color(0xFFF0F2FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          color: isWarning ? const Color(0xFFFF4B4B) : const Color(0xFF5A75FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
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
  }

  Widget _buildLiveTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildLiveCard(
          'Weekly Review Session',
          'Dr. Ahmed',
          'Today, 6:00 PM • 90 min',
          isLive: true,
        ),
        _buildLiveCard(
          'Q&A Session',
          'Dr. Ahmed',
          'Tomorrow, 4:00 PM • 60 min',
          isLive: true,
        ),
      ],
    );
  }

  Widget _buildLiveCard(String title, String instructor, String time, {required bool isLive}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFFFF4B4B)),
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
              const FaIcon(FontAwesomeIcons.towerBroadcast, color: Color(0xFFFF4B4B), size: 18),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 6),
          Text(
            instructor,
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(color: const Color(0xFF9CA3AF).withValues(alpha: 0.7), fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2DBC77),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text('JOIN LIVE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildFileCard('Chapter 1 Notes', '24 pages • 2.4 MB', hasDownload: false),
        _buildFileCard('Chapter 2 Summary', '18 pages • 1.8 MB', hasDownload: true),
        _buildFileCard('Practice Problems', '12 pages • 1.2 MB', hasDownload: false),
        _buildFileCard('Formula Sheet', '4 pages • 0.5 MB', hasDownload: true),
      ],
    );
  }

  Widget _buildFileCard(String title, String info, {required bool hasDownload}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F0),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(FontAwesomeIcons.fileLines, color: Color(0xFFFF4B4B), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                Text(info, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
              ],
            ),
          ),
          _buildFileActionButton(FontAwesomeIcons.eye),
          if (hasDownload) ...[
            const SizedBox(width: 10),
            _buildFileActionButton(FontAwesomeIcons.download),
          ],
        ],
      ),
    );
  }

  Widget _buildFileActionButton(dynamic icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: FaIcon(icon as FaIconData, color: const Color(0xFF4B5563), size: 16),
    );
  }

  Widget _buildExamsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildExamCard('Quiz 1', '15 Questions', '30 min', 'Available', const Color(0xFF263EE2), isAvailable: true),
        _buildExamCard('Midterm Exam', '30 Questions', '90 min', 'Upcoming', const Color(0xFF9CA3AF), isAvailable: false),
        _buildExamCard('Final Exam', '50 Questions', '120 min', 'Upcoming', const Color(0xFF9CA3AF), isAvailable: false),
      ],
    );
  }

  Widget _buildExamCard(String title, String questions, String time, String status, Color btnColor, {required bool isAvailable}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isAvailable ? const Color(0xFFE6F7F0) : const Color(0xFFFFF9F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: isAvailable ? const Color(0xFF27AE60) : const Color(0xFFF2994A),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          Row(
            children: [
              FaIcon(FontAwesomeIcons.users, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(questions, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(width: 20),
              FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: isAvailable ? () {} : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable ? const Color(0xFF263EE2) : const Color(0xFFC4C4C4),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFC4C4C4),
              disabledForegroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              isAvailable ? 'START EXAM' : 'COMING SOON',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Center(
          child: Column(
            children: [
              Text(
                'Community',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
              ),
              SizedBox(height: 8),
              Text(
                'Stay connected with course updates, links, and class discussions.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            _buildCommunityButton(FontAwesomeIcons.whatsapp, 'Join WhatsApp\nGroup', const Color(0xFF27AE60)),
            const SizedBox(width: 12),
            _buildCommunityButton(FontAwesomeIcons.paperPlane, 'Join Telegram\nChannel', const Color(0xFF5A75FF)),
            const SizedBox(width: 12),
            _buildCommunityButton(FontAwesomeIcons.globe, 'Our Course\nWebsite', const Color(0xFFFF4B4B)),
          ],
        ),
        const SizedBox(height: 32),
        _buildAnnouncementCard('Announcement', '10 min ago', 'Live revision moved to Thursday', 'The weekly revision session will be on Thursday at 8:00 PM instead of Wednesday. Please review Chapter 1 before joining.'),
        _buildAnnouncementCard('Exam update', '1 hour ago', 'Quiz 2 opens tomorrow', 'Quiz 2 will be available tomorrow at 6:00 PM. It focuses on accounting concepts and business transactions.'),
        _buildAnnouncementCard('Instruction', 'Yesterday', 'Important note for assignments', 'Upload your practice sheet before Sunday. Late submissions will not be reviewed during the next live session.'),
      ],
    );
  }

  Widget _buildCommunityButton(dynamic icon, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            FaIcon(icon as FaIconData, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementCard(String tag, String time, String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F2FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(color: Color(0xFF5A75FF), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              Text(time, style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 11)),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: const Color(0xFFF9FAFB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reply', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper> with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
