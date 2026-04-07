import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/exam_repository.dart';
import '../../models/quiz_models.dart';
import 'exam_notice_screen.dart';

class ExamsListScreen extends StatefulWidget {
  const ExamsListScreen({super.key});

  @override
  State<ExamsListScreen> createState() => _ExamsListScreenState();
}

class _ExamsListScreenState extends State<ExamsListScreen> {
  final ExamRepository _examRepository = ExamRepository();
  List<Quiz> _quizzes = [];
  Map<int, int> _remainingAttempts = {};
  Map<int, List<QuizAttempt>> _attemptsMap = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _examRepository.getQuizzes();
    if (!mounted) return;

    if (result['success']) {
      final quizzes = result['data'] as List<Quiz>;
      setState(() {
        _quizzes = quizzes;
      });

      for (final quiz in quizzes) {
        await _loadAttemptsForQuiz(quiz.quizId, quiz.maxAttempts);
      }
    } else {
      setState(() {
        _errorMessage = result['message'];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAttemptsForQuiz(int quizId, int maxAttempts) async {
    final result = await _examRepository.getRemainingAttempts(quizId, maxAttempts);
    if (!mounted) return;

    if (result['success']) {
      setState(() {
        _remainingAttempts[quizId] = result['remainingAttempts'];
        _attemptsMap[quizId] = result['attempts'] as List<QuizAttempt>;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6B73FF), Color(0xFF5A6AF0)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Quizzes & Exams',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _errorMessage != null
                          ? _buildErrorView()
                          : _quizzes.isEmpty
                              ? _buildEmptyView()
                              : RefreshIndicator(
                                  onRefresh: _loadQuizzes,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: _quizzes.length,
                                    itemBuilder: (context, index) {
                                      final quiz = _quizzes[index];
                                      final remaining = _remainingAttempts[quiz.quizId] ?? quiz.maxAttempts;
                                      return _buildQuizCard(context, quiz, remaining);
                                    },
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

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(FontAwesomeIcons.circleExclamation, size: 48, color: Colors.white),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadQuizzes,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF5A6AF0)),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.clipboardList, size: 48, color: Colors.white70),
          SizedBox(height: 16),
          Text('No quizzes available', style: TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildQuizCard(BuildContext context, Quiz quiz, int remainingAttempts) {
    final isAvailable = quiz.isAvailable && remainingAttempts > 0;
    final isExpired = quiz.isExpired;
    final hasNoAttempts = remainingAttempts <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildTypeBadge(quiz.type), _buildStatusBadge(quiz, remainingAttempts)],
            ),
            const SizedBox(height: 12),
            Text(quiz.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
            const SizedBox(height: 12),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.clock, size: 14, color: AppColors.textGray.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text('${quiz.duration} Minutes', style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
                const SizedBox(width: 16),
                FaIcon(FontAwesomeIcons.calendar, size: 14, color: AppColors.textGray.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Expanded(child: Text(_formatDateRange(quiz.startTime, quiz.endTime), style: const TextStyle(fontSize: 12, color: AppColors.textGray), overflow: TextOverflow.ellipsis)),
              ],
            ),
            if (quiz.chapter != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  FaIcon(FontAwesomeIcons.book, size: 14, color: AppColors.textGray.withValues(alpha: 0.7)),
                  const SizedBox(width: 6),
                  Expanded(child: Text('Chapter: ${quiz.chapter!.title}', style: const TextStyle(fontSize: 12, color: AppColors.textGray), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.rotateRight, size: 14, color: hasNoAttempts ? Colors.red : AppColors.textGray.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text('Attempts: $remainingAttempts/${quiz.maxAttempts}', style: TextStyle(fontSize: 12, color: hasNoAttempts ? Colors.red : AppColors.textGray, fontWeight: hasNoAttempts ? FontWeight.w600 : FontWeight.normal)),
              ],
            ),
            const SizedBox(height: 16),
            _buildActionButton(context, quiz, isAvailable, isExpired, hasNoAttempts),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final isExam = type == 'exam';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: isExam ? const Color(0xFFFFF0F0) : const Color(0xFFE6F7F0), borderRadius: BorderRadius.circular(20)),
      child: Text(isExam ? 'EXAM' : 'HOMEWORK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isExam ? const Color(0xFFFF4B4B) : const Color(0xFF27AE60))),
    );
  }

  Widget _buildStatusBadge(Quiz quiz, int remainingAttempts) {
    String text;
    Color bgColor;
    Color textColor;

    if (quiz.isExpired) {
      text = 'Expired';
      bgColor = const Color(0xFFF5F5F5);
      textColor = AppColors.textGray;
    } else if (remainingAttempts <= 0) {
      text = 'No Attempts';
      bgColor = const Color(0xFFFFF0F0);
      textColor = const Color(0xFFFF4B4B);
    } else if (quiz.isAvailable) {
      text = 'Available Now';
      bgColor = const Color(0xFFE6F7F0);
      textColor = const Color(0xFF27AE60);
    } else {
      text = 'Upcoming';
      bgColor = const Color(0xFFFFF4E6);
      textColor = const Color(0xFFF2994A);
    }

    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)));
  }

  Widget _buildActionButton(BuildContext context, Quiz quiz, bool isAvailable, bool isExpired, bool hasNoAttempts) {
    if (isExpired) return _buildDisabledButton('Exam Expired');
    if (hasNoAttempts) return _buildDisabledButton('No Attempts Remaining');

    if (isAvailable) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ExamNoticeScreen(quiz: quiz))).then((_) => _loadAttemptsForQuiz(quiz.quizId, quiz.maxAttempts));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          child: const Text('START EXAM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );
    } else {
      return _buildDisabledButton('Not Available Yet');
    }
  }

  Widget _buildDisabledButton(String text) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(12)),
        child: Center(child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textGray))),
      ),
    );
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final startStr = '${months[start.month - 1]} ${start.day}';
    final endStr = '${months[end.month - 1]} ${end.day}';
    return '$startStr - $endStr';
  }
}
