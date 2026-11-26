import '../connection/hotspot_service.dart';
import '../connection/mdns_responder.dart';
import 'local_http_server.dart';

class HostService {
  final _hotspot = HotspotService();
  final _mdns = MdnsResponder();

  final LocalHttpServer _server;

  HostService({
    required LocalHttpServer server,
  }) : _server = server;

  Future<HostingInfo> startHosting() async {
    try {
      final h = await _hotspot.start();

      await _server.start();

      final address =
          await _hotspot.getAddress() ?? h.address;

      var mdnsStarted = false;

      if (address != null) {
        try {
          await _hotspot.acquireMulticastLock();
          await _mdns.start(address);
          mdnsStarted = true;
        } catch (e) {
          await _hotspot.releaseMulticastLock();
        }
      }

      return HostingInfo(
        hotspot: HotspotInfo(
          ssid: h.ssid,
          password: h.password,
          address: address,
        ),
        mdnsStarted: mdnsStarted,
      );
    } catch (e) {
      await stopHosting();
      rethrow;
    }
  }

  Future<void> stopHosting() async {
    await _mdns.stop();
    await _hotspot.releaseMulticastLock();
    await _server.stop();
    await _hotspot.stop();
  }
}

class HostingInfo {
  final HotspotInfo hotspot;
  final bool mdnsStarted;

  const HostingInfo({
    required this.hotspot,
    required this.mdnsStarted,
  });
}