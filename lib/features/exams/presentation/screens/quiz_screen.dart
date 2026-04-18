import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../data/exam_repository.dart';
import '../../models/quiz_models.dart';
import 'exam_results_screen.dart';
import '../../../../core/widgets/watermark_wrapper.dart';
import '../../../../core/services/feature_manager.dart';
import '../../../../core/services/screen_protection_service.dart';
import '../../../auth/data/auth_repository.dart';

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
  final ScreenProtectionService _screenProtection = ScreenProtectionService();
  int _currentQuestionIndex = 0;
  int _remainingSeconds = 0;
  Timer? _timer;
  List<QuizQuestion> _questions = [];
  Map<int, List<QuizAnswer>> _answersMap = {}; // questionId -> answers
  bool _isLoading = true;
  bool _isSubmitting = false;

  // User info for watermark
  String _userName = '';
  String _userId = '';
  bool _showWatermark = true;
  final FeatureManager _featureManager = FeatureManager();
  final AuthRepository _authRepository = AuthRepository();

  // Exam protection state
  bool _isAppPaused = false;
  int _pauseCount = 0;
  DateTime? _lastPauseTime;
  static const int maxAllowedPauses = 1; // Maximum allowed app switches before auto-submit

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _remainingSeconds = widget.quiz.duration * 60;
    _initializeProtection();
    _loadQuestions();
    _loadUserData();
    _startTimer();
  }

  Future<void> _loadUserData() async {
    final result = await _authRepository.getProfile();
    if (result['success'] && mounted) {
      final attributes = result['data']['attributes'] ?? {};
      final firstName = attributes['first_name']?.toString() ?? '';
      final lastName = attributes['last_name']?.toString() ?? '';
      final userId = result['data']['id']?.toString() ?? '';
      setState(() {
        _userName = '$firstName $lastName'.trim();
        _userId = userId;
      });
    }
  }

  Future<void> _initializeProtection() async {
    // Initialize screen protection service
    await _screenProtection.initialize();
    // Enable global protection (FLAG_SECURE on Android, iOS protection)
    await _screenProtection.enableGlobalProtection();
  }

  Future<void> _loadQuestions() async {
    // Load questions
    final questionResult = await _examRepository.getQuizQuestions(widget.quiz.quizId);
    if (!mounted) return;

    if (questionResult['success']) {
      final questions = questionResult['data'] as List<QuizQuestion>;
      setState(() {
        _questions = questions;
        // Map questions to their answers from the nested data
        for (final question in questions) {
          _answersMap[question.questionId] = question.answers;
        }
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    // Disable global protection when leaving exam
    _screenProtection.disableGlobalProtection();
    super.dispose();
  }

  // Handle app lifecycle changes for exam protection
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || 
        state == AppLifecycleState.detached || 
        state == AppLifecycleState.inactive) {
      // User attempted to leave the app
      _handleAppPause();
    } else if (state == AppLifecycleState.resumed) {
      // User returned to the app
      _handleAppResume();
    }
  }

  void _handleAppPause() {
    if (_isSubmitting) return;
    
    _pauseCount++;
    _lastPauseTime = DateTime.now();
    
    setState(() {
      _isAppPaused = true;
    });

    // Auto-submit if user has paused too many times
    if (_pauseCount > maxAllowedPauses) {
      _showViolationAndSubmit('exam.violation_multiple_leaves'.tr());
      return;
    }

    // Show warning overlay but don't auto-submit immediately on first pause
    // This gives user a chance to return immediately
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isAppPaused && !_isSubmitting) {
        // If still paused after 3 seconds, auto-submit
        _showViolationAndSubmit('exam.violation_auto_submit'.tr());
      }
    });
  }

  void _handleAppResume() {
    if (_isSubmitting) return;
    
    setState(() {
      _isAppPaused = false;
    });

    // If user returned quickly (within 3 seconds), show warning but continue
    if (_lastPauseTime != null) {
      final pauseDuration = DateTime.now().difference(_lastPauseTime!);
      if (pauseDuration.inSeconds < 3 && _pauseCount <= maxAllowedPauses) {
        _showWarningDialog();
      }
    }
  }

  void _showWarningDialog() {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text('exam.warning_title'.tr()),
          ],
        ),
        content: Text(
          'exam.leave_warning'.tr(namedArgs: {
            'count': _pauseCount.toString(),
            'max': maxAllowedPauses.toString(),
          }),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3343D6)),
            child: Text('exam.continue_exam'.tr()),
          ),
        ],
      ),
    );
  }

  void _showViolationAndSubmit(String message) {
    if (!mounted || _isSubmitting) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Text('exam.violation_title'.tr()),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _autoSubmit();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('exam.ok'.tr()),
          ),
        ],
      ),
    );
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

    // Prevent back button - show warning instead
    final shouldExit = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text('exam.exit_title'.tr()),
          ],
        ),
        content: Text('exam.exit_warning'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('exam.stay'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('exam.leave_submit'.tr()),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      _autoSubmit();
      return false; // Let the submission handle navigation
    }
    return false; // Always return false to prevent immediate pop
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
      child: Stack(
        children: [
          Scaffold(
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
                // Options - Scrollable area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (answers.isEmpty)
                          const Center(child: CircularProgressIndicator())
                        else
                          ...answers.map((answer) {
                            final isSelected = currentQuestion.selectedAnswerId == answer.answerId;
                            return _buildOptionCard(answer.text, isSelected, answer.answerId);
                          }),
                        const SizedBox(height: 24),
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
                      ],
                    ),
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
        // Watermark overlay for exam protection - controlled by API
        WatermarkWrapper(
          type: WatermarkType.exams,
          studentCode: _userId.isNotEmpty ? _userId : null,
          featureManager: _featureManager,
          child: Container(), // Empty child as the watermark is positioned fill
        ),
        // Pause blocking overlay - prevents viewing content when app is paused
        if (_isAppPaused)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.circlePause,
                      color: Colors.white,
                      size: 64,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'exam.paused_title'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'exam.paused_message'.tr(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_pauseCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.withOpacity(0.5)),
                        ),
                        child: Text(
                          'exam.warning_count'.tr(namedArgs: {
                            'count': _pauseCount.toString(),
                            'max': maxAllowedPauses.toString(),
                          }),
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
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
