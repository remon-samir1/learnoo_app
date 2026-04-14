import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../features/exams/data/exam_repository.dart';
import '../../../../features/exams/models/quiz_models.dart';
import '../../../../features/exams/presentation/screens/quiz_screen.dart';

class CourseContentScreen extends StatefulWidget {
  final String courseTitle;
  final String instructorName;
  final int courseId;

  const CourseContentScreen({
    super.key,
    required this.courseTitle,
    required this.instructorName,
    required this.courseId,
  });

  @override
  State<CourseContentScreen> createState() => _CourseContentScreenState();
}

class _CourseContentScreenState extends State<CourseContentScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<bool> _isExpanded = [true, false]; // For chapters
  final _examRepository = ExamRepository();
  List<Quiz> _exams = [];
  bool _isLoadingExams = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() => _isLoadingExams = true);
    try {
      final result = await _examRepository.getQuizzes();
      if (result['success'] && mounted) {
        final allExams = result['data'] as List<Quiz>;
        // Assuming we need to filter by some course title or instructor for now
        // since I don't have the courseId directly in widget.
        // In a real scenario, we should pass courseId to this screen.
        setState(() {
          _exams = allExams.where((exam) => exam.courseId == widget.courseId).toList();
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
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
        tabs: [
          Tab(text: 'course.lectures_and_pdf'.tr()),
          Tab(text: 'course.exams'.tr()),
        ],
      ),
    );
  }

  Widget _buildLecturesTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildChapterItem(0, 'course.chapter_1_intro'.tr()),
        const SizedBox(height: 20),
        _buildChapterItem(1, 'course.chapter_2_stack'.tr()),
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
              'course.what_is_financial'.tr(),
              '45:30',
              'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400',
              true,
            ),
            const Divider(height: 1, color: Color(0xFFF1F1F1)),
            _buildLectureListItem(
              'course.accounting_concepts'.tr(),
              '52:15',
              'https://images.unsplash.com/photo-1454165833767-027ffcb7141b?w=400',
              true,
            ),
            const Divider(height: 1, color: Color(0xFFF1F1F1)),
            _buildPDFListItem('course.chapter_1_notes'.tr(), 'course.twenty_four_pages'.tr()),
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
                  child: Text(
                    'course.watch'.tr(),
                    style: const TextStyle(
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
    if (_isLoadingExams) {
      return _buildExamsSkeletonList();
    }

    if (_exams.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'course.no_exams_available'.tr(),
            style: const TextStyle(color: Colors.grey, fontSize: 15),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        final isAvailable = exam.isAvailable;
        return _buildExamCard(exam: exam, isAvailable: isAvailable);
      },
    );
  }

  Widget _buildExamsSkeletonList() {
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
                Container(height: 54, width: double.infinity, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamCard({required Quiz exam, required bool isAvailable}) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                exam.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1F2937)),
              ),
              if (!isAvailable && exam.isExpired)
                Text('course.expired'.tr(), style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('${exam.duration} ${'course.minutes'.tr()}', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
              const SizedBox(width: 24),
              Text(exam.type.toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 15)),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isAvailable ? () async {
              final result = await _examRepository.startQuizAttempt(exam.quizId);
              if (result['success'] && mounted) {
                final attempt = result['data'] as QuizAttempt;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuizScreen(
                      quiz: exam,
                      attempt: attempt,
                    ),
                  ),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'course.failed_start_exam'.tr())),
                );
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF263EE2),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: Text(
              isAvailable ? 'course.start_exam'.tr() : (exam.isExpired ? 'course.status_expired'.tr() : 'course.coming_soon'.tr()),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
