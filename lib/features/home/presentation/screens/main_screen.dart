import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:learnoo/features/home/presentation/screens/home_screen.dart';
import 'package:learnoo/features/home/presentation/screens/my_courses_screen.dart';
import 'package:learnoo/features/profile/presentation/screens/my_profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const MyCoursesScreen(),
    const Center(child: Text('Live Screen')),
    const Center(child: Text('Exams Screen')),
    const MyProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF5A75FF),
          unselectedItemColor: const Color(0xFF9CA3AF),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
          elevation: 0,
          items: [
            _buildNavItem(FontAwesomeIcons.house, FontAwesomeIcons.house, 'Home', 0),
            _buildNavItem(FontAwesomeIcons.bookOpen, FontAwesomeIcons.bookOpen, 'Courses', 1),
            _buildNavItem(FontAwesomeIcons.video, FontAwesomeIcons.video, 'Live', 2),
            _buildNavItem(FontAwesomeIcons.fileSignature, FontAwesomeIcons.fileSignature, 'Exams', 3),
            _buildNavItem(FontAwesomeIcons.user, FontAwesomeIcons.user, 'Profile', 4),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    FaIconData icon,
    FaIconData activeIcon,
    String label,
    int index,
  ) {
    final isSelected = _selectedIndex == index;
    return BottomNavigationBarItem(
      icon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: FaIcon(isSelected ? activeIcon : icon, size: 20),
      ),
      activeIcon: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(activeIcon, color: const Color(0xFF5A75FF), size: 20),
            const SizedBox(height: 4),
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF5A75FF),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
      label: label,
    );
  }
}
