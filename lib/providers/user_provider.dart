import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_price_tracker_app/screens/login_screen.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;

  User? get currentUser => _currentUser;

  void setUser(User? user) {
    _currentUser = user;
    notifyListeners();
  }

  // GlobalKey für den Fortschrittsdialog
  final GlobalKey<_ProgressDialogState> _dialogKey = GlobalKey();

  Future<void> deleteUserAccount(BuildContext context) async {
    // Zeige den Fortschrittsdialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProgressDialog(key: _dialogKey),
    );

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Kein Benutzer angemeldet.');
      }

      // Firestore-Daten löschen
      await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).delete();

      bool deletionSuccessful = false;
      bool requiresReauth = false;

      try {
        await currentUser.delete();
        deletionSuccessful = true;
      } on FirebaseAuthException catch (authError) {
        if (authError.code == 'requires-recent-login') {
          requiresReauth = true;
        } else {
          throw Exception('Firebase Auth Fehler: ${authError.message}');
        }
      }

      // Erster Dialog schließen
      print('Schließe ersten Dialog...');
      _closeDialog();

      if (requiresReauth) {
        final bool reauthSuccess = await _showReauthenticateDialog(context);

        if (reauthSuccess) {
          // Zeige zweiten Fortschrittsdialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _ProgressDialog(key: _dialogKey),
          );

          final secondUser = FirebaseAuth.instance.currentUser;
          if (secondUser != null) {
            await secondUser.delete();
            deletionSuccessful = true;
          }

          // Zweiter Dialog schließen
          print('Schließe zweiten Dialog...');
          _closeDialog();
        } else {
          return;
        }
      }

      if (deletionSuccessful) {
        setUser(null); // Benutzerstatus zurücksetzen

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Account erfolgreich gelöscht.')),
          );
        }

        // Navigiere zum Login-Screen
        if (context.mounted) {
          await Future.delayed(Duration(milliseconds: 200)); // Kurze Verzögerung
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print('Fehler aufgetreten: $e');

      // Sicherstellen, dass der Dialog geschlossen wird
      _closeDialog();

      // Fehlermeldung anzeigen
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Löschen des Accounts: $e')),
        );
      }
    }
  }

  // Hilfsmethode zum Schließen des Dialogs
  void _closeDialog() {
    if (_dialogKey.currentState != null) {
      _dialogKey.currentState?.closeDialog();
    }
  }

  Future<bool> _showReauthenticateDialog(BuildContext context) async {
    bool success = false;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Re-Authentifizierung erforderlich'),
        content: Text('Bitte melden Sie sich erneut an, um fortzufahren.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              success = true;
              Navigator.of(context).pop();
            },
            child: Text('OK'),
          ),
        ],
      ),
    );

    return success;
  }
}

// Widget für den Fortschrittsdialog
class _ProgressDialog extends StatefulWidget {
  const _ProgressDialog({Key? key}) : super(key: key);

  @override
  _ProgressDialogState createState() => _ProgressDialogState();
}

class _ProgressDialogState extends State<_ProgressDialog> {
  // Methode zum Schließen des Dialogs
  void closeDialog() {
    if (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Lösche Account...'),
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('Bitte warten...'),
        ],
      ),
    );
  }
}