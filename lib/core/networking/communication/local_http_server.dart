import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import '../../cards/game_action.dart';

class LocalHttpServer {
  HttpServer? _server;
  final void Function(GameAction) onAction;

  LocalHttpServer({required this.onAction});

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 80);

    _server!.listen((request) async {
      try {
        if (request.method == 'GET' && request.uri.path == '/') {
          request.response.headers.contentType = ContentType.html;

          final html = await rootBundle.loadString(
            'assets/web_client/index.html',
          );

          request.response.write(html);

        } else if (request.method == 'POST' &&
            request.uri.path == '/action') {
          final body = await utf8.decoder.bind(request).join();
          final json = jsonDecode(body) as Map<String, dynamic>;

          final action = GameAction.fromJson(json);
          onAction(action);

          request.response.write('OK');

        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
      } catch (e) {
        request.response.statusCode = HttpStatus.badRequest;
      } finally {
        await request.response.close();
      }
    });
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }
}