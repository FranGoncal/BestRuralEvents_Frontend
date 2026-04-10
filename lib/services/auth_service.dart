import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

//Custom result object
class LoginResult {
  final bool success;
  final String message;
  //Json
  final Map<String, dynamic>? data;
  final int? statusCode;

  //constructure
  LoginResult({
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
  static const String baseUrl = 'http://localhost:8080';

  // Returns result async way -> Future
  // func responsible for the
  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    try {
      //request login post -> leva um body em json
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
      )
          .timeout(const Duration(seconds: 8));

      // var to decode body into dart map
      Map<String, dynamic>? decodedBody;

      //json response into map
      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return LoginResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      // if success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final hasToken = decodedBody['token'] is String;
        final hasUserId = decodedBody['userId'] != null;
        final hasEmail = decodedBody['email'] is String;

        // has expected parameters in the response
        if (hasToken && hasUserId && hasEmail) {
          //method login returns a login success response to the login screen
          return LoginResult(
            success: true,
            message: 'Login success. Expected JSON received.',
            data: decodedBody,
            statusCode: response.statusCode,
          );
        } else {
          //method login returns a login success response but wrong json
          return LoginResult(
            success: false,
            message:
            'Backend responded 2xx, but JSON is not in expected format. Expected: token + userId + email.',
            data: decodedBody,
            statusCode: response.statusCode,
          );
        }
      }
      // unsuccessful response (error, forbidden...)
      return LoginResult(
        success: false,
        message: 'Backend responded with error status ${response.statusCode}.',
        data: decodedBody,
        statusCode: response.statusCode,
      );

      //Exception handling
    } on SocketException {
      return LoginResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on HttpException {
      return LoginResult(
        success: false,
        message: 'HTTP error while contacting backend.',
      );
    } on FormatException {
      return LoginResult(
        success: false,
        message: 'Invalid response format from backend.',
      );
    } on TimeoutException {
      return LoginResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return LoginResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}