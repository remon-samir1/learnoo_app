import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:learnoo/features/course_content/presentation/screens/course_content_screen.dart';

class MyCoursesScreen extends StatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  State<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends State<MyCoursesScreen> {
  final String _selectedFilter = 'All';

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
      child: const SafeArea(
        bottom: false,
        child: Center(
          child: Text(
            'My Courses',
            style: TextStyle(
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
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Dropdowns
          Row(
            children: [
              _buildFilterDropdown('All Subjects'),
              const SizedBox(width: 12),
              _buildFilterDropdown('Recently Opened'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F1F1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChips() {
    final chips = ['All', 'In Progress', 'Completed', 'Not Started'];
    return Container(
      height: 60,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        itemBuilder: (context, index) {
          final isSelected = chips[index] == _selectedFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
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
                  chips[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCourseList() {
    final courses = [
      {
        'title': 'Financial Accounting Basics',
        'instructor': 'Dr. Sarah Ahmed',
        'lectures': '24 lectures',
        'students': '156 students',
        'progress': 0.65,
        'image': 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=400',
      },
      {
        'title': 'Business Management Essentials',
        'instructor': 'Prof. John Smith',
        'lectures': '30 lectures',
        'students': '200 students',
        'progress': 0.75,
        'image': 'https://images.unsplash.com/photo-1454165833767-027ffcb7141b?w=400',
      },
      {
        'title': 'Economics Made Simple',
        'instructor': 'Dr. Emily Tran',
        'lectures': '28 lectures',
        'students': '150 students',
        'progress': 0.80,
        'image': 'https://images.unsplash.com/photo-1507679799987-c7377f54b45d?w=400',
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return _buildCourseCard(course);
      },
    );
  }

  Widget _buildCourseCard(Map<String, dynamic> course) {
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
              course['image'] as String,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course['title'] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  course['instructor'] as String,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.bookOpen, size: 12, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      course['lectures'] as String,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(width: 20),
                    const FaIcon(FontAwesomeIcons.users, size: 12, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      course['students'] as String,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Course Progress',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '${((course['progress'] as double) * 100).toInt()}%',
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
                    value: course['progress'] as double,
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseContentScreen(
                                courseTitle: course['title'] as String,
                                instructorName: course['instructor'] as String,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFF1F1F1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 48),
                        ),
                        child: const Text(
                          'VIEW DETAILS',
                          style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseContentScreen(
                                courseTitle: course['title'] as String,
                                instructorName: course['instructor'] as String,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3451E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(0, 48),
                          elevation: 0,
                        ),
                        child: const Text(
                          'CONTINUE',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
