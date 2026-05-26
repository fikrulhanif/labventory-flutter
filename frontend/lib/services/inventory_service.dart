import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/category.dart';
import '../models/inventory.dart';
import 'dio_client.dart';

/// Wraps `/api/inventories` and `/api/categories`.
///
/// Validates Requirements 7.1 — 7.7.
class InventoryService {
  InventoryService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// `GET /inventories` with optional filters and pagination cursor.
  Future<ApiResponse<PaginatedData<Inventory>>> list({
    String? search,
    int? categoryId,
    String? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    if (search != null && search.trim().isNotEmpty) {
      query['search'] = search.trim();
    }
    if (categoryId != null) {
      query['category_id'] = categoryId;
    }
    if (status != null && status.isNotEmpty) {
      query['status'] = status;
    }

    final response = await _dio.get<dynamic>(
      ApiConstants.inventories,
      queryParameters: query,
    );

    return ApiResponse<PaginatedData<Inventory>>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) => PaginatedData.fromEnvelope(
        (data as Map).cast<String, dynamic>(),
        Inventory.fromJson,
      ),
      statusCode: response.statusCode,
    );
  }

  /// `GET /inventories/{id}` (Requirement 7.5, 7.6).
  Future<ApiResponse<Inventory>> detail(int id) async {
    final response = await _dio.get<dynamic>(ApiConstants.inventoryDetail(id));

    return ApiResponse<Inventory>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) =>
          Inventory.fromJson((data as Map).cast<String, dynamic>()),
      statusCode: response.statusCode,
    );
  }

  /// `GET /categories` — flat list for the filter UI.
  Future<ApiResponse<List<Category>>> categories() async {
    final response = await _dio.get<dynamic>(ApiConstants.categories);

    return ApiResponse<List<Category>>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) {
        if (data is List) {
          return data
              .whereType<Map>()
              .map((m) => Category.fromJson(m.cast<String, dynamic>()))
              .toList();
        }
        return <Category>[];
      },
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _envelopeFrom(Response<dynamic> response) {
    final raw = response.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return {'success': false, 'message': 'Unexpected response shape'};
  }
}
