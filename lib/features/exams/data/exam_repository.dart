import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_constants.dart';
import '../models/quiz_models.dart';

class ExamRepository {
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  String _handleError(dynamic data, String defaultMessage) {
    if (data == null) return defaultMessage;

    if (data['message'] != null) {
      return data['message'].toString();
    }

    if (data['errors'] != null && data['errors'] is Map) {
      final errors = data['errors'] as Map<String, dynamic>;
      return errors.values
          .map((e) {
            if (e is List) return e.join(', ');
            return e.toString();
          })
          .join('\n');
    }

    return defaultMessage;
  }

  // Get all quizzes
  Future<Map<String, dynamic>> getQuizzes() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.quiz}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> quizData = data['data'] ?? [];
        final quizzes = quizData.map((q) => Quiz.fromJson(q)).toList();
        return {'success': true, 'data': quizzes};
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to fetch quizzes'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get quiz by ID
  Future<Map<String, dynamic>> getQuizById(int quizId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.quiz}/$quizId');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final quiz = Quiz.fromJson(data['data']);
        return {'success': true, 'data': quiz};
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to fetch quiz'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get questions for a quiz
  Future<Map<String, dynamic>> getQuizQuestions(int quizId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.quizQuestion}?quiz_id=$quizId',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> questionData = data['data'] ?? [];
        final questions = questionData.map((q) => QuizQuestion.fromJson(q)).toList();
        return {'success': true, 'data': questions};
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to fetch quiz questions'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get all answers (for a specific question or all)
  Future<Map<String, dynamic>> getQuizAnswers({int? questionId}) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    var urlString = '${ApiConstants.baseUrl}${ApiConstants.quizAnswer}';
    if (questionId != null) {
      urlString += '?quiz_question_id=$questionId';
    }

    final url = Uri.parse(urlString);
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> answerData = data['data'] ?? [];
        final answers = answerData.map((a) => QuizAnswer.fromJson(a)).toList();
        return {'success': true, 'data': answers};
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to fetch quiz answers'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get attempts for a specific quiz
  Future<Map<String, dynamic>> getQuizAttempts(int quizId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.quizAttempt}?quiz_id=$quizId',
    );
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> attemptData = data['data'] ?? [];
        final attempts = attemptData.map((a) => QuizAttempt.fromJson(a)).toList();
        return {'success': true, 'data': attempts};
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to fetch quiz attempts'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Get all attempts for current user
  Future<Map<String, dynamic>> getAllAttempts() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.quizAttempt}');
    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final List<dynamic> attemptData = data['data'] ?? [];
        final attempts = attemptData.map((a) => QuizAttempt.fromJson(a)).toList();
        return {'success': true, 'data': attempts};
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to fetch attempts'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Start a new quiz attempt
  Future<Map<String, dynamic>> startQuizAttempt(int quizId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.quizAttempt}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'quiz_id': quizId,
          'started_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': QuizAttempt.fromJson(data['data']),
          'message': data['message'] ?? 'Quiz attempt started',
        };
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to start quiz attempt'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Submit quiz answers and complete attempt
  Future<Map<String, dynamic>> submitQuizAttempt({
    required int attemptId,
    required int quizId,
    required List<Map<String, dynamic>> answers, // [{question_id, answer_id}]
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    // First, submit all answers
    for (final answer in answers) {
      final answerUrl = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.quizAnswer}');
      try {
        await http.post(
          answerUrl,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'quiz_attempt_id': attemptId,
            'quiz_question_id': answer['question_id'],
            'quiz_question_answer_id': answer['answer_id'],
          }),
        );
      } catch (e) {
        // Continue even if one answer fails
      }
    }

    // Then complete the attempt
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.quizAttempt}/$attemptId');
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'finished_at': DateTime.now().toUtc().toIso8601String(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': QuizAttempt.fromJson(data['data']),
          'message': data['message'] ?? 'Quiz submitted successfully',
        };
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to submit quiz'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  // Calculate remaining attempts for a quiz
  Future<Map<String, dynamic>> getRemainingAttempts(int quizId, int maxAttempts) async {
    final result = await getQuizAttempts(quizId);
    if (!result['success']) {
      return {'success': false, 'message': result['message']};
    }

    final attempts = result['data'] as List<QuizAttempt>;
    final remainingAttempts = maxAttempts - attempts.length;

    return {
      'success': true,
      'remainingAttempts': remainingAttempts > 0 ? remainingAttempts : 0,
      'attempts': attempts,
    };
  }
}
