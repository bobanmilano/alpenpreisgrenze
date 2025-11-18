import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:my_price_tracker_app/screens/home_screen.dart';
import 'package:my_price_tracker_app/screens/register_screen.dart';
import 'package:my_price_tracker_app/main.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';

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
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primaryContainer.withOpacity(0.2),
                theme.colorScheme.background,
              ],
            ),
          ),
          padding: EdgeInsets.all(AppSpacing.m),
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
                      return Icon(
                        Icons.account_circle,
                        size: 60,
                        color: AppColors.primary,
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.l),
              Center(
                child: Text(
                  'Willkommen bei',
                  style: TextStyle(
                    fontSize: AppTypography.headline3,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.s),
              Center(
                child: Image.asset(
                  'assets/logos/alpenpreisgrenze-darklila.png',
                  height: 60,
                ),
              ),
              SizedBox(height: AppSpacing.l),
              Text(
                'Melden Sie sich an, um fortzufahren',
                style: TextStyle(
                  fontSize: AppTypography.bodyLarge,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppSpacing.xl),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'E-Mail',
                        hintText: 'ihre.email@beispiel.de',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.large),
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
                    SizedBox(height: AppSpacing.m),

                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Passwort',
                        hintText: '••••••••',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.large),
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
                    SizedBox(height: AppSpacing.xxl),

                    if (_error.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(AppSpacing.s),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(
                            color: AppColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _error,
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    SizedBox(height: AppSpacing.m),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.large,
                            ),
                          ),
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                        ),
                        child: _loading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Text(
                                'Anmelden',
                                style: TextStyle(
                                  fontSize: AppTypography.body,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.xxl),

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
                      style: TextStyle(color: AppColors.textSecondary),
                      children: [
                        TextSpan(
                          text: 'Registrieren',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SizedBox(height: AppSpacing.m),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.m),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: AppColors.primary, size: 24),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Ihre Daten sind sicher bei uns. Wir respektieren Ihre Privatsphäre.',
                          style: TextStyle(
                            fontSize: AppTypography.body,
                            color: AppColors.textPrimary,
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
