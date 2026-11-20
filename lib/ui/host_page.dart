
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../modules/networking/communication/host_service.dart';

class HostPage extends StatefulWidget {
  const HostPage({super.key});

  @override
  State<HostPage> createState() => _HostPageState();
}

class _HostPageState extends State<HostPage> {
  final hostService = HostService();
  final messages = <String>[];

  HostingInfo? info;
  bool busy = false;
  String? error;

  @override
  void initState() {
    super.initState();

    hostService.onMessage = (text) {
      if (mounted) {
        setState(() => messages.insert(0, text));
      }
    };
  }

  Future<void> start() async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      final result = await hostService.startHosting();

      if (mounted) {
        setState(() => info = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  Future<void> stop() async {
    setState(() {
      busy = true;
      error = null;
    });

    try {
      await hostService.stopHosting();

      if (mounted) {
        setState(() => info = null);
      }
    } catch (e) {
      if (mounted) {
        setState(() => error = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  void dispose() {
    hostService.onMessage = null;
    hostService.stopHosting();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Offline Games Host'),
    ),
    body: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        FilledButton(
          onPressed: busy ? null : (info == null ? start : stop),
          child: Text(
            busy
                ? 'Please wait...'
                : info == null
                    ? 'Start Server'
                    : 'Stop Server',
          ),
        ),

        if (error != null)
          Text(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),

        if (info != null) ...[
          const SizedBox(height: 20),

          const Text(
            '1. Scan to join the Wi-Fi',
            style: TextStyle(fontSize: 18),
          ),

          Center(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: QrImageView(
                data: wifiQr(
                  info!.hotspot.ssid,
                  info!.hotspot.password,
                ),
                version: QrVersions.auto,
                size: 220,
              ),
            ),
          ),

          SelectableText('Network: ${info!.hotspot.ssid}'),
          SelectableText('Password: ${info!.hotspot.password}'),

          const SizedBox(height: 24),

          const Text(
            '2. Open Safari / Chrome and enter:',
            style: TextStyle(fontSize: 18),
          ),

          const SelectableText(
            'http://game.local',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Text(
            'Experimental: the short address depends on '
            'multicast support in the hotspot.',
          ),

          if (info!.hotspot.address != null) ...[
            const SizedBox(height: 12),
            const Text('If game.local does not work, use:'),
            SelectableText('http://${info!.hotspot.address}'),
          ] else
            const Text(
              'Could not detect hotspot IP; check your device.',
            ),

          if (!info!.mdnsStarted)
            const Text(
              'mDNS could not start; use the IP fallback.',
            ),

          const Text(
            '“No Internet Connection” on the iPad is normal.',
          ),
        ],

        const SizedBox(height: 20),

        const Text(
          'Received messages:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),

        for (final message in messages)
          ListTile(title: Text(message)),
      ],
    ),
  );
}

String wifiQr(String ssid, String password) {
  String escape(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(';', r'\;')
      .replaceAll(':', r'\:')
      .replaceAll(',', r'\,')
      .replaceAll('"', r'\"');

  return 'WIFI:T:WPA;S:${escape(ssid)};P:${escape(password)};;';
}
