import 'package:flutter/services.dart';

class HotspotInfo {
  final String ssid;
  final String password;
  final String? address;

  const HotspotInfo({required this.ssid, required this.password, this.address});

  factory HotspotInfo.fromMap(Map<dynamic, dynamic> map) => HotspotInfo(
    ssid: map['ssid'] as String,
    password: map['password'] as String,
    address: map['address'] as String?,
  );
}

class HotspotService {
  static const _channel = MethodChannel('offline_games/hotspot');

  Future<HotspotInfo> start() async {
    final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('start');
    if (result == null) throw StateError('No hotspot information returned');
    return HotspotInfo.fromMap(result);
  }

  Future<String?> getAddress() => _channel.invokeMethod<String>('address');
  Future<void> stop() => _channel.invokeMethod<void>('stop');
  Future<void> acquireMulticastLock() => _channel.invokeMethod<void>('acquireMulticastLock');
  Future<void> releaseMulticastLock() => _channel.invokeMethod<void>('releaseMulticastLock');
}
