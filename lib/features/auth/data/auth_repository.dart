import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_constants.dart';
import '../../../core/services/device_service.dart';

class AuthRepository {
  final _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  String _handleError(dynamic data, String defaultMessage) {
    if (data == null) return defaultMessage;

    // Check if there's a direct message field
    if (data['message'] != null) {
      return data['message'].toString();
    }

    // Check for validation errors object
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

  Future<Map<String, dynamic>> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}');

    final deviceName = await DeviceService.getDeviceName();

    final body = {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'email': email,
      'password': password,
      'device_name': deviceName,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final token = data['meta']['token'];
        if (token != null) {
          await saveToken(token);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Registration succeeded',
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Registration failed'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> sendEmailVerification(String token) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.emailVerificationNotification}',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );


      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body);
        }
        return {
          'success': true,
          'message': data?['message'] ?? 'Verification email sent',
        };
      } else {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return {
          'success': false,
          'message': _handleError(data, 'Failed to send verification email'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> sendPhoneVerification(String token) async {
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.phoneVerificationNotification}',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );



      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data;
        if (response.body.isNotEmpty) {
          data = jsonDecode(response.body);
        }
        return {
          'success': true,
          'message': data?['message'] ?? 'Verification phone queued/sent',
        };
      } else {
        final data = response.body.isNotEmpty ? jsonDecode(response.body) : null;
        return {
          'success': false,
          'message': _handleError(data, 'Failed to send verification phone'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyEmailOtp(String token, String code) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyEmail}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Email verified successfully',
        };
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to verify email'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyPhoneOtp(String token, String code) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.verifyPhone}');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Phone verified successfully',
        };
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to verify phone'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getUniversities() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.universities}',
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
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to fetch universities'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getCenters() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.centers}');
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
          'message': _handleError(data, 'Failed to fetch centers'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getFaculties() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.faculties}');
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
          'message': _handleError(data, 'Failed to fetch faculties'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateAcademicProfile({
    required dynamic universityId,
    required List<dynamic> centerIds,
    required dynamic facultyId,
  }) async {
    // Convert center IDs to list of integers
    final centerIdsList = centerIds.map((id) => int.tryParse(id.toString()) ?? id).toList();

    return updateProfile({
      'university_id': int.tryParse(universityId.toString()) ?? universityId,
      'center_ids': centerIdsList,
      'faculty_id': int.tryParse(facultyId.toString()) ?? facultyId,
    });
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> body) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.updateProfile}',
    );
    try {
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to update profile'),
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');
    final deviceName = await DeviceService.getDeviceName();

    final body = {
      'phone_or_email': identifier,
      'password': password,
      'device_name': deviceName,
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['meta']['token'];
        if (token != null) {
          await saveToken(token);
        }
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'data': data,
        };
      } else {
        return {'success': false, 'message': _handleError(data, 'Login failed')};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'message': 'No token found'};

    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.me}');
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
        return {
          'success': true,
          'data': data['data'],
        };
      } else {
        return {
          'success': false,
          'message': _handleError(data, 'Failed to fetch profile'),
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
