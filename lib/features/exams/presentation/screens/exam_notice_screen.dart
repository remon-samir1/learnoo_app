import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../data/exam_repository.dart';
import '../../models/quiz_models.dart';
import 'quiz_screen.dart';

class ExamNoticeScreen extends StatelessWidget {
  final Quiz quiz;

  const ExamNoticeScreen({
    super.key,
    required this.quiz,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF6B73FF), Color(0xFF5A6AF0)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: FaIcon(FontAwesomeIcons.triangleExclamation, color: Colors.white, size: 36),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Important Notice', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
              const SizedBox(height: 8),
              const Text('Please read carefully before starting', style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
              const SizedBox(height: 32),
              // Quiz Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F1F1)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(quiz.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                    const SizedBox(height: 20),
                    _buildDetailRow('Type', quiz.type.toUpperCase()),
                    const Divider(height: 16, color: Color(0xFFF1F1F1)),
                    _buildDetailRow('Duration', '${quiz.duration} min'),
                    const Divider(height: 16, color: Color(0xFFF1F1F1)),
                    _buildDetailRow('Max Attempts', '${quiz.maxAttempts}'),
                    if (quiz.chapter != null) ...[
                      const Divider(height: 16, color: Color(0xFFF1F1F1)),
                      _buildDetailRow('Chapter', quiz.chapter!.title),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Exam Rules Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F1F1)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Exam Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                    const SizedBox(height: 16),
                    _buildRuleItem(FontAwesomeIcons.eye, const Color(0xFFFF4B4B), 'You cannot leave the exam once started'),
                    const SizedBox(height: 12),
                    _buildRuleItem(FontAwesomeIcons.ban, const Color(0xFFF2994A), 'Switching apps or tabs will auto-submit'),
                    const SizedBox(height: 12),
                    _buildRuleItem(FontAwesomeIcons.clock, const Color(0xFF5A75FF), 'Timer will start automatically'),
                    const SizedBox(height: 12),
                    _buildRuleItem(FontAwesomeIcons.fileSignature, const Color(0xFF9B59B6), 'All questions must be answered'),
                    const SizedBox(height: 12),
                    _buildRuleItem(FontAwesomeIcons.rotateRight, const Color(0xFF27AE60), 'Each attempt counts - use wisely'),
                  ],
                ),
              ),
              const Spacer(),
              // Start Exam Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _startExam(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3343D6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('START EXAM', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              // Go Back Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Go Back', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startExam(BuildContext context) async {
    final examRepo = ExamRepository();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Start the attempt
    final result = await examRepo.startQuizAttempt(quiz.quizId);

    if (!context.mounted) return;
    Navigator.pop(context); // Remove loading

    if (result['success']) {
      final attempt = result['data'] as QuizAttempt;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => QuizScreen(quiz: quiz, attempt: attempt),
        ),
      );
    } else {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to start exam'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937))),
      ],
    );
  }

  Widget _buildRuleItem(dynamic icon, Color iconColor, String text) {
    return Row(
      children: [
        FaIcon(icon, size: 16, color: iconColor),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563)))),
      ],
    );
  }
}
