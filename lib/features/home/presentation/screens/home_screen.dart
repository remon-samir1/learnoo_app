import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../course_content/presentation/screens/course_content_screen.dart';
import '../../../course_content/presentation/screens/subject_detail_screen.dart';
import '../../../course_content/presentation/screens/lecture_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authRepository = AuthRepository();
  bool _isLoading = true;
  String _userName = 'Loading...'; // Default/Fallback
  String _universityName = 'Loading...';
  String _facultyName = 'Loading...';

  void _navigateToLecture(String title, String subtitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LectureDetailScreen(title: title, subtitle: subtitle),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
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
                  _buildContinueWatchingCard(),
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
                  _buildLiveClassCard(
                    title: 'Advanced Sorting Algorithms',
                    instructor: 'Dr. Sarah Ahmed',
                    time: 'Today, 6:00 PM • 90 min',
                    isLive: true,
                  ),
                  const SizedBox(height: 16),
                  _buildLiveClassCard(
                    title: 'Neural Networks Deep Dive',
                    instructor: 'Dr. Mohamed Ali',
                    time: 'Tomorrow, 4:00 PM • 120 min',
                    isLive: true,
                  ),
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

  void _navigateToCourse(String title, String instructor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CourseContentScreen(courseTitle: title, instructorName: instructor),
      ),
    );
  }

  void _navigateToSubjectDetail(String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDetailScreen(
          subjectTitle: title,
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

  Widget _buildContinueWatchingCard() {
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
                      'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400',
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
                    const Text(
                      'Cost Accounting',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Accounting Basics',
                      style: TextStyle(
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
                            child: const LinearProgressIndicator(
                              value: 0.6,
                              backgroundColor: Color(0xFFF1F1F1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF5A75FF),
                              ),
                              minHeight: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '35:20',
                          style: TextStyle(
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
            onPressed: () => _navigateToLecture(
              'Cost Accounting',
              'Chapter 1: Introduction',
            ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildSubjectItem(
            'Accounting',
            FontAwesomeIcons.calculator,
            AppColors.accountingBg,
            AppColors.accountingText,
          ),
          _buildSubjectItem(
            'Business',
            FontAwesomeIcons.briefcase,
            AppColors.businessBg,
            AppColors.businessText,
          ),
          _buildSubjectItem(
            'Economics',
            FontAwesomeIcons.chartLine,
            AppColors.economicsBg,
            AppColors.economicsText,
          ),
          _buildSubjectItem(
            'Finance',
            FontAwesomeIcons.chartPie,
            AppColors.financeBg,
            AppColors.financeText,
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectItem(
    String title,
    FaIconData icon,
    Color bgColor,
    Color iconColor,
  ) {
    return Container(
      width: 76,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToSubjectDetail(title),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            FaIcon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoursesList() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _buildCourseCard(
            'Principles of Financial Accounting',
            'Dr. Sarah Ahmed',
            'https://images.unsplash.com/photo-1554224154-26032ffc0d07?w=400',
            const Color(0xFF2137D6),
          ),
          _buildCourseCard(
            'Monetary Economics',
            'Dr. Mohamed Ali',
            'https://images.unsplash.com/photo-1554224154-26032ffc08d1?w=400',
            const Color(0xFFE2F017),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(
    String title,
    String instructor,
    String imageUrl,
    Color accentColor,
  ) {
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
        onTap: () => _navigateToCourse(title, instructor),
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
                color: accentColor,
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
            onPressed: () => _navigateToCourse('Live Session', instructor),
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
