import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> _isConnected = ValueNotifier<bool>(true);

  ValueNotifier<bool> get connectionStatus => _isConnected;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void initialize() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
    );
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    ConnectivityResult connectivityResult = result.isNotEmpty
        ? result[0]
        : ConnectivityResult.none;
    bool hasRealConnection = await _checkRealConnection(connectivityResult);
    _isConnected.value = hasRealConnection;
    notifyListeners();
  }

  Future<bool> _checkRealConnection(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      return false;
    }

    return true;
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _isConnected.dispose();
    super.dispose();
  }
}
