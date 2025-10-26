// lib/screens/settings_screen.dart
import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart'
    show FirebaseAuth, User, FirebaseAuthException, EmailAuthProvider;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:my_price_tracker_app/providers/user_provider.dart';
import 'package:my_price_tracker_app/screens/legal_screen.dart';
import 'package:my_price_tracker_app/screens/login_screen.dart'
    show LoginScreen;
import 'package:my_price_tracker_app/screens/profile_edit_screen.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import 'package:my_price_tracker_app/theme/app_theme_config.dart' hide AppColors; // Importieren Sie das Theme
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Verwende das Custom-Styling
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Einstellungen',
          style: textTheme.headlineSmall?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil-Bereich
              _buildSectionHeader(context, 'Profil'),
              _buildSettingsCard(
                context,
                icon: Icons.account_circle,
                title: 'Profil bearbeiten',
                subtitle: 'Name, Avatar und persönliche Informationen',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfileEditScreen(),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.m),
              // App-Einstellungen
              _buildSectionHeader(context, 'App-Einstellungen'),
              _buildSettingsCard(
                context,
                icon: Icons.brightness_6,
                title: 'Darstellung',
                subtitle: 'Dark/Light Mode',
                onTap: () {
                  // TODO: Theme-Switcher implementieren
                  _showFeatureComingSoon(context);
                },
              ),
              SizedBox(height: AppSpacing.s),
              _buildSettingsCard(
                context,
                icon: Icons.language,
                title: 'Sprache',
                subtitle: 'App-Sprache ändern',
                onTap: () {
                  // TODO: Sprachauswahl implementieren
                  _showFeatureComingSoon(context);
                },
              ),
              SizedBox(height: AppSpacing.m),
              // Rechtliches
              _buildSectionHeader(context, 'Rechtliches'),
              _buildSettingsCard(
                context,
                icon: Icons.description,
                title: 'Datenschutzerklärung',
                subtitle: 'Informationen zum Datenschutz',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LegalScreen(documentType: 'privacy'),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.s),
              _buildSettingsCard(
                context,
                icon: Icons.gavel,
                title: 'Allgemeine Geschäftsbedingungen',
                subtitle: 'AGB der App',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LegalScreen(documentType: 'terms'),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.s),
              _buildSettingsCard(
                context,
                icon: Icons.info,
                title: 'Impressum',
                subtitle: 'Informationen zum Anbieter',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          LegalScreen(documentType: 'imprint'),
                    ),
                  );
                },
              ),
              SizedBox(height: AppSpacing.m),
              // Account-Aktionen
              _buildSectionHeader(context, 'Account'),
              _buildSettingsCard(
                context,
                icon: Icons.delete,
                title: 'Account löschen',
                subtitle:
                    'Account löschen, Bewertungen bleiben anonym erhalten',
                onTap: () {
                  _showDeleteAccountDialog(context);
                },
                isDanger: true,
              ),
              SizedBox(height: AppSpacing.s),
              _buildSettingsCard(
                context,
                icon: Icons.exit_to_app,
                title: 'Abmelden',
                subtitle: 'Von Ihrem Account abmelden',
                onTap: () {
                  _showLogoutDialog(context);
                },
                isDanger: true,
              ),
              SizedBox(height: AppSpacing.xxl),
              // App-Informationen
              _buildAppInfoSection(context),
            ],
          ),
        ),
      ),
    );
  }

  // Header für Einstellungsabschnitte
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.s),
      child: Text(
        title,
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  // Einstellungs-Karte
  Widget _buildSettingsCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDanger ? theme.colorScheme.error : theme.colorScheme.primary,
          size: 32,
        ),
        title: Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDanger
                ? theme.colorScheme.error
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: AppTypography.bodySmall,
            color: isDanger
                ? theme.colorScheme.error.withOpacity(0.7)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDanger
              ? theme.colorScheme.error
              : theme.colorScheme.onSurface,
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.all(AppSpacing.m),
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.m),
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          String version = '1.0.0';
          String buildNumber = '1';

          if (snapshot.hasData) {
            version = snapshot.data!.version;
            buildNumber = snapshot.data!.buildNumber;
          } else if (snapshot.hasError) {
            print('Fehler beim Laden der App-Info: ${snapshot.error}');
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'App-Informationen',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              SizedBox(height: AppSpacing.s),
              Text(
                'Version: $version',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppSpacing.xs),
              Text(
                'Build: $buildNumber',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppSpacing.s),
              Text(
                '© ${DateTime.now().year} AlpenPreisGrenze. Alle Rechte vorbehalten.',
                style: textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Feature coming soon Dialog
  void _showFeatureComingSoon(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Demnächst verfügbar',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Diese Funktion wird in einer zukünftigen Version der App verfügbar sein.',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Verstanden',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Methode zum Ausloggen
  void _showLogoutDialog(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Abmelden',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Möchten Sie sich wirklich von Ihrem Account abmelden?',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Abbrechen',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pop(context);

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Erfolgreich abgemeldet',
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  }
                } catch (e) {
                  Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Fehler beim Abmelden',
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }
                  print('Fehler beim Ausloggen: $e');
                }
              },
              child: Text(
                'Abmelden',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Account-Löschungsdialog
  void _showDeleteAccountDialog(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    showDialog(
      context: context,
      builder: (context) {
        return DeleteAccountDialog(
          onDeleteConfirmed: () async {
            Navigator.pop(context);
            final userProvider = Provider.of<UserProvider>(
              context,
              listen: false,
            );
            await userProvider.deleteUserAccount(context);
          },
        );
      },
    );
  }

  Future<void> _deleteUserAccount(BuildContext context) async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    BuildContext? dialogContext;

    try {
      final Completer<void> dialogCompleter = Completer<void>();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext buildContext) {
          dialogContext = buildContext;
          return WillPopScope(
            onWillPop: () async => false,
            child: AlertDialog(
              title: Text(
                'Lösche Account...',
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              content: Row(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(width: AppSpacing.s),
                  Text(
                    'Bitte warten...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ).then((_) => dialogCompleter.complete());

      await Future.delayed(Duration(milliseconds: 100));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .delete();

      bool deletionSuccessful = false;
      bool requiresReauth = false;

      try {
        final freshUser = FirebaseAuth.instance.currentUser;
        if (freshUser != null) {
          await freshUser.delete();
          deletionSuccessful = true;
        }
      } on FirebaseAuthException catch (authError) {
        if (authError.code == 'requires-recent-login') {
          requiresReauth = true;
        } else {
          rethrow;
        }
      }

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.of(dialogContext!, rootNavigator: true).pop();
      } else if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      await dialogCompleter.future;

      if (requiresReauth) {
        final bool reauthSuccess = await _showReauthenticateDialog(context);

        if (reauthSuccess) {
          final Completer<void> secondDialogCompleter = Completer<void>();

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext buildContext) {
              return WillPopScope(
                onWillPop: () async => false,
                child: AlertDialog(
                  title: Text(
                    'Lösche Account...',
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  content: Row(
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                      SizedBox(width: AppSpacing.s),
                      Text(
                        'Bitte warten...',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ).then((_) => secondDialogCompleter.complete());

          await Future.delayed(Duration(milliseconds: 100));

          final secondUser = FirebaseAuth.instance.currentUser;
          if (secondUser != null) {
            await secondUser.delete();
          }

          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          await secondDialogCompleter.future;

          deletionSuccessful = true;
        } else {
          return;
        }
      }

      if (deletionSuccessful) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Account erfolgreich gelöscht. Bewertungen bleiben anonym erhalten.',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                ),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }

        await Future.delayed(Duration(seconds: 2));

        try {
          SystemNavigator.pop();
        } catch (e) {
          print('Fehler beim Schließen der App: $e');
          try {
            if (Platform.isAndroid) {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            }
          } catch (fallbackError) {
            print('Fallback Fehler: $fallbackError');
            if (Platform.isAndroid) {
              exit(0);
            }
          }
        }

        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      try {
        if (dialogContext != null && dialogContext!.mounted) {
          Navigator.of(dialogContext!, rootNavigator: true).pop();
        } else if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      } catch (_) {}

      if (context.mounted) {
        String errorMessage = 'Fehler beim Löschen des Accounts';

        if (e is FirebaseAuthException) {
          switch (e.code) {
            case 'requires-recent-login':
              errorMessage =
                  'Sie müssen sich erneut anmelden, um den Account zu löschen';
              break;
            case 'user-not-found':
              errorMessage = 'Benutzer nicht gefunden';
              break;
            default:
              errorMessage = e.message ?? 'Unbekannter Fehler beim Löschen';
          }
        } else {
          errorMessage = e.toString().contains(': ')
              ? e.toString().split(': ').last
              : e.toString();
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary,
              ),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    }
  }

  // Re-Authentifizierungsdialog
  Future<bool> _showReauthenticateDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final TextEditingController _passwordController = TextEditingController();
    final Completer<bool> completer = Completer<bool>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Erneute Anmeldung erforderlich',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aus Sicherheitsgründen müssen Sie sich erneut anmelden, um Ihren Account zu löschen.',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: AppSpacing.m),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Passwort',
                  prefixIcon: Icon(
                    Icons.lock,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                completer.complete(false);
              },
              child: Text(
                'Abbrechen',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bitte geben Sie Ihr Passwort ein',
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                  return;
                }

                Navigator.pop(dialogContext);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext progressDialogContext) {
                    return AlertDialog(
                      title: Text(
                        'Anmeldung...',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      content: Row(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                          SizedBox(width: AppSpacing.s),
                          Text(
                            'Bitte warten...',
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );

                try {
                  final User? user = FirebaseAuth.instance.currentUser;
                  if (user != null && user.email != null) {
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: _passwordController.text,
                    );

                    await user.reauthenticateWithCredential(credential);

                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Erfolgreich angemeldet.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                          backgroundColor: AppColors.success,
                        ),
                      );
                    }

                    completer.complete(true);
                  } else {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                    completer.complete(false);
                  }
                } catch (e) {
                  try {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  } catch (_) {}

                  if (context.mounted) {
                    String errorMessage = 'Fehler bei der Anmeldung';
                    if (e is FirebaseAuthException) {
                      if (e.code == 'wrong-password') {
                        errorMessage = 'Falsches Passwort';
                      } else if (e.code == 'user-not-found') {
                        errorMessage = 'User nicht gefunden';
                      } else {
                        errorMessage = e.message ?? 'Anmeldefehler';
                      }
                    } else {
                      errorMessage = e.toString().contains(': ')
                          ? e.toString().split(': ').last
                          : 'Anmeldefehler';
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          errorMessage,
                          style: textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                          ),
                        ),
                        backgroundColor: theme.colorScheme.error,
                      ),
                    );
                  }

                  completer.complete(false);
                }
              },
              child: Text(
                'Anmelden',
                style: textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );

    completer.future.whenComplete(() {
      _passwordController.dispose();
    });

    return completer.future;
  }
}

// Separate Dialog-Klasse für die Account-Löschung
class DeleteAccountDialog extends StatefulWidget {
  final Function()? onDeleteConfirmed;

  const DeleteAccountDialog({Key? key, this.onDeleteConfirmed})
    : super(key: key);

  @override
  _DeleteAccountDialogState createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final TextEditingController _confirmationController = TextEditingController();

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return AlertDialog(
      title: Text(
        'Account löschen',
        style: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Möchten Sie Ihren Account wirklich löschen?',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: AppSpacing.m),
            Container(
              padding: EdgeInsets.all(AppSpacing.s),
              decoration: BoxDecoration(
                color: theme.colorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: theme.colorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                      SizedBox(width: AppSpacing.s),
                      Expanded(
                        child: Text(
                          'Wichtige Information:',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.s),
                  Text(
                    '• Ihr Account und alle persönlichen Daten werden gelöscht\n'
                    '• Ihre Bewertungen bleiben anonym erhalten\n'
                    '• Dieser Vorgang kann nicht rückgängig gemacht werden',
                    style: textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.m),
            TextField(
              controller: _confirmationController,
              decoration: InputDecoration(
                labelText: 'Geben Sie "LÖSCHEN" ein, um zu bestätigen',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Abbrechen',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        TextButton(
          onPressed: () {
            if (_confirmationController.text.trim() == 'LÖSCHEN') {
              Navigator.pop(context);
              if (widget.onDeleteConfirmed != null) {
                widget.onDeleteConfirmed!();
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Bitte geben Sie "LÖSCHEN" ein, um zu bestätigen',
                    style: textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  backgroundColor: theme.colorScheme.error,
                ),
              );
            }
          },
          child: Text(
            'Löschen',
            style: textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ),
      ],
    );
  }
}
