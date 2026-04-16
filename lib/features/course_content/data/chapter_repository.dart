import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/offline/offline_first_repository.dart';
import '../../../core/local/hive_boxes.dart';
import '../../../core/local/models/pending_action.dart';

class ChapterRepository with OfflineFirstRepository {
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Get chapter by ID with offline-first support
  Future<Map<String, dynamic>> getChapterById(String chapterId) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    return offlineFirstFetch(
      apiFetcher: () async {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.chapters}/$chapterId');
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
          return {'success': true, 'data': data['data']};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch chapter details',
          };
        }
      },
      boxName: HiveBoxes.chapters,
      cacheKey: 'chapter_$chapterId',
      maxCacheAge: const Duration(hours: 24),
    );
  }

  Future<Map<String, dynamic>> activateCode({
    required String code,
    required int itemId,
    required String itemType,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.codeActivate}');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'code': code,
          'item_id': itemId,
          'item_type': itemType,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid activation code',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// Get user progress with offline-first support
  Future<Map<String, dynamic>> getUserProgress() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    return offlineFirstFetch(
      apiFetcher: () async {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProgress}');
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
          return {'success': true, 'data': data['data'] ?? []};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to fetch user progress',
          };
        }
      },
      boxName: HiveBoxes.progress,
      cacheKey: 'user_progress',
      maxCacheAge: const Duration(hours: 1), // Progress changes frequently
    );
  }

  /// Update user progress with offline queue support
  /// When offline, the update is queued and synced when connection is restored
  Future<Map<String, dynamic>> updateUserProgress({
    required int chapterId,
    required int progressSeconds,
    required bool isCompleted,
  }) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final payload = {
      'chapter_id': chapterId,
      'progress_seconds': progressSeconds,
      'is_completed': isCompleted,
    };

    // Try to queue the action
    final queueResult = await queueAction(
      actionType: PendingActionTypes.progress,
      payload: payload,
      optimisticId: 'progress_$chapterId',
      deduplicate: true, // Only keep latest progress for each chapter
    );

    // If not queued (we're online), execute immediately
    if (!queueResult['queued']) {
      try {
        final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.userProgress}');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'data': data['data'],
            'offline': false,
            'queued': false,
          };
        } else {
          // API failed, queue for retry
          await queueAction(
            actionType: PendingActionTypes.progress,
            payload: payload,
            optimisticId: 'progress_$chapterId',
            deduplicate: true,
          );
          return {
            'success': true, // Optimistic success
            'offline': false,
            'queued': true,
            'message': 'Progress saved locally, will sync when online',
          };
        }
      } catch (e) {
        // Network error, queue for retry
        await queueAction(
          actionType: PendingActionTypes.progress,
          payload: payload,
          optimisticId: 'progress_$chapterId',
          deduplicate: true,
        );
        return {
          'success': true, // Optimistic success
          'offline': true,
          'queued': true,
          'message': 'Progress saved locally, will sync when online',
        };
      }
    }

    // Action was queued (offline mode)
    return {
      'success': true,
      'offline': true,
      'queued': true,
      'actionId': queueResult['actionId'],
      'message': 'Progress saved locally, will sync when online',
    };
  }

  /// Get cached chapters for a course
  List<dynamic> getCachedChapters() {
    return getAllCached(HiveBoxes.chapters);
  }

  /// Get cached user progress
  List<dynamic>? getCachedProgress() {
    final cached = getCached(HiveBoxes.progress, 'user_progress');
    return cached as List<dynamic>?;
  }
}
