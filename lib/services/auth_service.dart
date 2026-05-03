import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';

// Custom object used to return auth operation results in a clean structured way.
class AuthResult {
  final bool success;
  final String message;
  final Map<String, dynamic>? data;
  final int? statusCode;

  AuthResult({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
  });
}

//class responsible for backend auth actions (login/register/refresh token)
class AuthService {
  // Android emulator -> http://10.0.2.2:8080
  // Mockoon -> http://localhost:8080
  // Real device -> http://PC_IP:8080
  // TODO
  static String get baseUrl => AppConfig.baseUrl;

  // Returns result async way -> Future
  // func responsible for the login
  // returns a AuthResult
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      //request login post -> takes a json body
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 8));

      // var to decode body into dart map
      Map<String, dynamic>? decodedBody;

      //json response into map
      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return AuthResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      // if success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final hasToken = decodedBody['accessToken'] is String;
        final hasUserId = decodedBody['userId'] != null;
        final hasEmail = decodedBody['email'] is String;

        // has expected parameters in the response
        if (hasToken && hasUserId && hasEmail) {
          //method login returns a login success response to the login screen
          return AuthResult(
            success: true,
            message: 'Login success. Expected JSON received.',
            data: decodedBody,
            statusCode: response.statusCode,
          );
        } else {
          //method login returns a login success response but wrong json
          return AuthResult(
            success: false,
            message:
            'Backend responded 2xx, but JSON is not in expected format. Expected: token + userId + email.',
            data: decodedBody,
            statusCode: response.statusCode,
          );
        }
      }
      // unsuccessful response (error, forbidden...)
      return AuthResult(
        success: false,
        message: 'Backend responded with error status ${response.statusCode}.',
        data: decodedBody,
        statusCode: response.statusCode,
      );

      //Exception handling
    } on SocketException {
      return AuthResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on HttpException {
      return AuthResult(
        success: false,
        message: 'HTTP error while contacting backend.',
      );
    } on FormatException {
      return AuthResult(
        success: false,
        message: 'Invalid response format from backend.',
      );
    } on TimeoutException {
      return AuthResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  // Request for signup called in signup screen
  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String birthDate,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/signup');

    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'birthDate': birthDate,
          'password': password,
        }),
      )
          .timeout(const Duration(seconds: 8));

      Map<String, dynamic>? decodedBody;

      try {
        //json response to map
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return AuthResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final hasMessage = decodedBody['message'] is String;
        final hasUserId = decodedBody['userId'] != null;
        final hasEmail = decodedBody['email'] is String;

        if (hasMessage && hasUserId && hasEmail) {
          return AuthResult(
            success: true,
            message: 'Signup success. Expected JSON received.',
            data: decodedBody,
            statusCode: response.statusCode,
          );
        } else {
          return AuthResult(
            success: false,
            message:
            'Backend responded 2xx, but JSON is not in expected format. Expected: message + userId + email.',
            data: decodedBody,
            statusCode: response.statusCode,
          );
        }
      }
      //exception handling
      return AuthResult(
        success: false,
        message: 'Backend responded with error status ${response.statusCode}.',
        data: decodedBody,
        statusCode: response.statusCode,
      );
    } on SocketException {
      return AuthResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on HttpException {
      return AuthResult(
        success: false,
        message: 'HTTP error while contacting backend.',
      );
    } on FormatException {
      return AuthResult(
        success: false,
        message: 'Invalid response format from backend.',
      );
    } on TimeoutException {
      return AuthResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}