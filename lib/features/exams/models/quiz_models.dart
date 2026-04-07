// Quiz/Exam Models matching API response structure

// Quiz/Exam Model
class Quiz {
  final String id;
  final int quizId;
  final String title;
  final int maxAttempts;
  final String type; // 'exam' or 'homework'
  final DateTime startTime;
  final DateTime endTime;
  final int duration; // in minutes
  final int? chapterId;
  final Chapter? chapter;
  final int courseId;
  final DateTime createdAt;

  Quiz({
    required this.id,
    required this.quizId,
    required this.title,
    required this.maxAttempts,
    required this.type,
    required this.startTime,
    required this.endTime,
    required this.duration,
    this.chapterId,
    this.chapter,
    required this.courseId,
    required this.createdAt,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? {};
    final chapterData = attributes['chapter']?['data'];

    return Quiz(
      id: json['id']?.toString() ?? '',
      quizId: attributes['id'] ?? 0,
      title: attributes['title'] ?? '',
      maxAttempts: attributes['max_attempts'] ?? 1,
      type: attributes['type'] ?? 'exam',
      startTime: DateTime.tryParse(attributes['start_time'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(attributes['end_time'] ?? '') ?? DateTime.now(),
      duration: attributes['duration'] ?? 0,
      chapterId: attributes['chapter_id'],
      chapter: chapterData != null ? Chapter.fromJson(chapterData) : null,
      courseId: attributes['course_id'] ?? 0,
      createdAt: DateTime.tryParse(attributes['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Check if quiz is currently available based on start/end time
  bool get isAvailable {
    final now = DateTime.now().toUtc();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  // Check if quiz has expired
  bool get isExpired {
    final now = DateTime.now().toUtc();
    return now.isAfter(endTime);
  }
}

// Chapter Model (nested in quiz response)
class Chapter {
  final String id;
  final int chapterId;
  final int lectureId;
  final String title;
  final String thumbnail;
  final String duration;
  final bool isFreePreview;
  final int maxViews;
  final int currentUserViews;
  final bool isActivated;
  final bool isLocked;
  final bool canWatch;
  final DateTime createdAt;
  final DateTime updatedAt;

  Chapter({
    required this.id,
    required this.chapterId,
    required this.lectureId,
    required this.title,
    required this.thumbnail,
    required this.duration,
    required this.isFreePreview,
    required this.maxViews,
    required this.currentUserViews,
    required this.isActivated,
    required this.isLocked,
    required this.canWatch,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? {};

    return Chapter(
      id: json['id']?.toString() ?? '',
      chapterId: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      lectureId: attributes['lecture_id'] ?? 0,
      title: attributes['title'] ?? '',
      thumbnail: attributes['thumbnail'] ?? '',
      duration: attributes['duration'] ?? '',
      isFreePreview: attributes['is_free_preview'] ?? false,
      maxViews: attributes['max_views'] ?? 0,
      currentUserViews: attributes['current_user_views'] ?? 0,
      isActivated: attributes['is_activated'] ?? false,
      isLocked: attributes['is_locked'] ?? false,
      canWatch: attributes['can_watch'] ?? false,
      createdAt: DateTime.tryParse(attributes['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(attributes['updated_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// Quiz Question Model
class QuizQuestion {
  final String id;
  final int questionId;
  final int quizId;
  final String text;
  final int score;
  final String type; // 'multiple_choice'
  final bool autoCorrect;
  final DateTime createdAt;
  List<QuizAnswer> answers;
  int? selectedAnswerId;

  QuizQuestion({
    required this.id,
    required this.questionId,
    required this.quizId,
    required this.text,
    required this.score,
    required this.type,
    required this.autoCorrect,
    required this.createdAt,
    this.answers = const [],
    this.selectedAnswerId,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? {};

    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      questionId: attributes['id'] ?? 0,
      quizId: attributes['quiz_id'] ?? 0,
      text: attributes['text'] ?? '',
      score: attributes['score'] ?? 0,
      type: attributes['type'] ?? 'multiple_choice',
      autoCorrect: attributes['auto_correct'] ?? true,
      createdAt: DateTime.tryParse(attributes['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// Quiz Answer Model
class QuizAnswer {
  final String id;
  final int answerId;
  final int quizQuestionId;
  final String text;
  final bool isCorrect;
  final DateTime createdAt;

  QuizAnswer({
    required this.id,
    required this.answerId,
    required this.quizQuestionId,
    required this.text,
    required this.isCorrect,
    required this.createdAt,
  });

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? {};

    return QuizAnswer(
      id: json['id']?.toString() ?? '',
      answerId: attributes['id'] ?? 0,
      quizQuestionId: attributes['quiz_question_id'] ?? 0,
      text: attributes['text'] ?? '',
      isCorrect: attributes['is_correct'] ?? false,
      createdAt: DateTime.tryParse(attributes['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

// Quiz Attempt Model
class QuizAttempt {
  final String id;
  final String userId;
  final int quizId;
  final int score;
  final int totalScore;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;

  QuizAttempt({
    required this.id,
    required this.userId,
    required this.quizId,
    required this.score,
    required this.totalScore,
    required this.startedAt,
    this.finishedAt,
    required this.createdAt,
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    final attributes = json['attributes'] ?? {};

    return QuizAttempt(
      id: json['id']?.toString() ?? '',
      userId: attributes['user_id']?.toString() ?? '',
      quizId: attributes['quiz_id'] ?? 0,
      score: attributes['score'] ?? 0,
      totalScore: attributes['total_score'] ?? 0,
      startedAt: DateTime.tryParse(attributes['started_at'] ?? '') ?? DateTime.now(),
      finishedAt: DateTime.tryParse(attributes['finished_at'] ?? ''),
      createdAt: DateTime.tryParse(attributes['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  double get percentage => totalScore > 0 ? (score / totalScore) * 100 : 0;
  bool get isCompleted => finishedAt != null;
}

// Quiz Result for local use
class QuizResult {
  final String quizId;
  final String quizTitle;
  final int score;
  final int totalScore;
  final double percentage;
  final int correctAnswers;
  final int totalQuestions;
  final bool passed;
  final DateTime completedAt;

  QuizResult({
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalScore,
    required this.percentage,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.passed,
    required this.completedAt,
  });
}

// Legacy classes for backward compatibility
class Exam {
  final String id;
  final String title;
  final String subject;
  final int questionCount;
  final int durationMinutes;
  final DateTime date;
  final String startTime;
  final ExamStatus status;
  final List<Question> questions;
  final String? description;

  Exam({
    required this.id,
    required this.title,
    required this.subject,
    required this.questionCount,
    required this.durationMinutes,
    required this.date,
    required this.startTime,
    required this.status,
    required this.questions,
    this.description,
  });
}

enum ExamStatus { upcoming, available, completed, notAvailable }

class Question {
  final String id;
  final int number;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  String? selectedAnswer;

  Question({
    required this.id,
    required this.number,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    this.selectedAnswer,
  });
}

class ExamResult {
  final String examId;
  final String examTitle;
  final double percentage;
  final int correctAnswers;
  final int totalQuestions;
  final int score;
  final int totalScore;
  final bool passed;
  final List<ChapterPerformance> chapterPerformance;

  ExamResult({
    required this.examId,
    required this.examTitle,
    required this.percentage,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.score,
    required this.totalScore,
    required this.passed,
    required this.chapterPerformance,
  });
}

class ChapterPerformance {
  final String chapterName;
  final double percentage;
  final bool needsImprovement;

  ChapterPerformance({
    required this.chapterName,
    required this.percentage,
    this.needsImprovement = false,
  });
}
