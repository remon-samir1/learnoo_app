import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart';
import '../../../core/network/api_constants.dart';

class DiscussionRepository {
  final _storage = const FlutterSecureStorage();

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Map<String, dynamic>> getDiscussions({int? chapterId}) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final queryParams = chapterId != null ? '?chapter_id=$chapterId' : '';
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.discussion}$queryParams');

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
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch discussions',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> postDiscussion({
    required int chapterId,
    required String type,
    required String content,
    required int moment,
    int? parentId,
    File? voiceFile,
  }) async {
    final token = await _getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.discussion}');
    
    try {
      if (type == 'voice' && voiceFile != null) {
        var request = http.MultipartRequest('POST', url);
        request.headers.addAll({
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        });

        request.fields['chapter_id'] = chapterId.toString() ;
        request.fields['type'] = type;
        request.fields['moment'] = moment.toString();
        if (parentId != null) {
          request.fields['parent_id'] = parentId.toString();
        }

        request.files.add(await http.MultipartFile.fromPath(
          'content',
          voiceFile.path,
          filename: basename(voiceFile.path),
          contentType: MediaType('audio', 'm4a'),
        ));

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        final data = jsonDecode(response.body);

        if (response.statusCode == 201 || response.statusCode == 200) {
          return {'success': true, 'data': data['data']};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to post voice discussion',
          };
        }
      } else {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'chapter_id': chapterId,
            'type': type,
            'content': content,
            'moment': moment,
            if (parentId != null) 'parent_id': parentId,
          }),
        );

        final data = jsonDecode(response.body);
        if (response.statusCode == 201 || response.statusCode == 200) {
          return {'success': true, 'data': data['data']};
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Failed to post discussion',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
