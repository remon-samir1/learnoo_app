import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'summary_detail_screen.dart';

class SummariesListScreen extends StatefulWidget {
  const SummariesListScreen({super.key});

  @override
  State<SummariesListScreen> createState() => _SummariesListScreenState();
}

class _SummariesListScreenState extends State<SummariesListScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Summaries', 'Highlights', 'Video'];

  final List<Map<String, dynamic>> _items = [
    {
      'title': 'Chapter 4 Summary',
      'type': 'Summary',
      'typeColor': const Color(0xFFF2994A),
      'typeBgColor': const Color(0xFFFFF4E6),
      'subject': 'Cost Accounting',
      'preview': 'Key concepts: Fixed costs remain constant regardless of production volume. Variable...',
      'date': 'Today',
      'icon': FontAwesomeIcons.fileLines,
      'iconColor': const Color(0xFFF2994A),
      'iconBgColor': const Color(0xFFFFF4E6),
    },
    {
      'title': 'Key Formulas',
      'type': 'Highlight',
      'typeColor': const Color(0xFF10B981),
      'typeBgColor': const Color(0xFFE6F9F1),
      'subject': 'Statistics for Business',
      'preview': 'Mean = Σ(x)/n, Standard Deviation = √[Σ(x-μ)²/n], Variance = σ²...',
      'date': 'Yesterday',
      'icon': FontAwesomeIcons.highlighter,
      'iconColor': const Color(0xFF10B981),
      'iconBgColor': const Color(0xFFE6F9F1),
    },
    {
      'title': 'Lecture 8 Notes',
      'type': 'Video Note',
      'typeColor': const Color(0xFF5A75FF),
      'typeBgColor': const Color(0xFFEEF0FF),
      'subject': 'Monetary Economics',
      'preview': 'Monetary policy tools: Open market operations, discount rate, reserve...',
      'date': '2 days ago',
      'icon': FontAwesomeIcons.video,
      'iconColor': const Color(0xFF5A75FF),
      'iconBgColor': const Color(0xFFEEF0FF),
    },
    {
      'title': 'Exam Prep Highlights',
      'type': 'Highlight',
      'typeColor': const Color(0xFF10B981),
      'typeBgColor': const Color(0xFFE6F9F1),
      'subject': 'Business Administration',
      'preview': 'SWOT Analysis framework: Strengths, Weaknesses, Opportunities, Threats.',
      'date': '3 days ago',
      'icon': FontAwesomeIcons.highlighter,
      'iconColor': const Color(0xFF10B981),
      'iconBgColor': const Color(0xFFE6F9F1),
    },
    {
      'title': 'Cost Types Overview',
      'type': 'Summary',
      'typeColor': const Color(0xFFF2994A),
      'typeBgColor': const Color(0xFFFFF4E6),
      'subject': 'Cost Accounting',
      'preview': 'Direct costs: Materials, Labor. Indirect costs: Overhead, Administrative expenses...',
      'date': '1 week ago',
      'icon': FontAwesomeIcons.fileLines,
      'iconColor': const Color(0xFFF2994A),
      'iconBgColor': const Color(0xFFFFF4E6),
    },
    {
      'title': 'Market Structures',
      'type': 'Video Note',
      'typeColor': const Color(0xFF5A75FF),
      'typeBgColor': const Color(0xFFEEF0FF),
      'subject': 'Monetary Economics',
      'preview': 'Perfect competition, Monopoly, Oligopoly, Monopolistic competition characteristics...',
      'date': '1 week ago',
      'icon': FontAwesomeIcons.video,
      'iconColor': const Color(0xFF5A75FF),
      'iconBgColor': const Color(0xFFEEF0FF),
    },
  ];

  List<Map<String, dynamic>> get _filteredItems {
    if (_selectedFilter == 'All') return _items;
    if (_selectedFilter == 'Video') {
      return _items.where((item) => item['type'] == 'Video Note').toList();
    }
    return _items.where((item) => item['type'] == _selectedFilter).toList();
  }

  void _navigateToSummaryDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryDetailScreen(
          title: item['title'],
          subject: item['subject'],
          type: item['type'],
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSearchBar(),
                  const SizedBox(height: 20),
                  _buildFilterChips(),
                  const SizedBox(height: 20),
                  _buildItemsList(),
                  const SizedBox(height: 20),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B7BFF),
            Color(0xFF5A75FF),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const Expanded(
                child: Text(
                  'New Summaries',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.search,
            color: Color(0xFF9CA3AF),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search notes...',
                hintStyle: TextStyle(
                  color: const Color(0xFF9CA3AF).withValues(alpha: 0.8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Row(
      children: _filters.map((filter) {
        final isSelected = _selectedFilter == filter;
        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF5A75FF) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF5A75FF) : const Color(0xFFE5E7EB),
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemsList() {
    return Column(
      children: _filteredItems.map((item) {
        return _buildItemCard(item);
      }).toList(),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _navigateToSummaryDetail(item),
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
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item['iconBgColor'],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: FaIcon(
                      item['icon'],
                      color: item['iconColor'],
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item['typeBgColor'],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item['type'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: item['typeColor'],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item['subject'],
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item['preview'],
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              item['date'],
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
