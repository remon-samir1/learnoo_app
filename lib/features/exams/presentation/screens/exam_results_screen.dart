import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../home/presentation/screens/main_screen.dart';
import '../../models/quiz_models.dart';

class ExamResultsScreen extends StatelessWidget {
  final QuizResult result;

  const ExamResultsScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Trophy Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: result.passed ? const Color(0xFF27AE60) : const Color(0xFFF2994A),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FaIcon(
                    result.passed ? FontAwesomeIcons.trophy : FontAwesomeIcons.rotateRight,
                    color: Colors.white,
                    size: 44,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Congratulations Text
              Text(
                result.passed ? 'Congratulations!' : 'Good Try!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1F2937)),
              ),
              const SizedBox(height: 8),
              Text(
                result.passed ? 'You passed the exam!' : 'Keep practicing!',
                style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)),
              ),
              const SizedBox(height: 32),
              // Score Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    Text('${result.percentage.toInt()}%', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                    const SizedBox(height: 8),
                    Text('${result.correctAnswers} out of ${result.totalQuestions} correct', style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
                    const SizedBox(height: 8),
                    Text('Score: ${result.score} / ${result.totalScore}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF3343D6))),
                    const SizedBox(height: 24),
                    // Circular Progress
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: result.percentage / 100,
                            strokeWidth: 10,
                            backgroundColor: const Color(0xFFE5E7EB),
                            valueColor: AlwaysStoppedAnimation<Color>(result.passed ? const Color(0xFF27AE60) : const Color(0xFFF2994A)),
                          ),
                          Center(
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: result.passed ? const Color(0xFF27AE60) : const Color(0xFFF2994A),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: FaIcon(
                                  result.passed ? FontAwesomeIcons.check : FontAwesomeIcons.arrowTrendUp,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Back to Home Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3343D6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const FaIcon(FontAwesomeIcons.house, size: 16),
                  label: const Text('Back to Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),
              // Review Button
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
                  child: const Text('Back to Exams', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
