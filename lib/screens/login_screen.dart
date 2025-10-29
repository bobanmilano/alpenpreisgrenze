// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_price_tracker_app/screens/home_screen.dart';
import 'package:my_price_tracker_app/screens/register_screen.dart';
import 'package:my_price_tracker_app/main.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart'; // ✅ NEU HINZUGEFÜGT

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _email;
  late String _password;
  bool _loading = false;
  String _error = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Anmelden'),
        centerTitle: true,
        backgroundColor: AppColors.primary, // ✅ THEME FARBE
        foregroundColor: Colors.white, // ✅ THEME FARBE
      ),
      body: SingleChildScrollView(
        child: Container(
          // <-- Dieses Container-Widget ...
          decoration: BoxDecoration(
            gradient: LinearGradient(
              // <-- ... hat diesen Verlauf als Dekoration
              begin: Alignment.topCenter, // Startpunkt: Oben
              end: Alignment.bottomCenter, // Endpunkt: Unten
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(
                  0.2,
                ), // Lila (leicht transparent)
                theme.colorScheme.background, // Weiß (oder Hintergrundfarbe)
              ],
            ),
          ),
          padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  child: Image.asset(
                    'assets/logos/aps.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback wenn Logo nicht geladen werden kann
                      return Icon(
                        Icons.account_circle,
                        size: 60,
                        color: AppColors.primary, // ✅ THEME FARBE
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.l), // ✅ THEME ABSTAND
              Center(
                child: Text(
                  'Willkommen bei',
                  style: TextStyle(
                    fontSize: AppTypography.headline3, // ✅ THEME TYPOGRAFIE
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary, // ✅ THEME FARBE
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.s), // ✅ THEME ABSTAND
              Center(
                child: Image.asset(
                  'assets/logos/alpenpreisgrenze-darklila.png',
                  height: 60, // Passen Sie die Höhe an
                ),
              ),
              SizedBox(height: AppSpacing.l), // ✅ THEME ABSTAND
              Text(
                'Melden Sie sich an, um fortzufahren',
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge, // ✅ THEME TYPOGRAFIE
                  color: AppColors.textPrimary, // ✅ THEME FARBE
                ),
              ),
              SizedBox(height: AppSpacing.xl), // ✅ THEME ABSTAND
              // Login Form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Email Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'E-Mail',
                        hintText: 'ihre.email@beispiel.de',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.large,
                          ), // ✅ THEME RADIUS
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte geben Sie Ihre E-Mail ein';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Bitte geben Sie eine gültige E-Mail ein';
                        }
                        return null;
                      },
                      onSaved: (value) => _email = value!,
                    ),
                    SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
                    // Password Field
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Passwort',
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(
                            AppRadius.large,
                          ), // ✅ THEME RADIUS
                        ),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bitte geben Sie Ihr Passwort ein';
                        }
                        if (value.length < 6) {
                          return 'Das Passwort muss mindestens 6 Zeichen haben';
                        }
                        return null;
                      },
                      onSaved: (value) => _password = value!,
                    ),
                    SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
                    // Error Message
                    if (_error.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(
                          AppSpacing.s,
                        ), // ✅ THEME ABSTAND
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(
                            0.1,
                          ), // ✅ THEME FARBE
                          borderRadius: BorderRadius.circular(
                            AppRadius.medium,
                          ), // ✅ THEME RADIUS
                          border: Border.all(
                            color: AppColors.error.withOpacity(
                              0.3,
                            ), // ✅ THEME FARBE
                          ),
                        ),
                        child: Text(
                          _error,
                          style: TextStyle(
                            color: AppColors.error,
                          ), // ✅ THEME FARBE
                        ),
                      ),
                    SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            vertical: AppSpacing.m,
                          ), // ✅ THEME ABSTAND
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.large,
                            ), // ✅ THEME RADIUS
                          ),
                          backgroundColor: AppColors.accent, // ✅ THEME FARBE
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Anmelden',
                                style: TextStyle(
                                  fontSize:
                                      AppTypography.body, // ✅ THEME TYPOGRAFIE
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.xxl), // ✅ THEME ABSTAND
              // Register Link
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterScreen()),
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: 'Noch keinen Account? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                      ), // ✅ THEME FARBE
                      children: [
                        TextSpan(
                          text: 'Registrieren',
                          style: TextStyle(
                            color: AppColors.primary, // ✅ THEME FARBE
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.m), // ✅ THEME ABSTAND
              // Info Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppRadius.large,
                  ), // ✅ THEME RADIUS
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.m), // ✅ THEME ABSTAND
                  child: Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: AppColors.primary, // ✅ THEME FARBE
                        size: 24,
                      ),
                      SizedBox(width: AppSpacing.s), // ✅ THEME ABSTAND
                      Expanded(
                        child: Text(
                          'Ihre Daten sind sicher bei uns. Wir respektieren Ihre Privatsphäre.',
                          style: TextStyle(
                            fontSize: AppTypography.body, // ✅ THEME TYPOGRAFIE
                            color: AppColors.textPrimary, // ✅ THEME FARBE
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() {
        _loading = true;
        _error = '';
      });

      try {
        UserCredential result = await _auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );

        if (result.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
          );
        } else {
          setState(() {
            _error =
                'Anmeldung fehlgeschlagen. Bitte überprüfen Sie Ihre Daten.';
            _loading = false;
          });
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          if (e.code == 'user-not-found') {
            _error = 'Kein Benutzer mit dieser E-Mail gefunden.';
          } else if (e.code == 'wrong-password') {
            _error = 'Falsches Passwort.';
          } else {
            _error = 'Anmeldung fehlgeschlagen. Bitte versuchen Sie es erneut.';
          }
          _loading = false;
        });
      } catch (e) {
        setState(() {
          _error = 'Ein Fehler ist aufgetreten. Bitte versuchen Sie es erneut.';
          _loading = false;
        });
      }
    }
  }
}
