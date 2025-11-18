import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';

class OverlayConnectionStatus extends StatelessWidget {
  final Widget child;
  const OverlayConnectionStatus({super.key, required this.child});

  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder<bool>(

      valueListenable: Provider.of<ConnectivityService>(context, listen: false).connectionStatus,
      builder: (context, isConnected, child) {
        return Stack(
          children: [
            child!,
            if (!isConnected)
              Container(
                color: Colors.red.withOpacity(0.85),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.signal_wifi_off,
                        color: Colors.white,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Keine Internetverbindung',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Einige Funktionen sind eingeschränkt.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}