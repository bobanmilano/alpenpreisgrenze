import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/models/product.dart';
import 'package:my_price_tracker_app/screens/comparison_screen.dart';
import 'package:my_price_tracker_app/services/openfoodfacts_service.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import 'package:my_price_tracker_app/theme/app_theme_config.dart'; // Importieren Sie das Theme
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'scanned_prices_screen.dart'; // Importieren Sie den neuen Screen
import 'about_screen.dart';
// --- NEU: Importiere FirebaseService und deine Preis-Utils ---
import '../services/firebase_service.dart';
import '../models/price_entry.dart';
import '../utils/price_utils.dart'; // Stelle sicher, dass deine Hilfsfunktionen verfügbar sind

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
class _HomePageContent extends StatefulWidget {
  // Geändert zu StatefulWidget
  @override
  __HomePageContentState createState() => __HomePageContentState();
}

class __HomePageContentState extends State<_HomePageContent> {
  // Neuer State
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService =
      FirebaseService(); // NEU: FirebaseService Instanz

  // Variablen für den größten Unterschied - Zustandsvariablen
  String? _topProductBarcode; // <--- NEU: Barcode speichern
  String? _topProductName;
  double? _topAtPrice;
  String? _topAtStore;
  String? _topAtCity; // <--- NEU
  String? _topAtQuantity; // <--- NEU
  double? _topDePrice;
  String? _topDeStore;
  String? _topDeCity; // <--- NEU
  String? _topDeQuantity; // <--- NEU
  double? _topPercentageDiff;
  String? _topDisplayUnit;
  String? _topProductImageUrl; // <--- NEU: Produktbild-URL


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

  // NEU: Methode zum Berechnen des Top-Unterschieds
  void _calculateTopDifference() {
    _firebaseService.getAllPricesForCurrentMonth().listen((allPrices) {
      if (allPrices.isEmpty) {
        setState(() {
          _topProductBarcode = null; // <--- Zurücksetzen
          _topProductName = null;
          _topAtPrice = null;
          _topAtStore = null;
          _topAtCity = null; // <--- NEU
          _topAtQuantity = null; // <--- NEU
          _topDePrice = null;
          _topDeStore = null;
          _topDeCity = null; // <--- NEU
          _topDeQuantity = null; // <--- NEU
          _topPercentageDiff = null;
          _topDisplayUnit = null;
          _topProductImageUrl = null; // Oder wie heißt das Feld in PriceEntry?

        });
        return;
      }

      // Gruppiere Preise nach Barcode
      Map<String, List<PriceEntry>> pricesByBarcode = {};
      for (var priceEntry in allPrices) {
        String barcode = priceEntry.barcode;
        pricesByBarcode.putIfAbsent(barcode, () => []).add(priceEntry);
      }

      double maxDiff = 0;
      PriceEntry? topAtPrice;
      PriceEntry? topDePrice;
      String? topBarcode; // <--- NEU: Barcode temporär speichern
      String? topDisplayUnit;

      for (var entry in pricesByBarcode.entries) {
        String barcode = entry.key;
        List<PriceEntry> prices = entry.value;

        List<PriceEntry> atPrices = prices
            .where((p) => p.country == 'Österreich')
            .toList();
        List<PriceEntry> dePrices = prices
            .where((p) => p.country == 'Deutschland')
            .toList();

        if (atPrices.isEmpty || dePrices.isEmpty) continue;

        atPrices.sort((a, b) => b.price.compareTo(a.price));
        dePrices.sort((a, b) => a.price.compareTo(b.price));

        PriceEntry currentAtPrice = atPrices.first;
        PriceEntry currentDePrice = dePrices.first;

        final atProductWeight = currentAtPrice.quantity ?? 'N/A';
        final deProductWeight = currentDePrice.quantity ?? 'N/A';

        final atPricePerUnit = calculatePricePerUnit(
          currentAtPrice.price,
          atProductWeight,
        );
        final dePricePerUnit = calculatePricePerUnit(
          currentDePrice.price,
          deProductWeight,
        );

        double currentDiff = 0;
        if (atPricePerUnit != null &&
            dePricePerUnit != null &&
            dePricePerUnit != 0) {
          currentDiff =
              ((atPricePerUnit - dePricePerUnit) / dePricePerUnit) * 100;
        } else if (dePricePerUnit == 0) {
          continue;
        } else {
          if (currentDePrice.price != 0) {
            currentDiff =
                ((currentAtPrice.price - currentDePrice.price) /
                    currentDePrice.price) *
                100;
          } else {
            continue;
          }
        }

        if (currentDiff > maxDiff) {
          maxDiff = currentDiff;
          topAtPrice = currentAtPrice;
          topDePrice = currentDePrice;
          topBarcode = currentAtPrice
              .barcode; // <--- Barcode des aktuellen Produkts speichern
          topDisplayUnit = getDisplayUnit(atProductWeight);

          // --- NEU: Speichere auch Stadt und Menge ---
          _topAtCity = currentAtPrice.city;
          _topDeCity = currentDePrice.city;
          _topAtQuantity = currentAtPrice.quantity;
          _topDeQuantity = currentDePrice.quantity;
        _topProductImageUrl = currentAtPrice.productImageURL; // Oder wie heißt das Feld in PriceEntry?

          // --- ENDE NEU ---
        }
      }

      setState(() {
        if (topAtPrice != null && topDePrice != null && topBarcode != null) {
          // <--- topBarcode prüfen
          _topProductBarcode = topBarcode; // <--- Zustandsvariable setzen
          _topProductName = topAtPrice.productName;
          _topAtPrice = topAtPrice.price;
          _topAtStore = topAtPrice.store;
          _topDePrice = topDePrice.price;
          _topDeStore = topDePrice.store;
          _topPercentageDiff = maxDiff;
          _topDisplayUnit = topDisplayUnit ?? 'Stück';

        } else {
          _topProductBarcode = null; // <--- Zurücksetzen
          _topProductName = null;
          _topAtPrice = null;
          _topAtStore = null;
          _topAtCity = null; // <--- NEU
          _topAtQuantity = null; // <--- NEU
          _topDePrice = null;
          _topDeStore = null;
          _topDeCity = null; // <--- NEU
          _topDeQuantity = null; // <--- NEU
          _topPercentageDiff = null;
          _topDisplayUnit = null;
        }
      });
    });
  }

