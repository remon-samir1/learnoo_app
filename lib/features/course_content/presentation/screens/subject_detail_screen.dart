import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../data/course_repository.dart';
import '../../data/live_room_repository.dart';
import '../../data/models/live_room.dart' as lr;
import '../../data/course_files_repository.dart';
import '../../../exams/data/exam_repository.dart';
import '../../../exams/models/quiz_models.dart';
import 'course_detail_screen.dart';
import '../../../exams/presentation/screens/quiz_screen.dart';
import 'pdf_reviewer_screen.dart';
import 'pdf_viewer_screen.dart';

class SubjectDetailScreen extends StatefulWidget {
  final String subjectId;
  final String subjectTitle;
  final String? subjectImage;
  final String subtitle;

  const SubjectDetailScreen({
    super.key,
    required this.subjectId,
    required this.subjectTitle,
    this.subjectImage,
    this.subtitle = 'Course Content',
  });

  @override
  State<SubjectDetailScreen> createState() => _SubjectDetailScreenState();
}

class _SubjectDetailScreenState extends State<SubjectDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _courseRepository = CourseRepository();
  final _examRepository = ExamRepository();
  final _courseFilesRepository = CourseFilesRepository();
  final _liveRoomRepository = LiveRoomRepository();
  bool _isLoadingCourses = true;
  bool _isLoadingExams = true;
  bool _isLoadingLiveRooms = true;
  bool _isLoadingFiles = true;
  List<dynamic> _courses = [];
  List<Quiz> _exams = [];
  List<lr.LiveRoom> _liveRooms = [];
  List<CourseFile> _files = [];
  String? _filesErrorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCourses(),
    ]);
    // Load files, exams and live rooms after courses to have course IDs for filtering
    await Future.wait([
      _loadFiles(),
      _loadExams(),
      _loadLiveRooms(),
    ]);
  }

  Future<void> _loadExams() async {
    setState(() => _isLoadingExams = true);
    try {
      final result = await _examRepository.getQuizzes();
      if (result['success'] && mounted) {
        final allExams = result['data'] as List<Quiz>;
        // Filter exams by course IDs in this subject
        final courseIds = _courses.map((c) => int.tryParse(c['id'].toString()) ?? -1).toList();
        setState(() {
          _exams = allExams.where((exam) => courseIds.contains(exam.courseId)).toList();
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

  Future<void> _loadCourses() async {
    if (widget.subjectId.isEmpty) {
      setState(() => _isLoadingCourses = false);
      return;
    }

    setState(() => _isLoadingCourses = true);
    try {
      final categoryId = int.tryParse(widget.subjectId);
      final result = await _courseRepository.getCourses(categoryId: categoryId);
      if (result['success'] && mounted) {
        setState(() {
          _courses = result['data'] ?? [];
          _isLoadingCourses = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingCourses = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCourses = false);
      }
    }
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoadingFiles = true;
      _filesErrorMessage = null;
    });

    try {
      final categoryId = int.tryParse(widget.subjectId);
      late final Map<String, dynamic> result;

      if (categoryId != null) {
        result = await _courseFilesRepository.getFilesByCategory(categoryId);
      } else {
        // Fallback: try to get files by course IDs if we have courses loaded
        final courseIds = _courses
            .map((c) => int.tryParse(c['id'].toString()))
            .whereType<int>()
            .toList();
        result = await _courseFilesRepository.getFilesByCourseIds(courseIds);
      }

      if (mounted) {
        if (result['success']) {
          setState(() {
            _files = result['data'] as List<CourseFile>? ?? [];
            _isLoadingFiles = false;
          });
        } else {
          setState(() {
            _filesErrorMessage = result['message'] ?? 'course.failed_load_files'.tr();
            _isLoadingFiles = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _filesErrorMessage = 'course.connection_error'.tr(args: [e.toString()]);
          _isLoadingFiles = false;
        });
      }
    }
  }

  Future<void> _refreshFiles() async {
    await _loadFiles();
  }

  void _openFile(CourseFile file) {
    if (file.filePath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('course.file_not_available'.tr())),
      );
      return;
    }

    if (file.isPdf) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            pdfUrl: file.filePath,
            title: file.title,
          ),
        ),
      );
    } else if (file.canPreview) {
      // For other previewable files, use the appropriate viewer
      // For now, show a message that file type is not directly viewable
      _downloadOrOpenFile(file);
    } else {
      // For non-previewable files, offer download
      _downloadOrOpenFile(file);
    }
  }

  void _downloadOrOpenFile(CourseFile file) async {
    // Show options for non-PDF files
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                file.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '.${file.extension.toUpperCase()} ${file.formattedSize.isNotEmpty ? '• ${file.formattedSize}' : ''}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              if (file.isLocked && !file.downloadable)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(FontAwesomeIcons.lock, color: Color(0xFFFF4B4B), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'course.file_locked'.tr(),
                          style: const TextStyle(
                            color: Color(0xFFFF4B4B),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    if (file.canPreview || file.isPdf)
                      ListTile(
                        leading: const FaIcon(FontAwesomeIcons.eye, color: Color(0xFF5A75FF)),
                        title: Text('course.open_file'.tr()),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PdfViewerScreen(
                                pdfUrl: file.filePath,
                                title: file.title,
                              ),
                            ),
                          );
                        },
                      ),
                    if (file.downloadable)
                      ListTile(
                        leading: const FaIcon(FontAwesomeIcons.download, color: Color(0xFF5A75FF)),
                        title: Text('course.download_file'.tr()),
                        onTap: () {
                          Navigator.pop(context);
                          // TODO: Implement download functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('course.download_started'.tr(args: [file.title]))),
                          );
                        },
                      ),
                    ListTile(
                      leading: const FaIcon(FontAwesomeIcons.share, color: Color(0xFF5A75FF)),
                      title: Text('course.share_file'.tr()),
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Implement share functionality
                      },
                    ),
                  ],
                ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectIconFallback() {
    final firstLetter = widget.subjectTitle.isNotEmpty 
        ? widget.subjectTitle[0].toUpperCase() 
        : '?';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
    );
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
                  if (widget.subjectImage != null && widget.subjectImage!.isNotEmpty)
                    ClipOval(
                      child: Image.network(
                        widget.subjectImage!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildSubjectIconFallback();
                        },
                      ),
                    )
                  else
                    _buildSubjectIconFallback(),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subjectTitle,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          widget.subtitle == 'Course Content' ? 'course.course_content'.tr() : widget.subtitle,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildHeaderInfoCard(FontAwesomeIcons.play, 'course.courses_count'.tr(args: [_courses.length.toString()])),
                  _buildHeaderInfoCard(FontAwesomeIcons.fileLines, 'course.files_count'.tr(args: [_files.length.toString()])),
                  _buildHeaderInfoCard(FontAwesomeIcons.calendarCheck, 'course.exams_count'.tr(args: ['3'])),
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
        labelPadding: const EdgeInsets.symmetric(horizontal: 18),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: [
          _buildTabItem(FontAwesomeIcons.circlePlay, 'course.courses'.tr()),
          _buildTabItem(FontAwesomeIcons.video, 'course.live'.tr()),
          _buildTabItem(FontAwesomeIcons.fileLines, 'course.files'.tr()),
          _buildTabItem(FontAwesomeIcons.calendarCheck, 'course.exams'.tr()),
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
    if (_isLoadingCourses) {
      return _buildCoursesSkeletonList();
    }

    if (_courses.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'course.no_courses_subject'.tr(),
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        final attributes = course['attributes'] ?? {};
        final title = attributes['title']?.toString() ?? 'course.untitled_course'.tr();
        final thumbnail = attributes['thumbnail']?.toString() ?? '';
        final price = attributes['price']?.toString() ?? '0';
        
        return _buildCourseCard(
          courseId: course['id']?.toString() ?? '',
          title: title,
          thumbnail: thumbnail,
          price: price,
          description: attributes['description']?.toString() ?? '',
        );
      },
    );
  }

  Widget _buildCoursesSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 75,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 80,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourseCard({
    required String courseId,
    required String title,
    required String thumbnail,
    required String price,
    required String description,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetailScreen(
              courseId: courseId,
              title: title,
              thumbnail: thumbnail,
              price: price,
              description: description,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                  child: thumbnail.isNotEmpty
                      ? Image.network(
                          thumbnail,
                          width: 100,
                          height: 75,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildCourseImagePlaceholder();
                          },
                        )
                      : _buildCourseImagePlaceholder(),
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
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FaIcon(FontAwesomeIcons.tag, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text(
                        'EGP $price',
                        style: TextStyle(
                          color: const Color(0xFF5A75FF),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseImagePlaceholder() {
    return Container(
      width: 100,
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(Icons.image_not_supported, color: Color(0xFF9CA3AF), size: 24),
      ),
    );
  }

  Future<void> _loadLiveRooms() async {
    setState(() => _isLoadingLiveRooms = true);
    try {
      final result = await _liveRoomRepository.getLiveRooms();
      if (result['success'] && mounted) {
        final allLiveRooms = result['data'] as List<lr.LiveRoom>;
        // Filter live rooms by course IDs in this subject
        final courseIds = _courses.map((c) => c['id']?.toString()).where((id) => id != null).toSet();
        setState(() {
          _liveRooms = allLiveRooms.where((room) => courseIds.contains(room.courseId)).toList();
          _isLoadingLiveRooms = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingLiveRooms = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLiveRooms = false);
      }
    }
  }

  Widget _buildLiveTab() {
    if (_isLoadingLiveRooms) {
      return _buildLiveRoomsSkeletonList();
    }

    if (_liveRooms.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'course.no_live_subject'.tr(),
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _liveRooms.length,
      itemBuilder: (context, index) {
        final room = _liveRooms[index];
        return _buildLiveRoomCard(room);
      },
    );
  }

  Widget _buildLiveRoomsSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  height: 18,
                  width: double.infinity,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  height: 14,
                  width: 120,
                  color: Colors.white,
                ),
                const SizedBox(height: 4),
                Container(
                  height: 12,
                  width: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 20),
                Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveRoomCard(lr.LiveRoom room) {
    final isLive = room.status == lr.SessionStatus.now;
    final isUpcoming = room.status == lr.SessionStatus.upcoming;
    
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
                  color: isLive ? const Color(0xFFFFF0F0) : (isUpcoming ? const Color(0xFFFFF9F0) : const Color(0xFFF0F2FF)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 3,
                      backgroundColor: isLive ? const Color(0xFFFF4B4B) : (isUpcoming ? const Color(0xFFF2994A) : const Color(0xFF5A75FF)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isLive ? 'course.live_uppercase'.tr() : (isUpcoming ? 'course.upcoming_uppercase'.tr() : 'course.recorded_uppercase'.tr()),
                      style: TextStyle(
                        color: isLive ? const Color(0xFFFF4B4B) : (isUpcoming ? const Color(0xFFF2994A) : const Color(0xFF5A75FF)),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              FaIcon(
                FontAwesomeIcons.towerBroadcast,
                color: isLive ? const Color(0xFFFF4B4B) : const Color(0xFF5A75FF),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            room.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            room.instructorName,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${room.formattedTime} • ${room.duration}',
            style: TextStyle(
              color: const Color(0xFF9CA3AF).withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          if (isLive)
            ElevatedButton(
              onPressed: () {
                // Handle join live
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2DBC77),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(
                'course.join_live'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            )
          else if (isUpcoming)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Handle view details
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B7280),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(
                      'course.view_details'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle set reminder
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5A75FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    child: Text(
                      'course.set_reminder'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: () {
                // Handle watch recorded
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A75FF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'WATCH RECORDING',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilesTab() {
    if (_isLoadingFiles) {
      return _buildFilesSkeletonList();
    }

    if (_filesErrorMessage != null) {
      return _buildFilesErrorState();
    }

    if (_files.isEmpty) {
      return _buildFilesEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _refreshFiles,
      color: const Color(0xFF5A75FF),
      backgroundColor: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          return _buildFileCard(file);
        },
      ),
    );
  }

  Widget _buildFilesSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilesEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  FontAwesomeIcons.fileCircleXmark,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'course.no_files_subject'.tr(),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilesErrorState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
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
                  _filesErrorMessage!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshFiles,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A75FF),
                    foregroundColor: Colors.white,
                  ),
                  child: Text('course.retry'.tr()),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileCard(CourseFile file) {
    final isLocked = file.isLocked && !file.downloadable;
    final canView = !isLocked && (file.isPdf || file.canPreview);

    return InkWell(
      onTap: isLocked ? null : () => _openFile(file),
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                color: isLocked ? const Color(0xFFF3F4F6) : const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(
                isLocked ? FontAwesomeIcons.lock : _getFileIcon(file.extension),
                color: isLocked ? const Color(0xFF9CA3AF) : const Color(0xFFFF4B4B),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isLocked ? const Color(0xFF9CA3AF) : const Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFileInfo(file),
                    style: TextStyle(
                      color: isLocked ? const Color(0xFF9CA3AF) : const Color(0xFF9CA3AF),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (canView)
              _buildFileActionButton(FontAwesomeIcons.eye)
            else if (file.downloadable && !isLocked)
              _buildFileActionButton(FontAwesomeIcons.download)
            else if (isLocked)
              _buildFileActionButton(FontAwesomeIcons.lock),
          ],
        ),
      ),
    );
  }

  FaIconData _getFileIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return FontAwesomeIcons.filePdf;
      case 'doc':
      case 'docx':
        return FontAwesomeIcons.fileWord;
      case 'xls':
      case 'xlsx':
        return FontAwesomeIcons.fileExcel;
      case 'ppt':
      case 'pptx':
        return FontAwesomeIcons.filePowerpoint;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return FontAwesomeIcons.fileImage;
      case 'mp4':
      case 'mov':
      case 'avi':
        return FontAwesomeIcons.fileVideo;
      case 'mp3':
      case 'wav':
      case 'aac':
        return FontAwesomeIcons.fileAudio;
      case 'zip':
      case 'rar':
      case '7z':
        return FontAwesomeIcons.fileZipper;
      default:
        return FontAwesomeIcons.fileLines;
    }
  }

  String _getFileInfo(CourseFile file) {
    final parts = <String>[];

    if (file.extension.isNotEmpty) {
      parts.add(file.extension.toUpperCase());
    }

    if (file.formattedSize.isNotEmpty) {
      parts.add(file.formattedSize);
    }

    if (file.isLocked && !file.downloadable) {
      parts.add('course.locked'.tr());
    }

    return parts.join(' • ');
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
    if (_isLoadingExams) {
      return _buildExamsSkeletonList();
    }

    if (_exams.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No exams available for this subject',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _exams.length,
      itemBuilder: (context, index) {
        final exam = _exams[index];
        final isAvailable = exam.isAvailable;
        
        return _buildExamCard(
          exam: exam,
          isAvailable: isAvailable,
        );
      },
    );
  }

  Widget _buildExamsSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 60, color: Colors.white),
                const SizedBox(height: 12),
                Container(height: 16, width: double.infinity, color: Colors.white),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(height: 12, width: 80, color: Colors.white),
                    const SizedBox(width: 20),
                    Container(height: 12, width: 80, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 20),
                Container(height: 50, width: double.infinity, color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExamCard({required Quiz exam, required bool isAvailable}) {
    final status = exam.getStatus(1); // Default to 1 attempt for now as we don't have remainingAttempts here
    final statusText = exam.getStatusTextKey(status).tr();
    
    Color statusColor;
    Color statusBgColor;

    switch (status) {
      case QuizStatus.available:
        statusColor = const Color(0xFF27AE60);
        statusBgColor = const Color(0xFFE6F7F0);
        break;
      case QuizStatus.expired:
        statusColor = Colors.red;
        statusBgColor = const Color(0xFFFFF0F0);
        break;
      case QuizStatus.upcoming:
        statusColor = const Color(0xFFF2994A);
        statusBgColor = const Color(0xFFFFF9F0);
        break;
      case QuizStatus.noAttempts:
        statusColor = const Color(0xFFFF4B4B);
        statusBgColor = const Color(0xFFFFF0F0);
        break;
    }

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
              color: statusBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(exam.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1F2937))),
          const SizedBox(height: 12),
          Row(
            children: [
              FaIcon(FontAwesomeIcons.clock, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text('course.duration_min'.tr(args: [exam.duration.toString()]), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              const SizedBox(width: 20),
              FaIcon(FontAwesomeIcons.circleInfo, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(exam.type.toUpperCase(), style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: status == QuizStatus.available ? () async {
              // Start attempt logic
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
                  SnackBar(content: Text(result['message'] ?? 'exams.failed_start'.tr())),
                );
              }
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: status == QuizStatus.available ? const Color(0xFF263EE2) : const Color(0xFFC4C4C4),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFC4C4C4),
              disabledForegroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text(
              exam.getButtonTextKey(status).tr().toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
        ],
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
