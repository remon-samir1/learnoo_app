import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
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
  Map<int, int>  _remainingAttempts = {};
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

      final attemptsFutures = quizzes.map((quiz) => 
        _loadAttemptsForQuiz(quiz.quizId, quiz.maxAttempts)
      ).toList();
      await Future.wait(attemptsFutures);
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
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'exams.title'.tr(),
                      style: const TextStyle(
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
                      ? _buildSkeletonList()
                      : _errorMessage != null
                          ? _buildErrorView()
                          : RefreshIndicator(
                              onRefresh: _loadQuizzes,
                              child: _quizzes.isEmpty
                                  ? LayoutBuilder(
                                      builder: (context, constraints) {
                                        return SingleChildScrollView(
                                          physics: const AlwaysScrollableScrollPhysics(),
                                          child: ConstrainedBox(
                                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                            child: _buildEmptyView(),
                                          ),
                                        );
                                      },
                                    )
                                  : ListView.builder(
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
            child: Text('exams.retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.clipboardList, size: 48, color: AppColors.textGray.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('exams.no_quizzes'.tr(), style: const TextStyle(color: AppColors.textGray, fontSize: 16)),
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
                Text('course.duration_min'.tr(args: [quiz.duration.toString()]), style: const TextStyle(fontSize: 12, color: AppColors.textGray)),
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
                  Expanded(child: Text('exams.chapter_prefix'.tr(args: [quiz.chapter!.title]), style: const TextStyle(fontSize: 12, color: AppColors.textGray), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                FaIcon(FontAwesomeIcons.rotateRight, size: 14, color: hasNoAttempts ? Colors.red : AppColors.textGray.withValues(alpha: 0.7)),
                const SizedBox(width: 6),
                Text('exams.attempts_count'.tr(args: [remainingAttempts.toString(), quiz.maxAttempts.toString()]), style: TextStyle(fontSize: 12, color: hasNoAttempts ? Colors.red : AppColors.textGray, fontWeight: hasNoAttempts ? FontWeight.w600 : FontWeight.normal)),
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
      child: Text(isExam ? 'exams.badge_exam'.tr() : 'exams.badge_homework'.tr(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isExam ? const Color(0xFFFF4B4B) : const Color(0xFF27AE60))),
    );
  }

  Widget _buildStatusBadge(Quiz quiz, int remainingAttempts) {
    String text;
    Color bgColor;
    Color textColor;

    if (quiz.isExpired) {
      text = 'exams.status_expired'.tr();
      bgColor = const Color(0xFFF5F5F5);
      textColor = AppColors.textGray;
    } else if (remainingAttempts <= 0) {
      text = 'exams.status_no_attempts'.tr();
      bgColor = const Color(0xFFFFF0F0);
      textColor = const Color(0xFFFF4B4B);
    } else if (quiz.isAvailable) {
      text = 'exams.status_available'.tr();
      bgColor = const Color(0xFFE6F7F0);
      textColor = const Color(0xFF27AE60);
    } else {
      text = 'exams.status_upcoming'.tr();
      bgColor = const Color(0xFFFFF4E6);
      textColor = const Color(0xFFF2994A);
    }

    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20)), child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: textColor)));
  }

  Widget _buildActionButton(BuildContext context, Quiz quiz, bool isAvailable, bool isExpired, bool hasNoAttempts) {
    if (isExpired) return _buildDisabledButton('exams.btn_exam_expired'.tr());
    if (hasNoAttempts) return _buildDisabledButton('exams.btn_no_attempts'.tr());

    if (isAvailable) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ExamNoticeScreen(quiz: quiz))).then((_) => _loadAttemptsForQuiz(quiz.quizId, quiz.maxAttempts));
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          child: Text('exams.btn_start_exam'.tr(), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      );
    } else {
      return _buildDisabledButton('exams.btn_not_available'.tr());
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

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (context, index) => _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row - badges
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(width: 80, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                Container(width: 100, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
              ],
            ),
            const SizedBox(height: 16),
            // Title
            Container(width: double.infinity, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 8),
            Container(width: 200, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
            const SizedBox(height: 16),
            // Info rows
            Row(
              children: [
                Container(width: 100, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                const SizedBox(width: 16),
                Container(width: 120, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              ],
            ),
            const SizedBox(height: 8),
            Container(width: 180, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            // Button
            Container(width: double.infinity, height: 46, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
          ],
        ),
      ),
    );
  }
}
