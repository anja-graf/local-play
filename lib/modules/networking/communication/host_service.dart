import 'package:localplay/modules/networking/events/network_event.dart';
import 'package:localplay/modules/networking/communication/networking_service.dart';
import 'package:localplay/modules/games/game_action.dart';
import '../connection/hotspot_service.dart';
import '../connection/mdns_responder.dart';
import 'local_http_server.dart';

class HostService implements NetworkingService {
  @override
  Future<void> disconnect() {
    // TODO: implement disconnect
    throw UnimplementedError();
  }

  @override
  // TODO: implement events
  Stream<NetworkEvent> get events => throw UnimplementedError();

  @override
  Future<void> sendAction(GameAction action) {
    // TODO: implement sendAction
    throw UnimplementedError();
  }
  
  final _hotspot = HotspotService();
  final _mdns = MdnsResponder();

  late final LocalHttpServer _server =
      LocalHttpServer(onMessage: (text) {
    onMessage?.call(text);
  });

  // Callback for received messages
  void Function(String)? onMessage;

  Future<HostingInfo> startHosting() async {
    try {
      final h = await _hotspot.start();

      await _server.start();

      final address = await _hotspot.getAddress() ?? h.address;

      var mdnsStarted = false;

      if (address != null) {
        try {
          await _hotspot.acquireMulticastLock();
          await _mdns.start(address);
          mdnsStarted = true;
        } catch (e) {
          await _hotspot.releaseMulticastLock();
          // Hosting still works without mDNS.
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

  HostingInfo({
    required this.hotspot,
    required this.mdnsStarted,
  });
}

