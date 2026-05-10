import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class PaymentResult {
  final bool success;
  final String message;
  final int? statusCode;
  final String? paymentReference;
  final String? paymentStatus;

  PaymentResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.paymentReference,
    this.paymentStatus,
  });
}

class PaymentService {
  static String get baseUrl => AppConfig.baseUrl;

  Future<PaymentResult> processPayment({
    required String token,
    required String userId,
    required int eventId,
    required int quantity,
    required double amount,
    required String paymentMethodId,
    required List<DateTime>? selectedDays,
  }) async {
    final url = Uri.parse('$baseUrl/payment');

    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
        body: jsonEncode({
          'eventId': eventId,
          'quantity': quantity,
          'amount': amount,
          'paymentMethodId': paymentMethodId,
          if (selectedDays != null)
            'selectedDays': selectedDays.map((d) {
              final year = d.year.toString().padLeft(4, '0');
              final month = d.month.toString().padLeft(2, '0');
              final day = d.day.toString().padLeft(2, '0');
              return '$year-$month-$day';
            }).toList(),
        }),
      )
          .timeout(const Duration(seconds: 12));

      Map<String, dynamic>? decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return PaymentResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PaymentResult(
          success: true,
          message: decodedBody['message']?.toString() ?? 'Payment successful.',
          paymentReference: decodedBody['paymentReference']?.toString(),
          paymentStatus: decodedBody['paymentStatus']?.toString(),
          statusCode: response.statusCode,
        );
      }

      return PaymentResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        paymentReference: decodedBody['paymentReference']?.toString(),
        paymentStatus: decodedBody['paymentStatus']?.toString(),
        statusCode: response.statusCode,
      );
    } on SocketException {
      return PaymentResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return PaymentResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}