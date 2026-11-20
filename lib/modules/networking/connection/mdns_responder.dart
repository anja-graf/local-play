import 'dart:io';
import 'dart:typed_data';

/// Experimental local mDNS A-record responder for game.local.
/// Multicast traffic may be blocked by Android hotspot implementations.
class MdnsResponder {
  RawDatagramSocket? _socket;
  InternetAddress? _address;
  static final _group = InternetAddress('224.0.0.251');

  Future<void> start(String ipv4) async {
    await stop();

    _address = InternetAddress(ipv4);

    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
    );

    // Find the interface that owns the hotspot IP.
    NetworkInterface? hotspotInterface;

    for (final interface in interfaces) {
      if (interface.addresses.any((a) => a.address == ipv4)) {
        hotspotInterface = interface;
        break;
      }
    }

    if (hotspotInterface == null) {
      throw StateError('No interface found for hotspot IP $ipv4');
    }

    print('mDNS interface: ${hotspotInterface.name}');
    print('mDNS IP: $ipv4');

    print('mDNS: binding socket...');

    final socket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      5353,
      reuseAddress: true,
    );

    _socket = socket;

    print('mDNS: socket bound successfully');

    try {
      print('mDNS: joining multicast group...');
      socket.joinMulticast(_group, hotspotInterface);
      print('mDNS: multicast group joined');
    } catch (e, st) {
      print('mDNS: joinMulticast failed: $e');
      print(st);
      rethrow;
    }

    try {
      print('mDNS: setting multicast interface...');

      print('mDNS: multicast interface configured');
    } catch (e, st) {
      print('mDNS: multicastInterface failed: $e');
      print(st);
      rethrow;
    }

    socket.multicastHops = 255;

    print('mDNS listening on UDP 5353');
    socket.listen((event) {
      if (event != RawSocketEvent.read) return;

      Datagram? datagram;

      while ((datagram = socket.receive()) != null) {
        final data = datagram!.data;

      
        if (_asksForGameLocal(data)) {
          print('mDNS query for game.local detected');

          final answer = _answer();

          // Test: send response directly to the requesting device
          socket.send(answer, datagram.address, datagram.port);

         
        }
      }
    });
  }

  bool _asksForGameLocal(Uint8List bytes) {
    if (bytes.length < 12) return false;

    final questions = (bytes[4] << 8) | bytes[5];
    if (questions == 0 || questions > 30) return false;

    // Read DNS names, including compressed labels.
    (String, int)? readName(int start) {
      var pos = start;
      var end = -1;
      var jumps = 0;
      final labels = <String>[];

      while (true) {
        if (pos >= bytes.length || jumps > 20) return null;

        final len = bytes[pos];

        if ((len & 0xC0) == 0xC0) {
          if (pos + 1 >= bytes.length) return null;

          final pointer = ((len & 0x3F) << 8) | bytes[pos + 1];
          if (pointer >= bytes.length) return null;

          if (end == -1) end = pos + 2;
          pos = pointer;
          jumps++;
          continue;
        }

        if (len == 0) {
          return (labels.join('.').toLowerCase(), end == -1 ? pos + 1 : end);
        }

        if (len > 63 || pos + 1 + len > bytes.length) {
          return null;
        }

        labels.add(String.fromCharCodes(bytes.sublist(pos + 1, pos + 1 + len)));

        pos += len + 1;
      }
    }

    var pos = 12;

    for (var q = 0; q < questions; q++) {
      final result = readName(pos);
      if (result == null) return false;

      final (name, nextPos) = result;
      pos = nextPos;

      if (pos + 4 > bytes.length) return false;

      final type = (bytes[pos] << 8) | bytes[pos + 1];
      pos += 4;

      if (name == 'game.local' && (type == 1 || type == 255)) {
        return true;
      }
    }

    return false;
  }

  Uint8List _answer() {
    final ip = _address!.rawAddress;
    final out = BytesBuilder();
    // Response, authoritative, one answer, no question.
    out.add([0, 0, 0x84, 0, 0, 0, 0, 1, 0, 0, 0, 0]);
    out.add([4, ...'game'.codeUnits, 5, ...'local'.codeUnits, 0]);
    // A record, IN with cache-flush bit, TTL 30 seconds, 4-byte IPv4.
    out.add([0, 1, 0x80, 1, 0, 0, 0, 30, 0, 4, ...ip]);
    return out.toBytes();
  }

  Future<void> stop() async {
    _socket?.close();
    _socket = null;
  }
}