  @override
  void initState() {
    super.initState();
    // Initialisiere die Berechnung
    _calculateTopDifference();
  }

    @override
  Widget build(BuildContext context) {
    // Verwende das Custom-Styling
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Hole die aktuelle Firebase UID
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

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
      // --- NEU: SingleChildScrollView hinzugefügt ---
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
          // --- Optional: Padding entfernen oder anpassen, da SingleChildScrollView den Inhalt scrollen lässt ---
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Column(
              // --- BEHAELT: mainAxisAlignment: MainAxisAlignment.center ---
              // Dies zentriert den Inhalt VOR dem Scrollen, wenn genug Platz ist.
              // Wenn der Inhalt zu lang ist, scrollt der SingleChildScrollView.
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
                  CommunityMaterialIcons.barcode_scan,
                  'Produkt-Barcode scannen',
                  context,
                  theme,
                ),
                SizedBox(height: AppSpacing.s),
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
                // --- NEU: Karte für den Top-Unterschied mit Tap-Handler und erweiterten Daten ---
                if (_topProductName != null &&
                    _topAtPrice != null &&
                    _topDePrice != null &&
                    _topPercentageDiff != null &&
                    _topProductBarcode != null) // <--- _topProductBarcode prüfen
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                    child: GestureDetector(
                      // <--- GestureDetector hinzufügen
                      onTap: () async {
                        // <--- NEU: async onTap-BLOCK
                        // Zeige Ladeanzeige (optional, z.B. mit einem SnackBar)
                        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lade Produkt...')));

                        try {
                          // Lade das vollständige Produktobjekt
                          final Product loadedProduct =
                              await OpenFoodFactsService.fetchProduct(
                            _topProductBarcode!,
                          );

                          // Prüfe, ob das Laden erfolgreich war
                          if (loadedProduct.barcode != null) {
                            // Annahme: Ein erfolgreich geladenes Produkt hat eine Barcode
                            // Navigiere zur ComparisonScreen mit dem geladenen Produkt
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ComparisonScreen(
                                  product:
                                      loadedProduct, // <--- GELADENES OBJEKT ÜBERGEBEN
                                ),
                              ),
                            );
                          } else {
                            // Fehler: Produkt konnte nicht geladen werden
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Produkt mit Barcode $_topProductBarcode konnte nicht geladen werden.',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          // Fehler beim Laden abfangen
                          print(
                            "Fehler beim Laden des Produkts aus OpenFoodFacts: $e",
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Fehler beim Laden des Produkts: $e'),
                            ),
                          );
                        }
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: AppSpacing.l),
                          Text(
                            'Der aktuelle "Hall of Shame" Superstar: ',//  im ${formatMonthYear(DateTime.now())}:',
                            style: textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.left,
                          ),

