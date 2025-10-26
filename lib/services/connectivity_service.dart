// lib/services/connectivity_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // Für ValueNotifier

class ConnectivityService extends ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  final ValueNotifier<bool> _isConnected = ValueNotifier<bool>(true);

  ValueNotifier<bool> get connectionStatus => _isConnected;

  // Korrigiere den Typ der Subscription
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  void initialize() {
    // Korrigiere die Stream-Zuweisung
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async { // Korrigiere den Typ hier
    // Nimm das erste Ergebnis aus der Liste, wenn vorhanden
    ConnectivityResult connectivityResult = result.isNotEmpty ? result[0] : ConnectivityResult.none;
    bool hasRealConnection = await _checkRealConnection(connectivityResult);
    _isConnected.value = hasRealConnection;
    notifyListeners(); // Benachrichtige Provider-Consumer
  }

  // Korrigiere den Typ des Parameters
  Future<bool> _checkRealConnection(ConnectivityResult result) async {
    if (result == ConnectivityResult.none) {
      return false; // Kein Netzwerktyp gefunden
    }

    // Für die meisten Anwendungsfälle reicht die Connectivity-Prüfung.
    // Optional: Hier könntest du einen echten HTTP-Request machen (z.B. auf google.com)
    // um zu prüfen, ob die Verbindung funktioniert.
    // Beispiel:
    // import 'package:http/http.dart' as http;
    // try {
    //   final response = await http.get(Uri.parse('https://www.google.com'), headers: {'Connection': 'close'});
    //   return response.statusCode == 200;
    // } catch (e) {
    //   debugPrint("Verbindungs-Ping fehlgeschlagen: $e");
    //   return false;
    // }

    return true; // Annahme: Wenn ein Netzwerktyp vorhanden ist, ist Internet verfügbar
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _isConnected.dispose();
    super.dispose();
  }
}