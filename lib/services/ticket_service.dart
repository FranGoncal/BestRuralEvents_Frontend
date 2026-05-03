import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/event_ticket.dart';
import '../models/ticket.dart';

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

class EventTicketsResult {
  final bool success;
  final String message;
  final List<EventTicket> tickets;
  final int? capacity;
  final int? ticketsSold;
  final int? ticketsAvailable;
  final int? statusCode;

  EventTicketsResult({
    required this.success,
    required this.message,
    required this.tickets,
    this.capacity,
    this.ticketsSold,
    this.ticketsAvailable,
    this.statusCode,
  });
}

class TicketsResult {
  final bool success;
  final String message;
  final List<Ticket> tickets;
  final int? statusCode;

  TicketsResult({
    required this.success,
    required this.message,
    required this.tickets,
    this.statusCode,
  });
}

class TicketValidationResult {
  final bool success;
  final bool valid;
  final String message;
  final String? ticketId;
  final String? userId;
  final String? eventId;
  final String? qrToken;
  final int? statusCode;

  TicketValidationResult({
    required this.success,
    required this.valid,
    required this.message,
    this.ticketId,
    this.userId,
    this.eventId,
    this.qrToken,
    this.statusCode,
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

  Future<TicketsResult> getUserTickets({
    required String token,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/tickets/my');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      ).timeout(const Duration(seconds: 8));

      final decodedBody = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (decodedBody is! List) {
          return TicketsResult(
            success: false,
            message: 'Expected a list of tickets.',
            tickets: [],
            statusCode: response.statusCode,
          );
        }

        final tickets = decodedBody
            .map((item) => Ticket.fromJson(item as Map<String, dynamic>))
            .toList();

        return TicketsResult(
          success: true,
          message: 'Tickets loaded successfully.',
          tickets: tickets,
          statusCode: response.statusCode,
        );
      }

      return TicketsResult(
        success: false,
        message: 'Backend error ${response.statusCode}',
        tickets: [],
        statusCode: response.statusCode,
      );
    } on SocketException {
      return TicketsResult(
        success: false,
        message: 'Could not connect to backend.',
        tickets: [],
      );
    } on TimeoutException {
      return TicketsResult(
        success: false,
        message: 'Request timed out.',
        tickets: [],
      );
    } catch (e) {
      return TicketsResult(
        success: false,
        message: 'Unexpected error: $e',
        tickets: [],
      );
    }
  }

  Future<bool> cancelTicket({
    required String token,
    required String ticketId,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/tickets/$ticketId/cancel');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-User-Id': userId,
        },
      ).timeout(const Duration(seconds: 8));

      return response.statusCode >= 200 && response.statusCode < 300;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<TicketValidationResult> validateTicketForQr({
    required String token,
    required String ticketId,
  }) async {
    final url = Uri.parse('$baseUrl/tickets/$ticketId/valid');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      Map<String, dynamic> decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return TicketValidationResult(
          success: false,
          valid: false,
          message: 'Backend responded, but body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return TicketValidationResult(
          success: true,
          valid: decodedBody['valid'] as bool? ?? false,
          message: decodedBody['message']?.toString() ??
              ((decodedBody['valid'] as bool? ?? false)
                  ? 'Ticket validated successfully.'
                  : 'Ticket is not valid.'),
          ticketId: decodedBody['ticketId']?.toString(),
          userId: decodedBody['userId']?.toString(),
          eventId: decodedBody['eventId']?.toString(),
          qrToken: decodedBody['qrToken']?.toString(),
          statusCode: response.statusCode,
        );
      }

      return TicketValidationResult(
        success: false,
        valid: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      return TicketValidationResult(
        success: false,
        valid: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return TicketValidationResult(
        success: false,
        valid: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return TicketValidationResult(
        success: false,
        valid: false,
        message: 'Unexpected error: $e',
      );
    }
  }
  Future<EventTicketsResult> getEventTickets({
    required String token,
    required int eventId,
  }) async {
    final url = Uri.parse('$baseUrl/tickets/event/$eventId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      Map<String, dynamic> decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return EventTicketsResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          tickets: [],
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final ticketsJson = decodedBody['tickets'];

        if (ticketsJson is! List) {
          return EventTicketsResult(
            success: false,
            message:
            'Backend responded 2xx, but JSON is not in expected format. Expected: tickets.',
            tickets: [],
            statusCode: response.statusCode,
          );
        }

        final tickets = ticketsJson
            .where((item) => item is Map<String, dynamic>)
            .map((item) => EventTicket.fromJson(item as Map<String, dynamic>))
            .toList();

        return EventTicketsResult(
          success: true,
          message: decodedBody['message']?.toString() ??
              'Event tickets loaded successfully.',
          tickets: tickets,
          capacity: (decodedBody['capacity'] as num?)?.toInt(),
          ticketsSold: (decodedBody['ticketsSold'] as num?)?.toInt(),
          ticketsAvailable: (decodedBody['ticketsAvailable'] as num?)?.toInt(),
          statusCode: response.statusCode,
        );
      }

      return EventTicketsResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        tickets: [],
        statusCode: response.statusCode,
      );
    } on SocketException {
      return EventTicketsResult(
        success: false,
        message: 'No response. Could not connect to backend.',
        tickets: [],
      );
    } on TimeoutException {
      return EventTicketsResult(
        success: false,
        message: 'No response. Request timed out.',
        tickets: [],
      );
    } catch (e) {
      return EventTicketsResult(
        success: false,
        message: 'Unexpected error: $e',
        tickets: [],
      );
    }
  }
}