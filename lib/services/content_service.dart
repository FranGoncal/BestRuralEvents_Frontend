import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class HelpMessageResult {
  final bool success;
  final String message;
  final int? statusCode;
  final Map<String, dynamic>? data;

  HelpMessageResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.data,
  });
}

class FaqItem {
  final String question;
  final String answer;

  FaqItem({
    required this.question,
    required this.answer,
  });

  factory FaqItem.fromJson(Map<String, dynamic> json) {
    return FaqItem(
      question: json['question']?.toString() ?? '',
      answer: json['answer']?.toString() ?? '',
    );
  }
}

class FaqResult {
  final bool success;
  final String message;
  final int? statusCode;
  final List<FaqItem> faqs;

  FaqResult({
    required this.success,
    required this.message,
    required this.faqs,
    this.statusCode,
  });
}

class ContentService {
  static String get baseUrl => AppConfig.baseUrl;

  Future<FaqResult> getFaqs({String? token}) async {
    final url = Uri.parse('$baseUrl/content/faq');

    try {
      final response = await http
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      )
          .timeout(const Duration(seconds: 12));

      dynamic decodedBody;

      try {
        decodedBody = jsonDecode(response.body);
      } catch (_) {
        return FaqResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
          faqs: [],
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        List<dynamic> faqListJson = [];

        if (decodedBody is List) {
          faqListJson = decodedBody;
        } else if (decodedBody is Map<String, dynamic>) {
          if (decodedBody['faqs'] is List) {
            faqListJson = decodedBody['faqs'] as List<dynamic>;
          } else if (decodedBody['data'] is List) {
            faqListJson = decodedBody['data'] as List<dynamic>;
          }
        }

        final faqs = faqListJson
            .whereType<Map<String, dynamic>>()
            .map(FaqItem.fromJson)
            .where((item) => item.question.isNotEmpty && item.answer.isNotEmpty)
            .toList();

        return FaqResult(
          success: true,
          message: decodedBody is Map<String, dynamic>
              ? decodedBody['message']?.toString() ?? 'FAQ loaded successfully.'
              : 'FAQ loaded successfully.',
          statusCode: response.statusCode,
          faqs: faqs,
        );
      }

      final message = decodedBody is Map<String, dynamic>
          ? decodedBody['message']?.toString() ??
          'Backend responded with error status ${response.statusCode}.'
          : 'Backend responded with error status ${response.statusCode}.';

      return FaqResult(
        success: false,
        message: message,
        statusCode: response.statusCode,
        faqs: [],
      );
    } on SocketException {
      return FaqResult(
        success: false,
        message: 'No response. Could not connect to backend.',
        faqs: [],
      );
    } on TimeoutException {
      return FaqResult(
        success: false,
        message: 'No response. Request timed out.',
        faqs: [],
      );
    } catch (e) {
      return FaqResult(
        success: false,
        message: 'Unexpected error: $e',
        faqs: [],
      );
    }
  }

  Future<HelpMessageResult> sendHelpMessage({
    required String token,
    required String userId,
    required String subject,
    required String message,
  }) async {
    final url = Uri.parse('$baseUrl/content/help');

    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'subject': subject,
          'message': message,
        }),
      )
          .timeout(const Duration(seconds: 12));

      Map<String, dynamic>? decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return HelpMessageResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return HelpMessageResult(
          success: true,
          message: decodedBody['message']?.toString() ?? 'Message sent successfully.',
          statusCode: response.statusCode,
          data: decodedBody,
        );
      }

      return HelpMessageResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        statusCode: response.statusCode,
        data: decodedBody,
      );
    } on SocketException {
      return HelpMessageResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return HelpMessageResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return HelpMessageResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}