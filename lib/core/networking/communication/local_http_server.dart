import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'network_message.dart';
import 'web_client_assets.dart';

class LocalHttpServer {
  HttpServer? _server;

  final MessageHandler onMessage;
  final String webAsset;
  final Map<String, String> staticAssets;

  LocalHttpServer({
    required this.onMessage,
    this.webAsset = 'assets/web_client/index.html',
    this.staticAssets = const {},
  });

  Future<void> start() async {
    if (_server != null) return;

    final server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      80,
    );

    _server = server;
    server.listen(_handle);
  }

  Future<Map<String, dynamic>> _readJson(
    HttpRequest request,
  ) async {
    final bytes = <int>[];

    await for (final chunk in request.timeout(
      const Duration(seconds: 5),
    )) {
      bytes.addAll(chunk);

      if (bytes.length > 8192) {
        throw const NetworkMessageException(
          'Request too large',
          413,
        );
      }
    }

    final data = jsonDecode(utf8.decode(bytes));

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'Expected a JSON object',
      );
    }

    return data;
  }

  String? _token(HttpRequest request) {
    final auth = request.headers.value(
      HttpHeaders.authorizationHeader,
    );

    return auth != null && auth.startsWith('Bearer ')
        ? auth.substring(7)
        : null;
  }

  void _json(
    HttpResponse response,
    Object data, [
    int status = 200,
  ]) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(data));
  }

  Future<void> _handle(HttpRequest request) async {
    final response = request.response;

    response.headers.set('Cache-Control', 'no-store');
    response.headers.set(
      'X-Content-Type-Options',
      'nosniff',
    );

    try {
      final path = request.uri.path;

      // Main website
      if (request.method == 'GET' &&
          (path == '/' || path == '/play')) {
        final html = await rootBundle.loadString(webAsset);

        response.headers.contentType = ContentType.html;
        response.write(html);
      }

      // Static assets: SVG, CSS, JavaScript
      else if (request.method == 'GET' &&
          staticAssets.containsKey(path)) {
        final asset = staticAssets[path]!;
        final data = await rootBundle.load(asset);

        response.headers.contentType =
            staticAssetContentType(path);

        response.add(
          data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          ),
        );
      }

      // Client communication
      else if (request.method == 'POST' &&
          path == '/api/message') {
        if (request.headers.contentType?.mimeType !=
            'application/json') {
          throw const NetworkMessageException(
            'Expected application/json',
            415,
          );
        }

        final message = NetworkMessage.fromJson(
          await _readJson(request),
        );

        final result = await onMessage(
          message,
          _token(request),
        );

        _json(response, result);
      }

      // Unknown endpoint
      else {
        _json(response, {'error': 'Not found'}, 404);
      }
    } on NetworkMessageException catch (e) {
      _json(response, {'error': e.message}, e.statusCode);
    } on FormatException {
      _json(response, {'error': 'Invalid JSON message'}, 400);
    } on TimeoutException {
      _json(response, {'error': 'Request timeout'}, 408);
    } catch (e, stack) {
      debugPrint('LocalHttpServer error: $e\n$stack');

      _json(response, {'error': 'Server error'}, 500);
    } finally {
      await response.close();
    }
  }

  Future<void> stop() async {
    final server = _server;
    _server = null;

    await server?.close(force: true);
  }
}