                          SizedBox(height: AppSpacing.s),
                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.s),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          'Produkt: $_topProductName',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                      ),
                                      // Klickbarkeits-Hinweis (Pfeil)
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 16,
                                        color: theme.colorScheme.onSurfaceVariant
                                            .withOpacity(0.6),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSpacing.xs),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Fahne und Stadtname oben
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Image.asset(
                                                  'assets/logos/at-fahne.png',
                                                  width: 24,
                                                  height: 24,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Icon(
                                                          Icons.flag,
                                                          size: 32,
                                                        );
                                                      },
                                                ),
                                                SizedBox(width: 8),
                                                // Dynamischer Stadtname mit ValueListenableBuilder
                                                if (_topAtCity != null)
                                                  Text(
                                                    '$_topAtCity',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: 20.0,
                                              ), // Abstand von links
                                              child: RichText(
                                                text: TextSpan(
                                                  style: DefaultTextStyle.of(
                                                    context,
                                                  ).style, // Standardstil des Widgets
                                                  children: <TextSpan>[
                                                    TextSpan(
                                                      text:
                                                          '€${_topAtPrice!.toStringAsFixed(2)} ',
                                                      style: TextStyle(
                                                        fontSize:
                                                            (Theme.of(context)
                                                                    .textTheme
                                                                    .titleLarge
                                                                    ?.fontSize ??
                                                                18) *
                                                            1.5, // 1.5-fache Größe
                                                        fontWeight: FontWeight
                                                            .bold, // Fett
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface, // Farbe an Theme anpassen
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '(${_topAtQuantity ?? 'N/A'})',
                                                      style: TextStyle(
                                                        fontSize:
                                                            (Theme.of(context)
                                                                    .textTheme
                                                                    .titleLarge
                                                                    ?.fontSize ??
                                                                18) *
                                                            0.75, // Halbe Größe (0.5 * 1.5)
                                                        fontWeight: FontWeight
                                                            .normal, // Nicht fett
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant, // Variante Farbe für Menge
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: 20.0,
                                              ), // Abstand von links
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildStoreLogoOrText(
                                                    context,
                                                    _topAtStore ?? 'Unbekannt',
                                                  ),
                                                  if (_topAtPrice != null &&
                                                      _topAtQuantity != null)
                                                    _buildPricePerUnitInfo(
                                                      _topAtPrice!,
                                                      _topAtQuantity!,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // --- NEU: Produktbild in der Mitte ---
                                      if (_topProductImageUrl != null)
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: AppSpacing.s), // Optional: Abstand
                                          child: ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0), // Optional: Ecken abrunden
                                            child: Image.network(
                                              _topProductImageUrl!,
                                              width: 60, // Anpassen der Größe
                                              height: 60,
                                              fit: BoxFit.cover, // Oder BoxFit.contain, je nach Bedarf
                                              errorBuilder: (context, error,
                                                  stackTrace) {
                                                // Falls das Laden des Bildes fehlschlägt, zeige ein Platzhalter-Icon
                                                return Icon(
                                                  Icons.image_not_supported,
                                                  size: 40,
                                                  color: Colors.grey,
                                                );
                                              },
                                            ),
                                          ),
                                        )
                                      else
                                        // Falls kein Bild vorhanden ist, zeige einen Platzhalter
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: AppSpacing.s),
                                          child: Icon(
                                            Icons.image_not_supported,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      // --- ENDE NEU ---
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // --- NEU: DE: Fahne und Stadtname ---
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Image.asset(
                                                  'assets/logos/de-fahne.png', // Stelle sicher, dass diese Datei existiert
                                                  width: 24,
                                                  height: 24,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Icon(
                                                          Icons.flag,
                                                          size: 32,
                                                        );
                                                      },
                                                ),
                                                SizedBox(width: 8),
                                                if (_topDeCity != null)
                                                  Text(
                                                    '$_topDeCity',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            // --- ENDE NEU ---
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: 20.0,
                                              ), // Abstand von links
                                              child: RichText(
                                                text: TextSpan(
                                                  style: DefaultTextStyle.of(
                                                    context,
                                                  ).style, // Standardstil des Widgets
                                                  children: <TextSpan>[
                                                    TextSpan(
                                                      text:
                                                          '€${_topDePrice!.toStringAsFixed(2)} ',
                                                      style: TextStyle(
                                                        fontSize:
                                                            (Theme.of(context)
                                                                    .textTheme
                                                                    .titleLarge
                                                                    ?.fontSize ??
                                                                18) *
                                                            1.5, // 1.5-fache Größe
                                                        fontWeight: FontWeight
                                                            .bold, // Fett
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurface, // Farbe an Theme anpassen
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text:
                                                          '(${_topDeQuantity ?? 'N/A'})',
                                                      style: TextStyle(
                                                        fontSize:
                                                            (Theme.of(context)
                                                                    .textTheme
                                                                    .titleLarge
                                                                    ?.fontSize ??
                                                                18) *
                                                            0.75, // Halbe Größe (0.5 * 1.5)
                                                        fontWeight: FontWeight
                                                            .normal, // Nicht fett
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant, // Variante Farbe für Menge
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: EdgeInsets.only(
                                                left: 20.0,
                                              ), // Abstand von links
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  _buildStoreLogoOrText(
                                                    context,
                                                    _topDeStore ?? 'Unbekannt',
                                                  ),
                                                  if (_topDePrice != null &&
                                                      _topDeQuantity != null)
                                                    _buildPricePerUnitInfo(
                                                      _topDePrice!,
                                                      _topDeQuantity!,
                                                    ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: AppSpacing.s),
                                  Text(
                                    'Österreich-Aufschlag: ${_topPercentageDiff!.toStringAsFixed(2)} % (pro ${_topDisplayUnit!})',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
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
                SizedBox(height: AppSpacing.xl),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScanScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.m,
                    ),
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
      ),
      // --- ENDE NEU ---
      floatingActionButton: currentUserId == 'LK0UJ40jzkcpuCcgxHqFR5I8OoW2'
          ? FloatingActionButton.extended(
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
            )
          : null, // Der Button wird nur für die spezifische UID angezeigt
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

  // --- NEU: Hilfsfunktion für das Händler-Logo (dein bestehendes Widget) ---
  Widget _buildStoreLogoOrText(BuildContext context, String storeName) {
    String lowerCaseName = storeName.toLowerCase();
    if (lowerCaseName == 'aldisüd') {
      lowerCaseName = 'aldisued';
    }
    String logoPath = 'assets/logos/$lowerCaseName.jpg';
    String logoPathUpper = 'assets/logos/$lowerCaseName.JPG';

    return Image.asset(
      logoPath,
      height: 32, // Geringere Höhe
      width: 72, // Geringere Breite
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          logoPathUpper,
          height: 32, // Geringere Höhe
          width: 72, // Geringere Breite
          errorBuilder: (context, error, stackTrace) {
            return Text(
              storeName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            );
          },
        );
      },
    );
  }

  // --- NEU: Hilfsfunktion für Preis pro Einheit ---
  Widget _buildPricePerUnitInfo(double price, String quantity) {
    final pricePerUnit = calculatePricePerUnit(price, quantity);
    final displayUnit = getDisplayUnit(quantity) ?? 'Stück';

    if (pricePerUnit != null) {
      return Text(
        '€${pricePerUnit.toStringAsFixed(3)} / $displayUnit',
        style: TextStyle(
          fontSize: 12,
          color: Colors.blue, // Oder eine andere Farbe für den Einheitspreis
        ),
      );
    } else {
      // Falls calculatePricePerUnit null zurückgibt, zeige zumindest die Menge an
      return Text(
        'Menge: $quantity',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
  }
}
