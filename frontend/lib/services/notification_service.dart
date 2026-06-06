import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/app_notification.dart';
import 'dio_client.dart';

class NotificationService {
  NotificationService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// `GET /notifications` — paginated list newest-first.
  Future<ApiResponse<PaginatedData<AppNotification>>> list({
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      ApiConstants.notifications,
      queryParameters: {'page': page, 'per_page': perPage},
    );

    return ApiResponse<PaginatedData<AppNotification>>.fromEnvelope(
      _envelope(response),
      decoder: (data) => PaginatedData.fromEnvelope(
        (data as Map).cast<String, dynamic>(),
        (item) => AppNotification.fromJson(item),
      ),
      statusCode: response.statusCode,
    );
  }

  /// `GET /notifications/unread-count` — returns the badge count.
  Future<int> unreadCount() async {
    final response = await _dio.get<dynamic>(
      ApiConstants.notificationsUnreadCount,
    );
    final env = _envelope(response);
    final data = env['data'];
    if (data is Map) return (data['count'] as num?)?.toInt() ?? 0;
    return 0;
  }

  /// `POST /notifications/{id}/read` — mark one notification as read.
  Future<void> markRead(int id) async {
    await _dio.post<dynamic>(ApiConstants.notificationRead(id));
  }

  /// `POST /notifications/read-all` — mark all as read.
  Future<void> markAllRead() async {
    await _dio.post<dynamic>(ApiConstants.notificationsReadAll);
  }

  Map<String, dynamic> _envelope(Response<dynamic> r) {
    final raw = r.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return {'success': false, 'message': 'Unexpected response'};
  }
}
