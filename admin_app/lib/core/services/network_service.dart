import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider exposing real-time online/offline network status.
final isOnlineProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map((results) {
    if (results.isEmpty) return false;
    return results.any((result) => result != ConnectivityResult.none);
  });
});
