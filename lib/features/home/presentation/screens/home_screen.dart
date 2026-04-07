import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../course_content/data/course_repository.dart';
import '../../../course_content/data/library_repository.dart';
import '../../../course_content/presentation/screens/course_detail_screen.dart';
import '../../../course_content/presentation/screens/electronic_library_screen.dart';
import '../../../course_content/presentation/screens/subject_detail_screen.dart';
import '../../../course_content/presentation/screens/unlock_material_screen.dart';
import '../../../notes/data/notes_repository.dart';
import '../../../notes/presentation/screens/summaries_list_screen.dart';
import '../../../notes/presentation/screens/summary_detail_screen.dart';
import '../../../profile/presentation/screens/my_profile_screen.dart';
import '../../data/department_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authRepository = AuthRepository();
  final _courseRepository = CourseRepository();
  final _departmentRepository = DepartmentRepository();
  final _notesRepository = NotesRepository();
  final _libraryRepository = LibraryRepository();
  bool _isLoading = true;
  bool _isCoursesLoading = true;
  bool _isSubjectsLoading = true;
  bool _isNotesLoading = true;
  bool _isLibrariesLoading = true;
  String _userName = 'Loading...';
  String _universityName = 'Loading...';
  String _facultyName = 'Loading...';
  List<dynamic> _courses = [];
  List<dynamic> _subjects = [];
  List<dynamic> _notes = [];
  List<dynamic> _libraries = [];
  Map<String, dynamic>? _continueWatching;
  List<dynamic> _liveClasses = [];
  bool _isLiveClassesLoading = true;

  void _navigateToCourse(dynamic course) {
    final courseId = course['id']?.toString() ?? '';
    final attributes = course['attributes'] ?? {};
    final title = attributes['title']?.toString() ?? 'Course';
    final thumbnail = attributes['thumbnail']?.toString() ?? '';
    final price = attributes['price']?.toString() ?? '0';
    final description = attributes['description']?.toString() ?? '';
    
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
  }

  Future<void> _loadCourses() async {
    setState(() => _isCoursesLoading = true);
    try {
      final result = await _courseRepository.getCourses();
      if (result['success'] && mounted) {
        setState(() {
          _courses = result['data'] ?? [];
          _isCoursesLoading = false;
        });
      } else if (mounted) {
        setState(() => _isCoursesLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCoursesLoading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCourses();
    _loadSubjects();
    _loadLiveClasses();
    _loadNotes();
    _loadLibraries();
  }

  Future<void> _loadLibraries() async {
    setState(() => _isLibrariesLoading = true);
    try {
      final result = await _libraryRepository.getLibraries();
      if (result['success'] && mounted) {
        setState(() {
          _libraries = result['data'] ?? [];
          _isLibrariesLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLibrariesLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLibrariesLoading = false);
      }
    }
  }

  Future<void> _loadNotes() async {
    setState(() => _isNotesLoading = true);
    try {
      final result = await _notesRepository.getNotes();
      if (result['success'] && mounted) {
        setState(() {
          _notes = result['data'] ?? [];
          _isNotesLoading = false;
        });
      } else if (mounted) {
        setState(() => _isNotesLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isNotesLoading = false);
      }
    }
  }

  Future<void> _loadSubjects() async {
    setState(() => _isSubjectsLoading = true);
    try {
      final result = await _departmentRepository.getDepartments();
      if (result['success'] && mounted) {
        setState(() {
          _subjects = result['data'] ?? [];
          _isSubjectsLoading = false;
        });
      } else if (mounted) {
        setState(() => _isSubjectsLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubjectsLoading = false);
      }
    }
  }

  Future<void> _loadLiveClasses() async {
    setState(() => _isLiveClassesLoading = true);
    try {
      // TODO: Replace with actual API call when endpoint is available
      // final result = await _courseRepository.getLiveClasses();
      // if (result['success'] && mounted) {
      //   setState(() {
      //     _liveClasses = result['data'] ?? [];
      //     _isLiveClassesLoading = false;
      //   });
      // }
      
      // For now, just end loading state with empty list
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _isLiveClassesLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLiveClassesLoading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      // 1. Get Profile
      final profileResult = await _authRepository.getProfile();
      if (profileResult['success']) {
        final attributes = profileResult['data']['attributes'];
        final firstName = (attributes['first_name'] ?? '').toString();
        final lastName = (attributes['last_name'] ?? '').toString();
        final fullName = '$firstName $lastName'.trim();

        final universityName =
            (attributes['university_id']?['data']?['attributes']?['name'] ??
            'University not set').toString();
        final facultyName =
            (attributes['faculty_id']?['data']?['attributes']?['name'] ??
            'Faculty not set').toString();

        setState(() {
          _userName = fullName.isEmpty ? 'User' : fullName;
          _universityName = universityName;
          _facultyName = facultyName;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Gradients
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFE4E1).withValues(alpha: 0.4),
                    const Color(0xFFFFE4E1).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE6E6FA).withValues(alpha: 0.4),
                    const Color(0xFFE6E6FA).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: -150,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFFFFACD).withValues(alpha: 0.3),
                    const Color(0xFFFFFACD).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildSearchBar(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Continue Watching'),
                  const SizedBox(height: 20),
                  _buildContinueWatching(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('My Subjects'),
                  const SizedBox(height: 20),
                  _buildSubjectsList(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('My Courses'),
                  const SizedBox(height: 20),
                  _buildCoursesList(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Upcoming Live Classes'),
                  const SizedBox(height: 20),
                  _buildLiveClassesList(),
                  const SizedBox(height: 32),
                  _buildSectionHeaderWithAction(
                    'New Notes & Summaries', 'View All',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SummariesListScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildNotesSummariesList(),
                  const SizedBox(height: 32),
                  _buildSectionHeaderWithAction(
                    'Electronic Library', 'View All',
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ElectronicLibraryScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  _buildLibraryList(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: const NetworkImage(
              'https://i.pravatar.cc/150?u=noura',
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, $_userName',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B4B4B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _isLoading
                    ? 'Loading profile...'
                    : '$_universityName — $_facultyName',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF4B4B4B).withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.bell,
                color: Color(0xFF5A75FF),
                size: 22,
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4B4B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MyProfileScreen()),
            );
          },
          child: Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.gear,
                color: Color(0xFF5A75FF),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const TextField(
        decoration: InputDecoration(
          hintText: 'Search courses, lectures...',
          hintStyle: TextStyle(color: Color(0xFFD1D1D1), fontSize: 14),
          prefixIcon: Padding(
            padding: EdgeInsets.all(14),
            child: FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              color: Color(0xFFD1D1D1),
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildSectionHeaderWithAction(String title, String actionText, VoidCallback onAction) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(
            actionText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5A75FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContinueWatching() {
    if (_isLoading) {
      return _buildContinueWatchingShimmer();
    }

    if (_continueWatching == null) {
      return const SizedBox.shrink();
    }

    final data = _continueWatching!;
    final courseName = data['course_name']?.toString() ?? 'Course';
    final lectureName = data['lecture_name']?.toString() ?? 'Lecture';
    final thumbnail = data['thumbnail']?.toString() ??
        'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400';
    final progress = (data['progress'] as num?)?.toDouble() ?? 0.0;
    final timeRemaining = data['time_remaining']?.toString() ?? '00:00';

    return _buildContinueWatchingCard(
      courseName: courseName,
      lectureName: lectureName,
      thumbnail: thumbnail,
      progress: progress,
      timeRemaining: timeRemaining,
    );
  }

  Widget _buildContinueWatchingShimmer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 104,
                  height: 78,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 100,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueWatchingCard({
    required String courseName,
    required String lectureName,
    required String thumbnail,
    required double progress,
    required String timeRemaining,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      thumbnail,
                      width: 104,
                      height: 78,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.play,
                      color: Color(0xFF5A75FF),
                      size: 14,
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
                      courseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lectureName,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: const Color(0xFFF1F1F1),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF5A75FF),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeRemaining,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2137D6),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Continue',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
                FaIcon(FontAwesomeIcons.play, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsList() {
    if (_isSubjectsLoading) {
      return _buildSubjectsShimmerList();
    }

    if (_subjects.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No subjects available',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: _subjects.asMap().entries.map((entry) {
          final index = entry.key;
          final subject = entry.value;
          final attributes = subject['attributes'] ?? {};
          final id = subject['id']?.toString() ?? '';
          final title = attributes['name']?.toString() ??
              attributes['title']?.toString() ??
              'Subject';
          final image = attributes['image']?.toString() ??
              attributes['icon']?.toString() ??
              '';

          // Get color based on index
          final colorIndex = index % AppColors.subjectColors.length;
          final colors = AppColors.subjectColors[colorIndex];

          return _buildSubjectItem(
            id,
            title,
            image,
            colors['bg']!,
            colors['text']!,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSubjectsShimmerList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(4, (index) {
          return Container(
            width: 76,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 50,
                    height: 11,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSubjectItem(
    String subjectId,
    String title,
    String imageUrl,
    Color bgColor,
    Color iconColor,
  ) {
    final firstLetter = title.isNotEmpty ? title[0].toUpperCase() : '?';

    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToSubjectDetail(subjectId, title, imageUrl),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            if (imageUrl.isNotEmpty)
              ClipOval(
                child: Image.network(
                  imageUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildSubjectIconFallback(firstLetter, iconColor);
                  },
                ),
              )
            else
              _buildSubjectIconFallback(firstLetter, iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectIconFallback(String letter, Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _navigateToSubjectDetail(String subjectId, String title, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDetailScreen(
          subjectId: subjectId,
          subjectTitle: title,
          subjectImage: imageUrl,
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    if (_isCoursesLoading) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        child: Row(
          children: [
            _buildCourseShimmerCard(),
            _buildCourseShimmerCard(),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No courses available',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: _courses.map((course) {
          final attributes = course['attributes'] ?? {};
          final title = attributes['title']?.toString() ?? 'Untitled Course';
          final instructor = attributes['instructor']?['data']?['attributes']?['name']?.toString() ??
              attributes['instructor_name']?.toString() ??
              'Unknown Instructor';
          final thumbnail = attributes['thumbnail']?.toString() ??
              'https://images.unsplash.com/photo-1554224155-26032ffc0d07?w=400';
          final accentColor = const Color(0xFF2137D6);

          return _buildCourseCard(
            course,
            title,
            instructor,
            thumbnail,
            accentColor: accentColor,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCourseShimmerCard() {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 130,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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

  Widget _buildCourseCard(
    dynamic course,
    String title,
    String instructor,
    String imageUrl, {
    Color? accentColor,
  }) {
    final color = accentColor ?? const Color(0xFF2137D6);
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToCourse(course),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                imageUrl,
                height: 130,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1F2937),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    instructor,
                    style: TextStyle(
                      color: const Color(0xFF9CA3AF),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<dynamic> get _summaryNotes {
    return _notes.where((note) {
      final attributes = note['attributes'] ?? {};
      return attributes['type'] == 'summary';
    }).toList();
  }

  Widget _buildNotesSummariesList() {
    if (_isNotesLoading) {
      return _buildNotesSummariesShimmer();
    }

    if (_summaryNotes.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No summaries available',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: _summaryNotes.take(5).map((note) {
          final attributes = note['attributes'] ?? {};
          final title = attributes['title']?.toString() ?? 'Untitled';
          final type = attributes['type']?.toString() ?? 'note';
          final linkedLecture = attributes['linked_lecture']?.toString();
          final createdAt = attributes['created_at']?.toString();

          final typeStyles = _getNoteTypeStyles(type);
          final dateText = _formatNoteDate(createdAt);
          final subtitle = linkedLecture != null
              ? '$linkedLecture • $dateText'
              : dateText;

          return GestureDetector(
            onTap: () => _navigateToNoteDetail(note),
            child: _buildNoteSummaryCard(
              title,
              subtitle,
              typeStyles['icon'],
              typeStyles['bgColor'],
              typeStyles['iconColor'],
            ),
          );
        }).toList(),
      ),
    );
  }

  Map<String, dynamic> _getNoteTypeStyles(String type) {
    switch (type) {
      case 'summary':
        return {
          'icon': FontAwesomeIcons.fileLines,
          'bgColor': const Color(0xFFFFF0F0),
          'iconColor': const Color(0xFFFF4B4B),
        };
      case 'highlight':
      case 'key_point':
        return {
          'icon': FontAwesomeIcons.highlighter,
          'bgColor': const Color(0xFFE6F9F1),
          'iconColor': const Color(0xFF10B981),
        };
      case 'important_notice':
        return {
          'icon': FontAwesomeIcons.circleExclamation,
          'bgColor': const Color(0xFFFFE6E6),
          'iconColor': const Color(0xFFEF4444),
        };
      case 'video_note':
        return {
          'icon': FontAwesomeIcons.video,
          'bgColor': const Color(0xFFEEF0FF),
          'iconColor': const Color(0xFF5A75FF),
        };
      default:
        return {
          'icon': FontAwesomeIcons.noteSticky,
          'bgColor': const Color(0xFFFFF9F0),
          'iconColor': const Color(0xFFF2994A),
        };
    }
  }

  String _formatNoteDate(String? dateString) {
    if (dateString == null) return 'Recently';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${(difference.inDays / 7).floor()} weeks ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _navigateToNoteDetail(dynamic note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryDetailScreen(note: note),
      ),
    );
  }

  Widget _buildNotesSummariesShimmer() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: List.generate(3, (index) {
          return Container(
            width: 180,
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F1F1)),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNoteSummaryCard(
    String title,
    String subtitle,
    FaIconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1F2937),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildLibraryList() {
    if (_isLibrariesLoading) {
      return _buildLibraryShimmerList();
    }

    if (_libraries.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No library materials available',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: _libraries.take(5).map((library) {
          final attributes = library['attributes'] ?? {};
          final title = attributes['title']?.toString() ?? 'Untitled';
          final price = attributes['price']?.toString() ?? '0';
          final coverImage = attributes['cover_image']?.toString() ?? '';
          final codeActivation = attributes['code_activation'] == true;

          return _buildLibraryCard(
            title: title,
            price: 'EGP $price',
            imageUrl: coverImage,
            requiresCode: codeActivation,
            library: library,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLibraryShimmerList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildLibraryShimmerCard(),
          _buildLibraryShimmerCard(),
          _buildLibraryShimmerCard(),
        ],
      ),
    );
  }

  Widget _buildLibraryShimmerCard() {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Row(
          children: [
            Container(
              width: 80,
              height: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 60,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 80,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryCard({
    required String title,
    required String price,
    required String imageUrl,
    required bool requiresCode,
    required dynamic library,
  }) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 16),
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
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(16),
            ),
            child: Image.network(
              imageUrl,
              width: 80,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 100,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.book, color: Color(0xFF9CA3AF)),
                );
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF5A75FF),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (requiresCode) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UnlockMaterialScreen(library: library),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2137D6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            requiresCode ? 'Unlock' : 'Free',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveClassesList() {
    if (_isLiveClassesLoading) {
      return Column(
        children: [
          _buildLiveClassShimmer(),
          const SizedBox(height: 16),
          _buildLiveClassShimmer(),
        ],
      );
    }

    if (_liveClasses.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No upcoming live classes',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return Column(
      children: _liveClasses.map((liveClass) {
        final attributes = liveClass['attributes'] ?? {};
        final title = attributes['title']?.toString() ?? 'Live Session';
        final instructor = attributes['instructor']?['data']?['attributes']?['name']?.toString() ??
            attributes['instructor_name']?.toString() ??
            'Unknown Instructor';
        final time = attributes['scheduled_at']?.toString() ??
            attributes['time']?.toString() ??
            'Time TBD';
        final isLive = attributes['is_live'] == true ||
            attributes['status']?.toString() == 'live';

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildLiveClassCard(
            title: title,
            instructor: instructor,
            time: time,
            isLive: isLive,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLiveClassShimmer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F1)),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 24,
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
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 150,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveClassCard({
    required String title,
    required String instructor,
    required String time,
    required bool isLive,
  }) {
    return Container(
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
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.liveBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 3,
                      backgroundColor: AppColors.liveText,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: AppColors.liveText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const FaIcon(
                FontAwesomeIcons.towerBroadcast,
                color: Color(0xFF5A75FF),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            instructor,
            style: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            time,
            style: TextStyle(
              color: const Color(0xFF9CA3AF).withValues(alpha: 0.7),
              fontSize: 12,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.joinLiveGreen,
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
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
