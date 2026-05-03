import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/event.dart';
import '../models/event_review.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';


// used to create events
class CreateEventResult {
  final bool success;
  final String message;
  final Event? event;
  final int? statusCode;

  CreateEventResult({
    required this.success,
    required this.message,
    this.event,
    this.statusCode,
  });
}

// used to update events
class UpdateEventResult {
  final bool success;
  final String message;
  final Event? event;
  final int? statusCode;

  UpdateEventResult({
    required this.success,
    required this.message,
    this.event,
    this.statusCode,
  });
}

class UserCreatedEventsResult {
  final bool success;
  final String message;
  final List<Event> events;
  final int? statusCode;

  UserCreatedEventsResult({
    required this.success,
    required this.message,
    required this.events,
    this.statusCode,
  });
}

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


class SearchEventsResult {
  final bool success;
  final String message;
  final List<Event> events;
  final int page;
  final int pageSize;
  final int total;
  final bool hasMore;
  final int? statusCode;

  SearchEventsResult({
    required this.success,
    required this.message,
    required this.events,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.hasMore,
    this.statusCode,
  });
}

class EventService {
  static String get baseUrl => AppConfig.baseUrl;

  static List<Event>? _cachedEvents;
  static String? _cachedLastUpdated;

  Future<bool> getIsFavorite({
    required String token,
    required int eventId,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/events/$eventId/favorite')
        .replace(queryParameters: {
      'userId': userId.toString(),
    });

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
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/events/$eventId/favorite')
        .replace(queryParameters: {
      'userId': userId.toString(),
    });

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
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/events/$eventId/favorite')
        .replace(queryParameters: {
      'userId': userId.toString(),
    });

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

  Future<EventsResult> getFavoriteEvents({
    required String token,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/events/favourites')
        .replace(queryParameters: {
      'userId': userId.toString(),
    });

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
        return EventsResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          events: [],
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final eventsJson = decodedBody['events'];

        if (eventsJson is! List) {
          return EventsResult(
            success: false,
            message: 'Backend responded 2xx, but JSON is not in expected format. Expected: events.',
            events: [],
            statusCode: response.statusCode,
          );
        }

        final events = eventsJson
            .map((item) => Event.fromJson(item as Map<String, dynamic>))
            .toList();

        return EventsResult(
          success: true,
          message: decodedBody['message']?.toString() ?? 'Favorite events loaded successfully.',
          events: events,
          statusCode: response.statusCode,
        );
      }

      return EventsResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
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


  Future<SearchEventsResult> searchEvents({
    required String token,
    String? query,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? activityType,
    DateTime? startDate,
    DateTime? endDate,
    required int page,
    int pageSize = 10,
  }) async {
    final queryParameters = <String, String>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
    };

    if (query != null && query.trim().isNotEmpty) {
      queryParameters['query'] = query.trim();
    }
    if (minPrice != null) {
      queryParameters['minPrice'] = minPrice.toString();
    }
    if (maxPrice != null) {
      queryParameters['maxPrice'] = maxPrice.toString();
    }
    if (minRating != null) {
      queryParameters['minRating'] = minRating.toString();
    }
    if (activityType != null && activityType.trim().isNotEmpty) {
      queryParameters['activityType'] = activityType.trim();
    }
    if (startDate != null) {
      queryParameters['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      queryParameters['endDate'] = endDate.toIso8601String();
    }

    final url = Uri.parse('$baseUrl/events/search')
        .replace(queryParameters: queryParameters);

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
        return SearchEventsResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          events: [],
          page: page,
          pageSize: pageSize,
          total: 0,
          hasMore: false,
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final eventsJson = decodedBody['events'];
        final pagination = decodedBody['pagination'];

        if (eventsJson is! List || pagination is! Map<String, dynamic>) {
          return SearchEventsResult(
            success: false,
            message: 'JSON format invalid. Expected: events + pagination.',
            events: [],
            page: page,
            pageSize: pageSize,
            total: 0,
            hasMore: false,
            statusCode: response.statusCode,
          );
        }

        final events = eventsJson
            .map((item) => Event.fromJson(item as Map<String, dynamic>))
            .toList();

        return SearchEventsResult(
          success: true,
          message: decodedBody['message']?.toString() ?? 'Search completed.',
          events: events,
          page: (pagination['page'] as int?) ?? page,
          pageSize: (pagination['pageSize'] as int?) ?? pageSize,
          total: (pagination['total'] as int?) ?? events.length,
          hasMore: (pagination['hasMore'] as bool?) ?? false,
          statusCode: response.statusCode,
        );
      }

      return SearchEventsResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        events: [],
        page: page,
        pageSize: pageSize,
        total: 0,
        hasMore: false,
        statusCode: response.statusCode,
      );
    } on SocketException {
      return SearchEventsResult(
        success: false,
        message: 'No response. Could not connect to backend.',
        events: [],
        page: page,
        pageSize: pageSize,
        total: 0,
        hasMore: false,
      );
    } on TimeoutException {
      return SearchEventsResult(
        success: false,
        message: 'No response. Request timed out.',
        events: [],
        page: page,
        pageSize: pageSize,
        total: 0,
        hasMore: false,
      );
    } catch (e) {
      return SearchEventsResult(
        success: false,
        message: 'Unexpected error: $e',
        events: [],
        page: page,
        pageSize: pageSize,
        total: 0,
        hasMore: false,
      );
    }
  }

