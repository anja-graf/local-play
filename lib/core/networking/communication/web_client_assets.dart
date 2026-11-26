import 'dart:io';

const Map<String, String> webClientAssets = {
  '/web/style.css': 'assets/web_client/style.css',
  '/web/app.js': 'assets/web_client/app.js',
  '/web/networking.js': 'assets/web_client/networking.js',
  '/web/widgets.js': 'assets/web_client/widgets.js',

  '/web/games/default_game.js':
      'assets/web_client/games/default_game.js',

  '/web/games/werewolf.js':
      'assets/web_client/games/werewolf.js',
};

ContentType staticAssetContentType(String path) {
  if (path.endsWith('.svg')) {
    return ContentType('image', 'svg+xml');
  }

  if (path.endsWith('.js')) {
    return ContentType(
      'text',
      'javascript',
      charset: 'utf-8',
    );
  }

  if (path.endsWith('.css')) {
    return ContentType(
      'text',
      'css',
      charset: 'utf-8',
    );
  }

  if (path.endsWith('.html')) {
    return ContentType.html;
  }

  return ContentType.binary;
}