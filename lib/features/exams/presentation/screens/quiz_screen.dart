import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/exam_repository.dart';
import '../../models/quiz_models.dart';
import 'exam_results_screen.dart';

class QuizScreen extends StatefulWidget {
  final Quiz quiz;
  final QuizAttempt attempt;

  const QuizScreen({
    super.key,
    required this.quiz,
    required this.attempt,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> with WidgetsBindingObserver {
  final ExamRepository _examRepository = ExamRepository();
  int _currentQuestionIndex = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  List<QuizQuestion> _questions = [];
  Map<int, List<QuizAnswer>> _answersMap = {}; // questionId -> answers
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = widget.quiz.duration * 60;
    _loadQuestions();
    _startTimer();
  }

  Future<void> _loadQuestions() async {
    // Load questions
    final questionResult = await _examRepository.getQuizQuestions(widget.quiz.quizId);
    if (!mounted) return;

    if (questionResult['success']) {
      final questions = questionResult['data'] as List<QuizQuestion>;
      setState(() {
        _questions = questions;
      });

      // Load answers for each question
      for (final question in questions) {
        final answerResult = await _examRepository.getQuizAnswers(questionId: question.questionId);
        if (answerResult['success'] && mounted) {
          setState(() {
            _answersMap[question.questionId] = answerResult['data'] as List<QuizAnswer>;
          });
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  // Handle app lifecycle changes for auto-submit
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached || 
        state == AppLifecycleState.inactive) {
      // User left the app - auto submit
      _autoSubmit();
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          _submitExam();
        }
      });
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _selectAnswer(int answerId) {
    setState(() {
      _questions[_currentQuestionIndex].selectedAnswerId = answerId;
    });
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _showSubmitConfirmation();
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _showSubmitConfirmation() {
    // Check if all questions are answered
    final unanswered = _questions.where((q) => q.selectedAnswerId == null).length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Exam?'),
        content: unanswered > 0
            ? Text('You have $unanswered unanswered question(s). Are you sure you want to submit?')
            : const Text('Are you sure you want to submit your exam?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitExam();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3343D6)),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _autoSubmit() {
    if (_isSubmitting) return;
    _submitExam(isAutoSubmit: true);
  }

  Future<void> _submitExam({bool isAutoSubmit = false}) async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });
    _timer?.cancel();

    // Prepare answers
    final answers = <Map<String, dynamic>>[];
    for (final question in _questions) {
      if (question.selectedAnswerId != null) {
        answers.add({
          'question_id': question.questionId,
          'answer_id': question.selectedAnswerId,
        });
      }
    }

    // Submit to API
    final result = await _examRepository.submitQuizAttempt(
      attemptId: int.parse(widget.attempt.id),
      quizId: widget.quiz.quizId,
      answers: answers,
    );

    if (!mounted) return;

    if (result['success']) {
      final attempt = result['data'] as QuizAttempt;

      // Calculate correct answers for display
      int correctAnswers = 0;
      for (final question in _questions) {
        final answers = _answersMap[question.questionId] ?? [];
        final selectedAnswer = answers.firstWhere(
          (a) => a.answerId == question.selectedAnswerId,
          orElse: () => QuizAnswer(id: '', answerId: 0, quizQuestionId: 0, text: '', isCorrect: false, createdAt: DateTime.now()),
        );
        if (selectedAnswer.isCorrect) {
          correctAnswers++;
        }
      }

      final quizResult = QuizResult(
        quizId: widget.quiz.id,
        quizTitle: widget.quiz.title,
        score: attempt.score,
        totalScore: attempt.totalScore,
        percentage: attempt.percentage,
        correctAnswers: correctAnswers,
        totalQuestions: _questions.length,
        passed: attempt.percentage >= 60,
        completedAt: DateTime.now(),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ExamResultsScreen(result: quizResult),
        ),
      );
    } else {
      // Show error and allow retry
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to submit exam'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _submitExam,
            textColor: Colors.white,
          ),
        ),
      );
    }
  }

  Future<bool> _onWillPop() async {
    if (_isSubmitting) return false;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Exam?'),
        content: const Text('If you leave, your exam will be auto-submitted with current answers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Leave & Submit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      _autoSubmit();
      return false; // Let the submission handle navigation
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Loading questions...', style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Exam'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF1F2937),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(FontAwesomeIcons.circleExclamation, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('No questions available', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    final answers = _answersMap[currentQuestion.questionId] ?? [];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Header Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.quiz.title,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                    // Timer
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _remainingSeconds < 60 ? const Color(0xFFFFF0F0) : const Color(0xFFFFF4E6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.clock,
                            size: 14,
                            color: _remainingSeconds < 60 ? const Color(0xFFFF4B4B) : const Color(0xFFF2994A),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formattedTime,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _remainingSeconds < 60 ? const Color(0xFFFF4B4B) : const Color(0xFFF2994A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3343D6)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 32),
                // Question Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: Color(0xFF3343D6), shape: BoxShape.circle),
                        child: Center(
                          child: Text('${_currentQuestionIndex + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentQuestion.text,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1F2937), height: 1.5),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '(${currentQuestion.score} point${currentQuestion.score > 1 ? 's' : ''})',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Options
                if (answers.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  ...answers.map((answer) {
                    final isSelected = currentQuestion.selectedAnswerId == answer.answerId;
                    return _buildOptionCard(answer.text, isSelected, answer.answerId);
                  }),
                const Spacer(),
                // Navigation Row
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE5E7EB))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildNavButton(icon: FontAwesomeIcons.chevronLeft, onTap: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8)),
                        child: Text('${_currentQuestionIndex + 1}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
                      ),
                      const SizedBox(width: 16),
                      _buildNavButton(icon: FontAwesomeIcons.chevronRight, onTap: _goToNextQuestion),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Bottom Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _currentQuestionIndex > 0 ? _goToPreviousQuestion : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _currentQuestionIndex > 0 ? const Color(0xFF9CA3AF) : const Color(0xFFD1D5DB),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: _currentQuestionIndex > 0 ? const Color(0xFFE5E7EB) : const Color(0xFFF3F4F6)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FaIcon(FontAwesomeIcons.chevronLeft, size: 14),
                            SizedBox(width: 8),
                            Text('Previous', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _goToNextQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3343D6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Submit', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 8),
                            const FaIcon(FontAwesomeIcons.chevronRight, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String option, bool isSelected, int answerId) {
    return GestureDetector(
      onTap: _isSubmitting ? null : () => _selectAnswer(answerId),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F2FF) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF3343D6) : const Color(0xFFE5E7EB), width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFF3343D6) : const Color(0xFFD1D5DB), width: 2),
                color: isSelected ? const Color(0xFF3343D6) : Colors.transparent,
              ),
              child: isSelected
                  ? const Center(child: FaIcon(FontAwesomeIcons.check, size: 10, color: Colors.white))
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF3343D6) : const Color(0xFF4B5563),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavButton({required dynamic icon, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(color: onTap != null ? const Color(0xFFF3F4F6) : const Color(0xFFF9FAFB), borderRadius: BorderRadius.circular(8)),
        child: Center(
          child: FaIcon(icon, size: 14, color: onTap != null ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB)),
        ),
      ),
    );
  }
}
