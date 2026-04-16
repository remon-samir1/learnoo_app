import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/lecture_repository.dart';
import '../../../exams/data/exam_repository.dart';
import '../../../exams/models/quiz_models.dart';
import '../../../exams/presentation/screens/quiz_screen.dart';
import 'lecture_detail_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final String courseId;
  final String title;
  final String thumbnail;
  final String price;
  final String description;

  const CourseDetailScreen({
    super.key,
    required this.courseId,
    required this.title,
    required this.thumbnail,
    required this.price,
    required this.description,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen>
    with SingleTickerProviderStateMixin {
  final _lectureRepository = LectureRepository();
  final _examRepository = ExamRepository();
  late TabController _tabController;

  bool _isLoadingLectures = true;
  bool _isLoadingExams = true;
  List<dynamic> _lectures = [];
  List<Quiz> _exams = [];
  List<bool> _isExpanded = [];
  String _qaFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadLectures(), _loadExams()]);
  }

  Future<void> _loadExams() async {
    setState(() => _isLoadingExams = true);
    try {
      final result = await _examRepository.getQuizzes();
      if (result['success'] && mounted) {
        final allExams = result['data'] as List<Quiz>;
        final courseIdInt = int.tryParse(widget.courseId) ?? -1;
        setState(() {
          _exams = allExams
              .where((exam) => exam.courseId == courseIdInt)
              .toList();
          _isLoadingExams = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingExams = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingExams = false);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLectures() async {
    if (widget.courseId.isEmpty) {
      setState(() => _isLoadingLectures = false);
      return;
    }

    setState(() => _isLoadingLectures = true);
    try {
      final courseId = int.tryParse(widget.courseId);
      final result = await _lectureRepository.getLectures(courseId: courseId);
      if (result['success'] && mounted) {
        final allLectures = result['data'] as List<dynamic>? ?? [];
        final filteredLectures = allLectures.where((lecture) {
          final attributes = lecture['attributes'] ?? {};
          final lectureCourseId = attributes['course_id']?.toString();
          return lectureCourseId == widget.courseId;
        }).toList();

        setState(() {
          _lectures = filteredLectures;
          _isExpanded = List<bool>.filled(filteredLectures.length, false);
          _isLoadingLectures = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingLectures = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLectures = false);
      }
    }
  }

  void _navigateToLecture(dynamic lecture, dynamic chapter) {
    final lectureId = lecture['id']?.toString() ?? '';
    final lectureTitle =
        lecture['attributes']?['title']?.toString() ?? 'course.untitled_lecture'.tr();
    final chapterId = chapter['id']?.toString() ?? '';
    final chapterTitle =
        chapter['attributes']?['title']?.toString() ?? 'course.untitled_chapter'.tr();
    // course_id comes directly from the chapter attributes in the chapters API response
    final courseId =
        chapter['attributes']?['course_id']?.toString() ?? widget.courseId;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LectureDetailScreen(
          lectureId: lectureId,
          lectureTitle: lectureTitle,
          chapterId: chapterId,
          chapterTitle: chapterTitle,
          courseId: courseId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          // _buildProgressSection(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoadingLectures
                    ? _buildLecturesSkeleton()
                    : _buildLecturesTab(),
                _buildExamsTab(),
                // _buildQATab(),
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
        Container(
          height: 320,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(
                widget.thumbnail.isNotEmpty
                    ? widget.thumbnail
                    : 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=800',
              ),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Container(
          height: 320,
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
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description.isNotEmpty
                      ? widget.description.split('\n').first
                      : 'course.course'.tr(),
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'course.course_progress'.tr(),
                style: const TextStyle(color: Colors.grey, fontSize: 13),
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
        indicatorPadding: EdgeInsets.zero,
        labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        tabs: [
          Tab(text: 'course.lectures_and_pdf'.tr()),
          Tab(text: 'course.exams'.tr()),
          // Tab(text: 'Q&A'),
        ],
      ),
    );
  }

  Widget _buildLecturesSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F1F1)),
            ),
            child: Column(
              children: [
                ListTile(
                  title: Container(height: 16, width: 200, color: Colors.white),
                  subtitle: Container(
                    height: 12,
                    width: 100,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLecturesTab() {
    if (_lectures.isEmpty) {
      return Center(
        child: Text(
          'course.no_lectures_available'.tr(),
          style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: _lectures.asMap().entries.map((entry) {
        final index = entry.key;
        final lecture = entry.value;
        final attributes = lecture['attributes'] ?? {};
        final lectureTitle =
            attributes['title']?.toString() ?? 'course.untitled_lecture'.tr();

        return Column(
          children: [
            _buildChapterItem(index, lectureTitle, lecture),
            if (index < _lectures.length - 1) const SizedBox(height: 20),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildChapterItem(int index, String title, dynamic lecture) {
    bool isExpanded = _isExpanded.length > index ? _isExpanded[index] : false;
    final attributes = lecture['attributes'] ?? {};
    final chapters = attributes['chapters'] as List<dynamic>? ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F1)),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: const Color(0xFF5A75FF).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent lecture header with tree indicator
          InkWell(
            onTap: () {
              setState(() {
                if (_isExpanded.length > index) {
                  _isExpanded[index] = !isExpanded;
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Tree structure indicator
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isExpanded 
                          ? const Color(0xFF5A75FF).withValues(alpha: 0.1)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isExpanded ? Icons.folder_open : Icons.folder,
                      color: isExpanded ? const Color(0xFF5A75FF) : Colors.grey,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 15,
                            color: isExpanded ? const Color(0xFF5A75FF) : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${chapters.length} ${chapters.length == 1 ? 'course.chapter'.tr() : 'course.chapters'.tr()}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  // Expand/collapse indicator
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isExpanded 
                            ? const Color(0xFF5A75FF).withValues(alpha: 0.1)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: isExpanded ? const Color(0xFF5A75FF) : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Nested chapters with visual tree indentation
          if (isExpanded && chapters.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFBFF),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  ...chapters.asMap().entries.expand((entry) {
                    final chapterIndex = entry.key;
                    final chapter = entry.value;
                    final chapterAttrs = chapter['attributes'] ?? {};
                    final chapterTitle =
                        chapterAttrs['title']?.toString() ?? 'course.untitled_chapter'.tr();
                    final duration = chapterAttrs['duration']?.toString() ?? '--:--';
                    final thumbnail = chapterAttrs['thumbnail']?.toString() ?? '';
                    final isLocked = chapterAttrs['is_locked'] as bool? ?? false;
                    final isFreePreview =
                        chapterAttrs['is_free_preview'] as bool? ?? false;
                    final isLastItem = chapterIndex == chapters.length - 1;

                    final widgets = <Widget>[
                      _buildNestedChapterItem(
                        chapterTitle,
                        duration,
                        thumbnail,
                        !isLocked,
                        index: chapterIndex,
                        totalCount: chapters.length,
                        onTap: () => _navigateToLecture(lecture, chapter),
                        isFreePreview: isFreePreview,
                        isLocked: isLocked,
                        isLastItem: isLastItem,
                      ),
                    ];

                    return widgets;
                  }).toList(),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // New nested chapter item with tree visualization
  Widget _buildNestedChapterItem(
    String title,
    String duration,
    String imageUrl,
    bool isCompleted, {
    required VoidCallback onTap,
    bool isFreePreview = false,
    bool isLocked = false,
    required int index,
    required int totalCount,
    required bool isLastItem,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Tree connector lines
            SizedBox(
              width: 32,
              height: 60,
              child: Stack(
                children: [
                  // Vertical line from parent
                  Positioned(
                    left: 8,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 2,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  // Horizontal connector
                  Positioned(
                    left: 8,
                    top: 20,
                    child: Container(
                      width: 16,
                      height: 2,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
                  // Last item corner or continue line
                  if (!isLastItem)
                    Positioned(
                      left: 8,
                      top: 22,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),
                  // Node indicator
                  Positioned(
                    left: 4,
                    top: 16,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.grey : const Color(0xFF5A75FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Content
            Expanded(
              child: _buildLectureListItem(
                title,
                duration,
                imageUrl,
                isCompleted,
                onTap: onTap,
                isFreePreview: isFreePreview,
                isLocked: isLocked,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLectureListItem(
    String title,
    String duration,
    String imageUrl,
    bool isCompleted, {
    VoidCallback? onTap,
    bool isFreePreview = false,
    bool isLocked = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          width: 80,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                          ),
                        ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isLocked ? Icons.lock : Icons.play_arrow,
                        color: Colors.black,
                        size: 14,
                      ),
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
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 8,
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
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (isFreePreview)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F9F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'course.free_preview'.tr(),
                        style: const TextStyle(
                          color: Color(0xFF2DBC77),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isLocked ? 'course.locked'.tr() : 'course.watch'.tr(),
                        style: TextStyle(
                          color: isLocked
                              ? Colors.grey
                              : const Color(0xFF3451E5),
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
      ),
    );
  }

  Widget _buildExamsTab() {
    if (_isLoadingExams) {
      return _buildExamsSkeleton();
    }

    if (_exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'course.no_exams_available'.tr(),
            style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        return _buildExamCard(exam);
      },
    );
  }

  Widget _buildExamsSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 18, width: 200, color: Colors.white),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(height: 14, width: 80, color: Colors.white),
                    const SizedBox(width: 24),
                    Container(height: 14, width: 80, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 54,
                  width: double.infinity,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamCard(Quiz exam) {
    final isAvailable = exam.isAvailable;
    final status = isAvailable
        ? 'course.available'.tr()
        : (exam.isExpired ? 'course.expired'.tr() : 'course.upcoming'.tr());
    final statusColor = isAvailable
        ? const Color(0xFF27AE60)
        : (exam.isExpired ? Colors.red : const Color(0xFFF2994A));
    final statusBgColor = isAvailable
        ? const Color(0xFFE6F7F0)
        : (exam.isExpired ? const Color(0xFFFFF0F0) : const Color(0xFFFFF9F0));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            exam.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(
                '${exam.duration} ${'course.minutes'.tr()}',
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
              const SizedBox(width: 24),
              FaIcon(
                FontAwesomeIcons.circleInfo,
                size: 14,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 8),
              Text(
                exam.type.toUpperCase(),
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isAvailable
                ? () async {
                    final result = await _examRepository.startQuizAttempt(
                      exam.quizId,
                    );
                    if (result['success'] && mounted) {
                      final attempt = result['data'] as QuizAttempt;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuizScreen(quiz: exam, attempt: attempt),
                        ),
                      );
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            result['message'] ?? 'course.failed_start_exam'.tr(),
                          ),
                        ),
                      );
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAvailable
                  ? const Color(0xFF263EE2)
                  : const Color(0xFFC4C4C4),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFC4C4C4),
              disabledForegroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              isAvailable
                  ? 'course.start_exam'.tr()
                  : (exam.isExpired ? 'course.status_expired'.tr() : 'course.coming_soon'.tr()),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                    'text':
                        'Great question! Merge sort always has O(n log n) complexity, while quick sort has average O(n log n) but worst case O(n²).',
                  },
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFF0F2FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected
                            ? const Color(0xFF3451E5)
                            : Colors.grey,
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
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
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(avatarUrl),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 52),
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800], fontSize: 13),
            ),
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
                            child: Text(
                              'D',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              response['name']!,
                              style: const TextStyle(
                                color: Color(0xFF263EE2),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF263EE2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                response['role']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          response['time']!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      response['text']!,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
        child: Row(
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
                    hintText: _qaFilter == 'Comments'
                        ? 'Write a comment...'
                        : 'Type here...',
                    hintStyle: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildCircleActionButton(Icons.mic_none, const Color(0xFF263EE2)),
            const SizedBox(width: 12),
            _buildCircleActionButton(
              Icons.send_rounded,
              const Color(0xFF263EE2),
            ),
          ],
        ),
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
