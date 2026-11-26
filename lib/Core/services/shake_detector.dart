import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

class ShakeDetector {
  StreamSubscription<UserAccelerometerEvent>? _subscription;

  DateTime _lastShake = DateTime(2000);

  void startListening(VoidCallback onShake) {
    stopListening();

    _subscription = userAccelerometerEventStream().listen((event) {
      final acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final now = DateTime.now();

      if (acceleration > 15 &&
          now.difference(_lastShake).inMilliseconds > 1000) {
        _lastShake = now;
        onShake();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
