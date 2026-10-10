import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum NetworkStatus { online, offline }

class NetworkConnectivityService {
  NetworkStatus _status = NetworkStatus.online;
  final StreamController<NetworkStatus> _controller =
      StreamController<NetworkStatus>.broadcast();

  NetworkStatus get status => _status;
  Stream<NetworkStatus> get onStatusChanged => _controller.stream;

  void updateStatus(NetworkStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _controller.add(newStatus);
    }
  }

  void dispose() {
    _controller.close();
  }
}

final networkConnectivityServiceProvider =
    Provider<NetworkConnectivityService>((ref) {
  final service = NetworkConnectivityService();
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(networkConnectivityServiceProvider);
  return connectivity.status == NetworkStatus.online;
});
