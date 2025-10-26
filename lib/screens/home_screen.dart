// lib/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import 'package:my_price_tracker_app/theme/app_theme_config.dart'; // Importieren Sie das Theme
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'scanned_prices_screen.dart'; // Importieren Sie den neuen Screen
import 'about_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    _HomePageContent(),
    ScanScreen(),
    ScannedPricesScreen(), // NEU: History-Tab hinzugefügt
    SettingsScreen(),
    AboutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Verwende das Theme
    final theme = Theme.of(context);

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Start'),
          BottomNavigationBarItem(
            icon: Icon(CommunityMaterialIcons.barcode_scan),
            label: 'Scannen',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history), // NEU: History-Icon
            label: 'Verlauf',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Einstellungen',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Über uns'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: theme.colorScheme.onSurface.withOpacity(0.6),
        type: BottomNavigationBarType.fixed, // Für mehr als 3 Items
        backgroundColor: theme.colorScheme.background,
      ),
    );
  }
}

// --- ANPASSUNG: Neuer Inhalt für die Startseite ---
class _HomePageContent extends StatelessWidget {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // Methode zum Aktualisieren der user_ids
  Future<void> updateUserIds(BuildContext context) async {
    try {
      // Hole die aktuelle userId des angemeldeten Benutzers
      final String newUserId =
          FirebaseAuth.instance.currentUser?.uid ?? 'UNKNOWN_USER_ID';

      // Hole alle Einträge mit der alten test_user_id
      final QuerySnapshot querySnapshot = await firestore
          .collection('prices')
          .where('user_id', isNotEqualTo: newUserId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Keine Einträge zur Aktualisierung gefunden.'),
          ),
        );
        return;
      }

      // Durchlaufe alle gefundenen Dokumente und aktualisiere die user_id
      for (final doc in querySnapshot.docs) {
        final docId = doc.id;
        await firestore.collection('prices').doc(docId).update({
          'user_id': newUserId,
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${querySnapshot.docs.length} Einträge erfolgreich aktualisiert.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Aktualisieren der Einträge: $e')),
      );
    }
  }

  // Methode zum Löschen alter Einträge
  Future<void> deleteOldEntries(BuildContext context) async {
    try {
      // Hole alle Einträge mit der alten test_user_id
      final QuerySnapshot querySnapshot = await firestore
          .collection('prices')
          .where('user_id', isEqualTo: 'test_user_id')
          .get();

      if (querySnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Keine Einträge zum Löschen gefunden.')),
        );
        return;
      }

      // Durchlaufe alle gefundenen Dokumente und lösche sie
      for (final doc in querySnapshot.docs) {
        final docId = doc.id;
        await firestore.collection('prices').doc(docId).delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${querySnapshot.docs.length} Einträge erfolgreich gelöscht.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Löschen der Einträge: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verwende das Custom-Styling
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logos/alpenpreisgrenze.png',
          height: 60, // Passen Sie die Höhe an
        ),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
      ),
      body: Container(
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
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.m),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Vereint gegen den Österreich-Aufschlag.',
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.l),
              Text(
                'Schliess dich der AlpenPreisGrenze Community an und finde Österreich-Aufschläge '
                'bei Lebensmitteln. Gemeinsam können wir etwas bewegen!',
                style: textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: AppSpacing.xl),
              _buildGoalItem(
                Icons.remove_red_eye,
                'Österreich-Aufschlag entdecken',
                context,
                theme,
              ),
              SizedBox(height: AppSpacing.s),
              _buildGoalItem(
                Icons.share,
                'Auf Social-Media teilen',
                context,
                theme,
              ),
              SizedBox(height: AppSpacing.s),
              _buildGoalItem(
                Icons.mail,
                'Beschwerde-E-Mail senden',
                context,
                theme,
              ),
              SizedBox(height: AppSpacing.s),
              _buildGoalItem(
                Icons.euro,
                'Produkte/Preise hinzufügen',
                context,
                theme,
              ),
              SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ScanScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.m),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                  ),
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 4,
                ),
                child: Text(
                  'Jetzt Produkt scannen',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
       floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: Text('Option auswählen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: Icon(Icons.update),
                    title: Text('User-IDs aktualisieren'),
                    onTap: () {
                      Navigator.pop(context); // Schließe den Dialog
                      updateUserIds(context);
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.delete),
                    title: Text('Alte Einträge löschen'),
                    onTap: () {
                      Navigator.pop(context); // Schließe den Dialog
                      deleteOldEntries(context);
                    },
                  ),
                ],
              ),
            ),
          );
        },
        icon: Icon(Icons.build),
        label: Text('Verwalten'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildGoalItem(
    IconData icon,
    String text,
    BuildContext context,
    ThemeData theme,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Row(
      children: [
        Icon(icon, size: 30, color: theme.colorScheme.primary),
        SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(
            text,
            style: textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
