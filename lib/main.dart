// lib/main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/providers/user_provider.dart';
import 'package:my_price_tracker_app/screens/home_screen.dart';
import 'package:my_price_tracker_app/theme/app_theme_config.dart';
import 'package:my_price_tracker_app/widgets/overlay_connection_status.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'services/connectivity_service.dart'; // Importiere den neuen Service
// Importiere das Overlay-Widget

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _connectivityService.initialize();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider.value(value: _connectivityService),
      ],
      child: MaterialApp(
        title: 'AlpenPreisGrenze',
        theme: AppThemeConfig.lightTheme,
        home: AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasData && snapshot.data != null) {
          // ✅ Korrektur: Entferne das '!' und verwende snapshot.data direkt
          // Da die Bedingung 'snapshot.data != null' bereits geprüft wurde,
          // ist sichergestellt, dass snapshot.data nicht null ist.
          userProvider.setUser(snapshot.data); // Entferne das '!'
          return OverlayConnectionStatus(
            child: HomeScreen(),
          );
        } else {
          return OverlayConnectionStatus(
            child: LoginScreen(),
          );
        }
      },
    );
  }
}