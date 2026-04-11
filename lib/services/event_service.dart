import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/event.dart';
import '../models/event_review.dart';

// Custom object used to return get events operation results in a clean structured way.
class EventsResult {
  final bool success;
  final String message;
  final List<Event> events;
  final int? statusCode;
  final String? lastUpdated;
  final bool loadedFromCache;

  EventsResult({
    required this.success,
    required this.message,
    required this.events,
    this.statusCode,
    this.lastUpdated,
    this.loadedFromCache = false,
  });
}

// Custom object used to return meta operation results in a clean structured way.
class MainPageMetaResult {
  final bool success;
  final String message;
  final String? lastUpdated;
  final int? statusCode;

  MainPageMetaResult({
    required this.success,
    required this.message,
    this.lastUpdated,
    this.statusCode,
  });
}

class EventService {
  //TODO
  static String get baseUrl => AppConfig.baseUrl;

  static List<Event>? _cachedEvents;
  static String? _cachedLastUpdated;

  Future<bool> getIsFavorite({
    required String token,
    required int eventId,
  }) async {
    final url = Uri.parse('$baseUrl/events/$eventId/favorite');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
        return decodedBody['isFavorite'] as bool? ?? false;
      }

      return false;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<List<EventReview>> getReviews({
    required String token,
    required int eventId,
  }) async {
    final url = Uri.parse('$baseUrl/events/$eventId/reviews');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
        final reviewsJson = decodedBody['reviews'];

        if (reviewsJson is! List) return [];

        return reviewsJson
            .map((item) => EventReview.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return [];
    } on SocketException {
      return [];
    } on TimeoutException {
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> addFavorite({
    required String token,
    required int eventId,
  }) async {
    final url = Uri.parse('$baseUrl/events/$eventId/favorite');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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

  Future<bool> removeFavorite({
    required String token,
    required int eventId,
  }) async {
    final url = Uri.parse('$baseUrl/events/$eventId/favorite');

    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
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

  Future<MainPageMetaResult> checkMainPageEventsMeta({
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/events/main-page/meta');

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
          .timeout(const Duration(seconds: 8));

      Map<String, dynamic>? decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return MainPageMetaResult(
          success: false,
          message: 'Backend responded, but meta body is not valid JSON.',
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final lastUpdated = decodedBody['lastUpdated']?.toString();

        if (lastUpdated == null || lastUpdated.isEmpty) {
          return MainPageMetaResult(
            success: false,
            message:
            'Backend responded 2xx, but meta JSON is not in expected format. Expected: lastUpdated.',
            statusCode: response.statusCode,
          );
        }

        return MainPageMetaResult(
          success: true,
          message: 'Main page meta loaded successfully.',
          lastUpdated: lastUpdated,
          statusCode: response.statusCode,
        );
      }

      return MainPageMetaResult(
        success: false,
        message: 'Backend responded with error status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      return MainPageMetaResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return MainPageMetaResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return MainPageMetaResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

  Future<EventsResult> getMainPageEvents({
    String? token,
  }) async {
    final url = Uri.parse('$baseUrl/events/main-page');

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
          .timeout(const Duration(seconds: 8));

      Map<String, dynamic>? decodedBody;

      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        return EventsResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          events: [],
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final lastUpdated = decodedBody['lastUpdated']?.toString();
        final eventsJson = decodedBody['events'];

        if (lastUpdated == null || eventsJson is! List) {
          return EventsResult(
            success: false,
            message:
            'Backend responded 2xx, but JSON is not in expected format. Expected: lastUpdated + events.',
            events: [],
            statusCode: response.statusCode,
          );
        }

        final events = eventsJson
            .map((item) => Event.fromJson(item as Map<String, dynamic>))
            .toList();

        _cachedEvents = events;
        _cachedLastUpdated = lastUpdated;

        return EventsResult(
          success: true,
          message: 'Main page events loaded successfully.',
          events: events,
          statusCode: response.statusCode,
          lastUpdated: lastUpdated,
          loadedFromCache: false,
        );
      }

      return EventsResult(
        success: false,
        message: 'Backend responded with error status ${response.statusCode}.',
        events: [],
        statusCode: response.statusCode,
      );
    } on SocketException {
      return EventsResult(
        success: false,
        message: 'No response. Could not connect to backend.',
        events: [],
      );
    } on TimeoutException {
      return EventsResult(
        success: false,
        message: 'No response. Request timed out.',
        events: [],
      );
    } catch (e) {
      return EventsResult(
        success: false,
        message: 'Unexpected error: $e',
        events: [],
      );
    }
  }

  Future<EventsResult> loadMainPageEventsSmart({
    String? token,
  }) async {
    if (_cachedEvents == null || _cachedLastUpdated == null) {
      return getMainPageEvents(token: token);
    }

    final metaResult = await checkMainPageEventsMeta(token: token);

    //debugPrint('CACHED lastUpdated: $_cachedLastUpdated');
    //debugPrint('META   lastUpdated: ${metaResult.lastUpdated}');

    if (!metaResult.success) {
      return EventsResult(
        success: true,
        message: 'Using cached events. Meta check failed.',
        events: _cachedEvents!,
        lastUpdated: _cachedLastUpdated,
        loadedFromCache: true,
      );
    }

    if (metaResult.lastUpdated == _cachedLastUpdated) {
      return EventsResult(
        success: true,
        message: 'Using cached events. Backend list is unchanged.',
        events: _cachedEvents!,
        lastUpdated: _cachedLastUpdated,
        loadedFromCache: true,
      );
    }

    return getMainPageEvents(token: token);
  }
}