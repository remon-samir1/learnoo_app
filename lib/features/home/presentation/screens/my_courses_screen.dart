import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import '../../../course_content/data/course_repository.dart';
import '../../../course_content/presentation/screens/course_detail_screen.dart';
import '../../../search/data/search_repository.dart';
import '../../data/department_repository.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final _courseRepository = CourseRepository();
  final _searchRepository = SearchRepository();
  final _departmentRepository = DepartmentRepository();
  String _selectedFilter = 'All';
  bool _isLoading = true;
  bool _isDepartmentsLoading = true;
  List<dynamic> _courses = [];
  List<dynamic> _departments = [];
  int? _selectedDepartmentId;

  // Search state variables
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<dynamic> _searchResults = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _loadDepartments();
    _loadCourses();
  }

  Future<void> _loadDepartments() async {
    setState(() => _isDepartmentsLoading = true);
    try {
      final result = await _departmentRepository.getDepartments();
      if (result['success'] && mounted) {
        setState(() {
          _departments = result['data'] ?? [];
          _isDepartmentsLoading = false;
        });
      } else if (mounted) {
        setState(() => _isDepartmentsLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isDepartmentsLoading = false);
      }
    }
  }

  Future<void> _loadCourses({int? categoryId}) async {
    setState(() => _isLoading = true);
    try {
      final result = await _courseRepository.getCourses(categoryId: categoryId);
      if (result['success'] && mounted) {
        setState(() {
          _courses = result['data'] ?? [];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final result = await _searchRepository.search(
        query: query,
        type: 'courses', // Filter by courses type
        limit: 10,
      );

      if (mounted) {
        setState(() {
          if (result['success']) {
            _searchResults = result['data'] ?? [];
          } else {
            _searchResults = [];
          }
          _showSearchResults = true;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
        });
      }
    }
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _showSearchResults = false;
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFBFF),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildSearchAndFilters(),
                  _buildStatusChips(),
                  _buildCourseList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 140, // Reduced from Image 3 to fit better in Column
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF5A75FF),
            Color(0xFF8B9DFF),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            'home.my_courses_title'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _performSearch(value);
              },
              decoration: InputDecoration(
                hintText: 'home.search_courses_hint'.tr(),
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
                suffixIcon: _isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(14),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5A75FF)),
                          ),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? GestureDetector(
                            onTap: _clearSearch,
                            child: const Icon(Icons.clear, color: Colors.grey, size: 20),
                          )
                        : null,
                border: InputBorder.none,
              ),
            ),
          ),
          // Removed dropdowns - now using department chips below
        ],
      ),
    );
  }

  Widget _buildStatusChips() {
    // Show loading shimmer while departments are loading
    if (_isDepartmentsLoading) {
      return Container(
        height: 60,
        margin: const EdgeInsets.only(top: 8),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          scrollDirection: Axis.horizontal,
          itemCount: 4,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
              child: Shimmer.fromColors(
                baseColor: Colors.grey[300]!,
                highlightColor: Colors.grey[100]!,
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    // Build department chips with "All" as first option
    final chips = [
      {'id': null, 'name': 'home.filter_all'.tr()},
      ..._departments.map((d) {
        final attributes = d['attributes'] ?? {};
        return {
          'id': int.tryParse(d['id']?.toString() ?? ''),
          'name': attributes['name']?.toString() ??
                  attributes['title']?.toString() ??
                  'Unknown',
        };
      }).toList(),
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final chip = chips[index];
          final chipName = chip['name'] as String;
          final chipId = chip['id'] as int?;
          final isSelected = _selectedDepartmentId == chipId;

          return Padding(
            padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDepartmentId = chipId;
                  _selectedFilter = chipName;
                });
                // Load courses filtered by selected department
                _loadCourses(categoryId: chipId);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF3451E5) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: const Color(0xFF3451E5).withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Center(
                  child: Text(
                    chipName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

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

  Widget _buildCourseList() {
    // Show search results when searching
    if (_showSearchResults) {
      if (_searchResults.isEmpty) {
        return SizedBox(
          height: 200,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(
                  FontAwesomeIcons.magnifyingGlass,
                  color: Color(0xFFD1D1D1),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'home.no_courses_found'.tr(),
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final course = _searchResults[index];
          return _buildCourseCard(course);
        },
      );
    }

    // Show regular course list
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(20),
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        itemBuilder: (context, index) => _buildCourseShimmerCard(),
      );
    }

    if (_courses.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'home.no_courses_available'.tr(),
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
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseShimmerCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 150,
                    height: 13,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  Widget _buildCourseCard(dynamic course) {
    final attributes = course['attributes'] ?? {};
    final title = attributes['title']?.toString() ?? 'Untitled Course';
    final instructor = attributes['instructor']?['data']?['attributes']?['name']?.toString() ??
        attributes['instructor_name']?.toString() ??
        'home.unknown_instructor'.tr();
    final thumbnail = attributes['thumbnail']?.toString() ??
        'https://images.unsplash.com/photo-1554224155-26032ffc0d07?w=400';
    final lectures = attributes['lectures_count']?.toString() ?? '0';
    final students = attributes['students_count']?.toString() ?? '0';
    final progress = (attributes['progress'] as num?)?.toDouble() ?? 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Image.network(
              thumbnail,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  color: const Color(0xFFF3F4F6),
                  child: const Icon(Icons.image, color: Color(0xFF9CA3AF)),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  instructor,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.bookOpen, size: 12, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '$lectures ${'home.lectures'.tr()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                    const FaIcon(FontAwesomeIcons.users, size: 12, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '$students ${'home.students'.tr()}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'home.course_progress'.tr(),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Color(0xFF3451E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3451E5)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 24),
                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _navigateToCourse(course);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF1F1F1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 48),
                        ),
                        child: Text(
                          'home.view_details'.tr(),
                          style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _navigateToCourse(course);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3451E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                        ),
                        child: Text(
                          'home.continue_course'.tr(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
}
