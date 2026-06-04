import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../services/dio_client.dart';

/// In-app viewer for a loan's KTM document. Fetches the bytes through
/// the authenticated Dio client (so the server's auth:sanctum gate is
/// satisfied with our Bearer token) and renders either an interactive
/// image or a "PDF attached" placeholder.
///
/// We pass the **API path** (not the absolute URL), e.g.
///   `/loans/42/document`
/// so the request goes through DioClient with the Authorization header
/// auto-attached by AuthInterceptor.
class KtmViewerScreen extends StatefulWidget {
  const KtmViewerScreen({super.key, required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<KtmViewerScreen> createState() => _KtmViewerScreenState();
}

class _KtmViewerScreenState extends State<KtmViewerScreen> {
  Uint8List? _bytes;
  String? _contentType;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    try {
      final response = await DioClient.instance.get<List<int>>(
        widget.path,
        options: Options(
          responseType: ResponseType.bytes,
          // Server returns the raw file, NOT our JSON envelope, so we
          // must accept any 2xx as success.
          validateStatus: (s) => s != null && s < 400,
          headers: const {'Accept': '*/*'},
        ),
      );

      if (!mounted) return;
      final data = response.data;
      if (data == null || data.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'KTM file is empty.';
        });
        return;
      }

      setState(() {
        _bytes = Uint8List.fromList(data);
        _contentType = response.headers
            .value('content-type')
            ?.split(';')
            .first
            .trim()
            .toLowerCase();
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = switch (e.response?.statusCode) {
          401 => 'Your session expired. Please sign in again.',
          403 => 'You are not allowed to view this KTM.',
          404 => 'KTM file is missing.',
          _ => 'Could not load KTM (${e.message ?? 'unknown error'}).',
        };
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load KTM ($e).';
      });
    }
  }

  bool get _isImage {
    final ct = _contentType ?? '';
    return ct.startsWith('image/');
  }

  bool get _isPdf {
    final ct = _contentType ?? '';
    return ct == 'application/pdf' || ct.endsWith('/pdf');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 56,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : _isImage
            ? Center(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Image.memory(_bytes!, fit: BoxFit.contain),
                ),
              )
            : _isPdf
            ? _PdfPlaceholder(bytes: _bytes!.length)
            : _UnknownPlaceholder(contentType: _contentType ?? 'unknown'),
      ),
    );
  }
}

class _PdfPlaceholder extends StatelessWidget {
  const _PdfPlaceholder({required this.bytes});
  final int bytes;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.picture_as_pdf, color: Colors.white, size: 80),
            const SizedBox(height: 16),
            const Text(
              'KTM uploaded as PDF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PDF size: ${(bytes / 1024).toStringAsFixed(1)} KB',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            const Text(
              'In-app PDF preview is not available for students. The lab '
              'staff can review your KTM PDF from the admin dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnknownPlaceholder extends StatelessWidget {
  const _UnknownPlaceholder({required this.contentType});
  final String contentType;
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file_outlined,
              color: Colors.white,
              size: 72,
            ),
            const SizedBox(height: 12),
            Text(
              'Unsupported file type ($contentType).',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
