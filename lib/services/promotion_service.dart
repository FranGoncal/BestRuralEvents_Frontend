import 'dart:convert';
import 'package:http/http.dart' as http;

class PromotionResult {
  final bool success;
  final String message;
  final String? promotionReference;

  PromotionResult({
    required this.success,
    required this.message,
    this.promotionReference,
  });
}

class PromotionService {
  // Adjust this to your real backend base URL or shared config.
  static const String _baseUrl = 'http://localhost:8080';

  Future<PromotionResult> promoteEvent({
    required String token,
    required int eventId,
    required String userId,
    required String paymentMethodId,
    required double amount,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/promotion');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'eventId': eventId,
          'userId': userId,
          'paymentMethodId': paymentMethodId,
          'amount': amount,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        String? promotionReference;
        String message = 'Event promoted successfully';

        if (response.body.isNotEmpty) {
          final data = jsonDecode(response.body);

          if (data is Map<String, dynamic>) {
            promotionReference = data['promotionReference']?.toString();
            message = data['message']?.toString() ?? message;
          }
        }

        return PromotionResult(
          success: true,
          message: message,
          promotionReference: promotionReference,
        );
      }

      String errorMessage = 'Could not promote event';
      if (response.body.isNotEmpty) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic>) {
            errorMessage = data['message']?.toString() ?? errorMessage;
          }
        } catch (_) {}
      }

      return PromotionResult(
        success: false,
        message: errorMessage,
      );
    } catch (_) {
      return PromotionResult(
        success: false,
        message: 'Network error while promoting event',
      );
    }
  }
}