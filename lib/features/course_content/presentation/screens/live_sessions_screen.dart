import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'widgets/session_detail_modal.dart';
import 'widgets/set_reminder_modal.dart';

class LiveSessionsScreen extends StatefulWidget {
  const LiveSessionsScreen({super.key});

  @override
  State<LiveSessionsScreen> createState() => _LiveSessionsScreenState();
}

class _LiveSessionsScreenState extends State<LiveSessionsScreen> {
  String _selectedFilter = 'All';

  final List<LiveSession> _sessions = [
    LiveSession(
      id: '1',
      title: 'Advanced Sorting Algorithms',
      instructor: 'Dr. Sarah Ahmed',
      time: 'Today, 6:00 PM',
      duration: '90 min',
      status: SessionStatus.now,
      category: 'Computer Science',
      description: 'Join the live session to review the key concepts from Chapter 1 and ask your questions directly.',
      sessionInfo: 'This session is related to Financial Accounting Basics and can include revision, Q&A, and problem solving.',
    ),
    LiveSession(
      id: '2',
      title: 'Advanced Sorting Algorithms',
      instructor: 'Dr. Sarah Ahmed',
      time: 'Today, 6:00 PM',
      duration: '90 min',
      status: SessionStatus.upcoming,
      category: 'Computer Science',
      description: 'Join the live session to review the key concepts from Chapter 1 and ask your questions directly.',
    ),
    LiveSession(
      id: '3',
      title: 'Neural Networks Deep Dive',
      instructor: 'Dr. Mohamed Ali',
      time: 'Tomorrow, 4:00 PM',
      duration: '120 min',
      status: SessionStatus.now,
      category: 'AI & Machine Learning',
      description: 'Deep dive into neural network architectures and implementations.',
    ),
    LiveSession(
      id: '4',
      title: 'Advanced Sorting Algorithms',
      instructor: 'Dr. Sarah Ahmed',
      time: 'Today, 6:00 PM',
      duration: '90 min',
      status: SessionStatus.recorded,
      category: 'Computer Science',
      description: 'Replay the previous live explanation of financial statements anytime from the app.',
      sessionInfo: 'This session is related to Financial Accounting Basics and can include revision, Q&A, and problem solving.',
    ),
    LiveSession(
      id: '5',
      title: 'Neural Networks Deep Dive',
      instructor: 'Dr. Mohamed Ali',
      time: 'Tomorrow, 4:00 PM',
      duration: '120 min',
      status: SessionStatus.now,
      category: 'AI & Machine Learning',
      description: 'Deep dive into neural network architectures and implementations.',
    ),
  ];

  List<LiveSession> get _filteredSessions {
    if (_selectedFilter == 'All') return _sessions;
    if (_selectedFilter == 'Live Now') {
      return _sessions.where((s) => s.status == SessionStatus.now).toList();
    }
    if (_selectedFilter == 'Upcoming') {
      return _sessions.where((s) => s.status == SessionStatus.upcoming).toList();
    }
    if (_selectedFilter == 'Recorded') {
      return _sessions.where((s) => s.status == SessionStatus.recorded).toList();
    }
    return _sessions;
  }

  void _showSessionDetail(LiveSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SessionDetailModal(
        session: session,
        onSetReminder: () {
          Navigator.pop(context);
          _showSetReminder(session);
        },
        onJoinNow: () {
          Navigator.pop(context);
          // Handle join now
        },
        onWatch: () {
          Navigator.pop(context);
          // Handle watch recorded
        },
      ),
    );
  }

  void _showSetReminder(LiveSession session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SetReminderModal(
        sessionTitle: session.title,
        onSave: (minutes) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reminder set for $minutes minutes before session'),
              backgroundColor: const Color(0xFF4A68F6),
            ),
          );
        },
        onCancel: () {
          Navigator.pop(context);
        },
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
          _buildFilterTabs(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredSessions.length,
              itemBuilder: (context, index) {
                return _buildSessionCard(_filteredSessions[index]);
              },
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
          colors: [Color(0xFF3451E5), Color(0xFF5A75FF), Color(0xFF7B93FF)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
              child: Column(
                children: [
                  const Text(
                    'Live Sessions',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Live Now', 'Upcoming', 'Recorded'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF4A68F6) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF4A68F6) : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF6B7280),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSessionCard(LiveSession session) {
    return GestureDetector(
      onTap: () => _showSessionDetail(session),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F1F1)),
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
                _buildStatusBadge(session.status),
                const Spacer(),
                const FaIcon(
                  FontAwesomeIcons.towerBroadcast,
                  color: Color(0xFF5A75FF),
                  size: 18,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              session.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              session.instructor,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${session.time} • ${session.duration}',
              style: TextStyle(
                color: const Color(0xFF9CA3AF),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 16),
            _buildActionButtons(session),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(SessionStatus status) {
    Color bgColor;
    Color textColor;
    String label;
    Color dotColor;

    switch (status) {
      case SessionStatus.now:
        bgColor = const Color(0xFFFFF0F0);
        textColor = const Color(0xFFFF4B4B);
        label = 'NOW';
        dotColor = const Color(0xFFFF4B4B);
        break;
      case SessionStatus.upcoming:
        bgColor = const Color(0xFFFFF9F0);
        textColor = const Color(0xFFF2994A);
        label = 'UPCOMING';
        dotColor = const Color(0xFFF2994A);
        break;
      case SessionStatus.recorded:
        bgColor = const Color(0xFFF0F2FF);
        textColor = const Color(0xFF5A75FF);
        label = 'RECORDED';
        dotColor = const Color(0xFF5A75FF);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(LiveSession session) {
    if (session.status == SessionStatus.now) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _showSessionDetail(session),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2DBC77),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: const Text(
            'JOIN LIVE',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
    } else if (session.status == SessionStatus.upcoming) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showSessionDetail(session),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showSetReminder(session),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5A75FF),
                side: const BorderSide(color: Color(0xFF5A75FF)),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Set Reminder',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      // Recorded
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showSessionDetail(session),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6B7280),
                side: const BorderSide(color: Color(0xFFD1D5DB)),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _showSessionDetail(session),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF5A75FF),
                side: const BorderSide(color: Color(0xFF5A75FF)),
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Watch',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }
  }
}
