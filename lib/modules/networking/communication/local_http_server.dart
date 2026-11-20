import 'dart:convert';
import 'dart:io';

class LocalHttpServer {
  HttpServer? _server;
  final void Function(String) onMessage;

  LocalHttpServer({required this.onMessage});

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.anyIPv4, 80);
    _server!.listen((request) async {
      try {
        if (request.method == 'GET' && request.uri.path == '/') {
          request.response.headers.contentType = ContentType.html;
          request.response.write('''<!doctype html><html><head>
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Offline Games</title></head><body>
<h2>Offline Games - Client</h2>
<form id="form"><input id="message" placeholder="Message" required>
<button type="submit">Send</button></form><p id="status"></p>
<script>
document.getElementById('form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const message = document.getElementById('message').value;
  try {
    const response = await fetch('/message', {
      method: 'POST', headers: {'Content-Type': 'application/json'},
      body: JSON.stringify({message})
    });
    if (!response.ok) throw new Error('HTTP ' + response.status);
    document.getElementById('status').textContent = 'Sent!';
    document.getElementById('message').value = '';
  } catch (err) {
    document.getElementById('status').textContent = 'Error: ' + err;
  }
});
</script></body></html>''');
        } else if (request.method == 'POST' && request.uri.path == '/message') {
          final body = await utf8.decoder.bind(request).join();
          final json = jsonDecode(body) as Map<String, dynamic>;
          final message = json['message'];
          if (message is! String || message.trim().isEmpty) {
            request.response.statusCode = HttpStatus.badRequest;
          } else {
            onMessage(message);
            request.response.write('OK');
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
      } catch (_) {
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
