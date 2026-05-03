import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/event_review.dart';

class ReviewResult {
  final bool success;
  final String message;
  final EventReview? review;
  final int? statusCode;

  ReviewResult({
    required this.success,
    required this.message,
    this.review,
    this.statusCode,
  });
}

class ReviewsResult {
  final bool success;
  final String message;
  final List<EventReview> reviews;
  final int? statusCode;

  ReviewsResult({
    required this.success,
    required this.message,
    required this.reviews,
    this.statusCode,
  });
}

class ReviewService {
  static String get baseUrl => AppConfig.baseUrl;

  Map<String, String> _headers({
    required String token,
    required String userId,
  }) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'X-User-Id': userId,
    };
  }

  Future<ReviewsResult> getMyReviews({
    required String token,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/reviews/me');

    try {
      final response = await http
          .get(url, headers: _headers(token: token, userId: userId))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is! List) {
          return ReviewsResult(
            success: false,
            message: 'Invalid reviews response format.',
            reviews: [],
            statusCode: response.statusCode,
          );
        }

        return ReviewsResult(
          success: true,
          message: 'Reviews loaded successfully.',
          reviews: decoded
              .map((item) => EventReview.fromJson(item as Map<String, dynamic>))
              .toList(),
          statusCode: response.statusCode,
        );
      }

      return ReviewsResult(
        success: false,
        message: _extractMessage(response.body) ?? 'Could not load reviews.',
        reviews: [],
        statusCode: response.statusCode,
      );
    } on SocketException {
      return ReviewsResult(
        success: false,
        message: 'No response. Could not connect to backend.',
        reviews: [],
      );
    } on TimeoutException {
      return ReviewsResult(
        success: false,
        message: 'Request timed out.',
        reviews: [],
      );
    } catch (e) {
      return ReviewsResult(
        success: false,
        message: 'Unexpected error: $e',
        reviews: [],
      );
    }
  }

  Future<ReviewResult> createReview({
    required String token,
    required String userId,
    required int eventId,
    required int rating,
    required String comment,
  }) async {
    final url = Uri.parse('$baseUrl/reviews');

    return _sendReviewRequest(
      method: 'POST',
      url: url,
      token: token,
      userId: userId,
      eventId: eventId,
      rating: rating,
      comment: comment,
      successMessage: 'Review submitted successfully.',
    );
  }

  Future<ReviewResult> updateReview({
    required String token,
    required String userId,
    required int reviewId,
    required int eventId,
    required int rating,
    required String comment,
  }) async {
    final url = Uri.parse('$baseUrl/reviews/$reviewId');

    return _sendReviewRequest(
      method: 'PUT',
      url: url,
      token: token,
      userId: userId,
      eventId: eventId,
      rating: rating,
      comment: comment,
      successMessage: 'Review updated successfully.',
    );
  }

  Future<ReviewResult> deleteReview({
    required String token,
    required String userId,
    required int reviewId,
  }) async {
    final url = Uri.parse('$baseUrl/reviews/$reviewId');

    try {
      final response = await http
          .delete(url, headers: _headers(token: token, userId: userId))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ReviewResult(
          success: true,
          message: 'Review removed successfully.',
          statusCode: response.statusCode,
        );
      }

      return ReviewResult(
        success: false,
        message: _extractMessage(response.body) ?? 'Could not remove review.',
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ReviewResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<ReviewResult> _sendReviewRequest({
    required String method,
    required Uri url,
    required String token,
    required String userId,
    required int eventId,
    required int rating,
    required String comment,
    required String successMessage,
  }) async {
    try {
      final body = jsonEncode({
        'eventId': eventId,
        'rating': rating,
        'comment': comment.trim(),
      });

      final response = method == 'POST'
          ? await http
          .post(
        url,
        headers: _headers(token: token, userId: userId),
        body: body,
      )
          .timeout(const Duration(seconds: 8))
          : await http
          .put(
        url,
        headers: _headers(token: token, userId: userId),
        body: body,
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ReviewResult(
          success: true,
          message: successMessage,
          review: EventReview.fromJson(jsonDecode(response.body)),
          statusCode: response.statusCode,
        );
      }

      return ReviewResult(
        success: false,
        message: _extractMessage(response.body) ?? 'Could not save review.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      return ReviewResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return ReviewResult(
        success: false,
        message: 'Request timed out.',
      );
    } catch (e) {
      return ReviewResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);

      if (decoded is Map<String, dynamic>) {
        return decoded['message']?.toString() ??
            decoded['error']?.toString();
      }
    } catch (_) {}

    return null;
  }


  Future<ReviewsResult> getReviewsForEvent({
    required String token,
    required int eventId,
  }) async {
    final url = Uri.parse('$baseUrl/reviews/event/$eventId');

    try {
      final response = await http
          .get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is! List) {
          return ReviewsResult(
            success: false,
            message: 'Invalid reviews response format.',
            reviews: [],
            statusCode: response.statusCode,
          );
        }

        return ReviewsResult(
          success: true,
          message: 'Reviews loaded successfully.',
          reviews: decoded
              .map((item) => EventReview.fromJson(item as Map<String, dynamic>))
              .toList(),
          statusCode: response.statusCode,
        );
      }

      return ReviewsResult(
        success: false,
        message: _extractMessage(response.body) ?? 'Could not load reviews.',
        reviews: [],
        statusCode: response.statusCode,
      );
    } catch (e) {
      return ReviewsResult(
        success: false,
        message: 'Unexpected error: $e',
        reviews: [],
      );
    }
  }
}