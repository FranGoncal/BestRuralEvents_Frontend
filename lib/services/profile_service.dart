import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ProfileResult {
  final bool success;
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  ProfileResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.data,
  });
}

class ProfileService {
  static String get baseUrl => AppConfig.baseUrl;

  Future<ProfileResult> getProfile({
    required String token,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/user/$userId');

    try {
      final response = await http
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(const Duration(seconds: 12));

      Map<String, dynamic>? decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ProfileResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ProfileResult(
          success: true,
          message: decodedBody['message']?.toString() ?? 'Profile loaded successfully.',
          data: decodedBody,
          statusCode: response.statusCode,
        );
      }

      return ProfileResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        data: decodedBody,
        statusCode: response.statusCode,
      );
    } on SocketException {
      return ProfileResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return ProfileResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return ProfileResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<ProfileResult> updateProfile({
    required String token,
    required String userId,
    required String name,
    required String birthDate,
  }) async {
    final url = Uri.parse('$baseUrl/user/$userId');

    try {
      final response = await http
          .put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'birthDate': birthDate,
        }),
      )
          .timeout(const Duration(seconds: 12));

      Map<String, dynamic>? decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ProfileResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ProfileResult(
          success: true,
          message: decodedBody['message']?.toString() ?? 'Profile updated successfully.',
          data: decodedBody,
          statusCode: response.statusCode,
        );
      }

      return ProfileResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        data: decodedBody,
        statusCode: response.statusCode,
      );
    } on SocketException {
      return ProfileResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return ProfileResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return ProfileResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<ProfileResult> changePassword({
    required String token,
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/user/$userId/password');

    try {
      final response = await http
          .put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      )
          .timeout(const Duration(seconds: 12));

      Map<String, dynamic>? decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return ProfileResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ProfileResult(
          success: true,
          message: decodedBody['message']?.toString() ?? 'Password changed successfully.',
          data: decodedBody,
          statusCode: response.statusCode,
        );
      }

      return ProfileResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        data: decodedBody,
        statusCode: response.statusCode,
      );
    } on SocketException {
      return ProfileResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return ProfileResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return ProfileResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}