  Future<UserCreatedEventsResult> getUserCreatedEvents({
    required String token,
    required String userId,
  }) async {
    final url = Uri.parse('$baseUrl/events/user/$userId');

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
        return UserCreatedEventsResult(
          success: false,
          message: 'Backend responded, but body is not valid JSON.',
          events: [],
          statusCode: response.statusCode,
        );
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final eventsJson = decodedBody['events'];

        if (eventsJson is! List) {
          return UserCreatedEventsResult(
            success: false,
            message: 'Backend responded 2xx, but JSON is not in expected format. Expected: events.',
            events: [],
            statusCode: response.statusCode,
          );
        }

        final events = eventsJson
            .map((item) => Event.fromJson(item as Map<String, dynamic>))
            .toList();

        return UserCreatedEventsResult(
          success: true,
          message: decodedBody['message']?.toString() ??
              'User created events loaded successfully.',
          events: events,
          statusCode: response.statusCode,
        );
      }

      return UserCreatedEventsResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        events: [],
        statusCode: response.statusCode,
      );
    } on SocketException {
      return UserCreatedEventsResult(
        success: false,
        message: 'No response. Could not connect to backend.',
        events: [],
      );
    } on TimeoutException {
      return UserCreatedEventsResult(
        success: false,
        message: 'No response. Request timed out.',
        events: [],
      );
    } catch (e) {
      return UserCreatedEventsResult(
        success: false,
        message: 'Unexpected error: $e',
        events: [],
      );
    }
  }


  Future<CreateEventResult> createEvent({
    required String token,
    required String title,
    required String location,
    required DateTime date,
    required double price,
    String? description,
    XFile? imageXFile,
    Uint8List? imageBytes,
  }) async {
    final url = Uri.parse('$baseUrl/events');

    try {
      final request = http.MultipartRequest('POST', url);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['title'] = title.trim();
      request.fields['location'] = location.trim();
      request.fields['date'] = date.toIso8601String();
      request.fields['price'] = price.toString();

      if (description != null && description.trim().isNotEmpty) {
        request.fields['description'] = description.trim();
      }

      if (imageXFile != null) {
        if (kIsWeb) {
          final bytes = imageBytes ?? await imageXFile.readAsBytes();

          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: imageXFile.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageXFile.path,
              filename: imageXFile.name,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );

      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic> decodedBody = {};
      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final eventJson = decodedBody['event'];

        return CreateEventResult(
          success: true,
          message: decodedBody['message']?.toString() ??
              'Event created successfully.',
          event: eventJson is Map<String, dynamic>
              ? Event.fromJson(eventJson)
              : null,
          statusCode: response.statusCode,
        );
      }

      return CreateEventResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      return CreateEventResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return CreateEventResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return CreateEventResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }
  Future<UpdateEventResult> updateEvent({
    required String token,
    required int eventId,
    required String title,
    required String location,
    required DateTime date,
    required double price,
    String? description,
    XFile? imageXFile,
    Uint8List? imageBytes,
  }) async {
    final url = Uri.parse('$baseUrl/events/$eventId');

    try {
      final request = http.MultipartRequest('PUT', url);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['title'] = title.trim();
      request.fields['location'] = location.trim();
      request.fields['date'] = date.toIso8601String();
      request.fields['price'] = price.toString();

      if (description != null && description.trim().isNotEmpty) {
        request.fields['description'] = description.trim();
      }

      if (imageXFile != null) {
        if (kIsWeb) {
          final bytes = imageBytes ?? await imageXFile.readAsBytes();

          request.files.add(
            http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename: imageXFile.name,
            ),
          );
        } else {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image',
              imageXFile.path,
              filename: imageXFile.name,
            ),
          );
        }
      }

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 15),
      );

      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic> decodedBody = {};
      try {
        decodedBody = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {}

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final eventJson = decodedBody['event'];

        return UpdateEventResult(
          success: true,
          message: decodedBody['message']?.toString() ??
              'Event updated successfully.',
          event: eventJson is Map<String, dynamic>
              ? Event.fromJson(eventJson)
              : null,
          statusCode: response.statusCode,
        );
      }

      return UpdateEventResult(
        success: false,
        message: decodedBody['message']?.toString() ??
            'Backend responded with error status ${response.statusCode}.',
        statusCode: response.statusCode,
      );
    } on SocketException {
      return UpdateEventResult(
        success: false,
        message: 'No response. Could not connect to backend.',
      );
    } on TimeoutException {
      return UpdateEventResult(
        success: false,
        message: 'No response. Request timed out.',
      );
    } catch (e) {
      return UpdateEventResult(
        success: false,
        message: 'Unexpected error: $e',
      );
    }
  }

}