import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class BookTicketResult {
  final bool success;
  final String message;
  final int? statusCode;
  final String? bookingReference;
  final int? ticketId;

  BookTicketResult({
    required this.success,
    required this.message,
    this.statusCode,
    this.bookingReference,
    this.ticketId,
  });
}

class TicketService {
  static String get baseUrl => AppConfig.baseUrl;

  Future<BookTicketResult> bookTicket({
    required String token,
    required int eventId,
    required int quantity,
    required String customerName,
    required String customerEmail,
    String? paymentReference,
  }) async {
    final url = Uri.parse('$baseUrl/tickets');

    try {
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'eventId': eventId,
          'quantity': quantity,
          'customerName': customerName,
          'customerEmail': customerEmail,
          if (paymentReference != null) 'paymentReference': paymentReference,
        }),
      )
          .timeout(const Duration(seconds: 8));

      Map<String, dynamic>? decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return BookTicketResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return BookTicketResult(
          success: true,
          message: decodedBody['message']?.toString() ??
              'Ticket created successfully.',
          bookingReference: decodedBody['bookingReference']?.toString(),
          ticketId: decodedBody['ticketId'] as int?,
          statusCode: response.statusCode,
        );
      }

      return BookTicketResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      return BookTicketResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return BookTicketResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return BookTicketResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
}