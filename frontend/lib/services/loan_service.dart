import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../models/api_response.dart';
import '../models/loan.dart';
import 'dio_client.dart';

/// Wraps `/api/loans` student-facing endpoints.
///
/// Validates Requirements 8.1 — 8.9, 11.1 — 11.5, 18.6.
class LoanService {
  LoanService({Dio? dio}) : _dio = dio ?? DioClient.instance;

  final Dio _dio;

  /// `POST /loans` — multipart upload (Requirements 8.1, 8.6, 8.7).
  ///
  /// `documentPath` is the absolute file path on disk (returned by
  /// image_picker / file_picker). Dio's [MultipartFile.fromFile] handles
  /// the actual streaming.
  Future<ApiResponse<Loan>> create({
    required int inventoryId,
    required DateTime borrowDate,
    required DateTime returnDate,
    required String documentPath,
    String? documentFilename,
    String? notes,
  }) async {
    final form = FormData.fromMap({
      'inventory_id': inventoryId,
      'borrow_date': _formatDate(borrowDate),
      'return_date': _formatDate(returnDate),
      if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
      'document': await MultipartFile.fromFile(
        documentPath,
        filename: documentFilename,
      ),
    });

    final response = await _dio.post<dynamic>(ApiConstants.loans, data: form);

    return ApiResponse<Loan>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) => Loan.fromJson((data as Map).cast<String, dynamic>()),
      statusCode: response.statusCode,
    );
  }

  /// `GET /loans` — paginated history scoped to authenticated student
  /// (Requirements 11.1, 11.5).
  Future<ApiResponse<PaginatedData<Loan>>> history({
    LoanStatus? status,
    int page = 1,
    int perPage = 15,
  }) async {
    final query = <String, dynamic>{'page': page, 'per_page': perPage};
    if (status != null && status != LoanStatus.unknown) {
      query['status'] = status.wire;
    }

    final response = await _dio.get<dynamic>(
      ApiConstants.loans,
      queryParameters: query,
    );

    return ApiResponse<PaginatedData<Loan>>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) => PaginatedData.fromEnvelope(
        (data as Map).cast<String, dynamic>(),
        Loan.fromJson,
      ),
      statusCode: response.statusCode,
    );
  }

  /// `GET /loans/{id}` — owner-only detail (Requirement 11.3, 11.4).
  Future<ApiResponse<Loan>> detail(int id) async {
    final response = await _dio.get<dynamic>(ApiConstants.loanDetail(id));

    return ApiResponse<Loan>.fromEnvelope(
      _envelopeFrom(response),
      decoder: (data) => Loan.fromJson((data as Map).cast<String, dynamic>()),
      statusCode: response.statusCode,
    );
  }

  /// `DELETE /loans/{id}` — cancel a pending loan (student only).
  Future<ApiResponse<void>> cancel(int id) async {
    final response = await _dio.delete<dynamic>(ApiConstants.loanCancel(id));
    return ApiResponse<void>.fromEnvelope(
      _envelopeFrom(response),
      statusCode: response.statusCode,
    );
  }

  // -- helpers --

  String _formatDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> _envelopeFrom(Response<dynamic> response) {
    final raw = response.data;
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return raw.cast<String, dynamic>();
    return {'success': false, 'message': 'Unexpected response shape'};
  }
}
