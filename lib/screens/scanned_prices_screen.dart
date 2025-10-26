// lib/screens/scanned_prices_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import 'package:my_price_tracker_app/widgets/product_list_item.dart';
import '../services/firebase_service.dart';
import '../models/price_entry.dart';
import '../services/openfoodfacts_service.dart';
import '../screens/comparison_screen.dart';
import 'package:my_price_tracker_app/theme/app_theme_config.dart'; // Importieren Sie das Theme

class ScannedPricesScreen extends StatefulWidget {
  @override
  _ScannedPricesScreenState createState() => _ScannedPricesScreenState();
}

class _ScannedPricesScreenState extends State<ScannedPricesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 15; // Anzahl der Einträge pro Abfrage
  List<PriceEntry> _allScannedPricesFromFirestore = []; // Alle abgerufenen Dokumente (vollständige Liste)
  List<PriceEntry> _filteredScannedPrices = []; // Gefilterte Liste für die Anzeige
  bool _isLoading = false;
  bool _isLoadingMore = false; // Unterscheidet zwischen Initial- und Paginierungs-Laden
  late String _userId; // Dynamische Benutzer-ID
  DocumentSnapshot? _lastDocument; // Speichert das letzte Firestore-Dokument
  bool _hasReachedEnd = false; // Zeigt an, ob alle Dokumente geladen wurden

  // Suchbegriff
  String _searchQuery = '';

  // Aktiver Filter
  String _activeFilter = 'alle_scans'; // Standard: "Alle Scans"

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadMorePrices();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadUserId() async {
    try {
      setState(() {
        _userId = _firebaseService.getCurrentUserId();
      });
    } catch (e) {
      print('Fehler beim Abrufen der Benutzer-ID: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Freigabe des Controllers
    super.dispose();
  }

  // Neue Methode: Nur die Filterung durchführen
  void _applyFilters() {
    print("_applyFilters: Wende Filter an. Suchbegriff: $_searchQuery");
    if (_searchQuery.isEmpty) {
      // Wenn keine Suche, zeige alle abgerufenen Preise an
      setState(() {
        _filteredScannedPrices = List.from(_allScannedPricesFromFirestore);
      });
    } else {
      // Wenn Suche, filtere die abgerufenen Preise
      setState(() {
        _filteredScannedPrices = _allScannedPricesFromFirestore.where((entry) {
          final productName = entry.productName?.toLowerCase() ?? '';
          final city = entry.city?.toLowerCase() ?? ''; // Stelle sicher, dass 'city' im PriceEntry-Modell vorhanden ist
          final searchLower = _searchQuery.toLowerCase();
          return productName.contains(searchLower) || city.contains(searchLower);
        }).toList();
      });
    }
    print("_applyFilters: Gefilterte Anzahl: ${_filteredScannedPrices.length}");
  }


  Future<void> _loadMorePrices() async {
    // Verhindere parallele Ladevorgänge während des Paginierens
    if (_isLoadingMore || _hasReachedEnd) return;

    print("_loadMorePrices: Lade weitere Preise...");
    if (_allScannedPricesFromFirestore.isEmpty) {
      // Erster Ladevorgang
      setState(() => _isLoading = true);
    } else {
      // Paginierungs-Ladevorgang
      setState(() => _isLoadingMore = true);
    }


    try {
      final querySnapshot = await _firebaseService
          .getUserScannedPricesWithFilter(
            _userId,
            _pageSize,
            searchQuery: '', // Wichtig: Kein Suchbegriff hier! Die Suche erfolgt lokal.
            activeFilter: _activeFilter,
            startAfterDocument: _lastDocument,
          )
          .first;

      print("Firestore-Abfrage (ohne Suchfilter): activeFilter=$_activeFilter");
      print("Erhaltene Dokumente: ${querySnapshot.docs.length}");

      if (querySnapshot.docs.isEmpty) {
        print("Keine weiteren Daten verfügbar. Ende der Liste erreicht.");
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasReachedEnd = true; // Markiere, dass keine weiteren Daten vorhanden sind
        });
        return;
      }

      // Konvertiere Firestore-Dokumente in PriceEntry-Objekte
      final newPrices = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PriceEntry.fromMap(data, doc.id);
      }).toList();

      setState(() {
        _allScannedPricesFromFirestore.addAll(newPrices);
        _lastDocument = querySnapshot.docs.isNotEmpty
            ? querySnapshot.docs.last // Speichere das letzte Firestore-Dokument
            : null;
        _isLoading = false;
        _isLoadingMore = false;
      });

      // Wende die aktuelle Suche auf die neu geladenen Daten an
      _applyFilters();

    } catch (e) {
      print("Fehler bei der Firestore-Abfrage: $e");
      if (_allScannedPricesFromFirestore.isEmpty) { // Nur Fehler anzeigen, wenn gar nichts geladen ist
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Fehler beim Laden der Preise: $e')),
         );
      }
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }


  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore && // Verhindere Laden, wenn gerade geladen wird
        !_hasReachedEnd) { // Verhindere Laden, wenn Ende erreicht
      print("_onScroll: Lade weitere Preise für Paginierung...");
      _loadMorePrices();
    }
  }

  void _updateSearchQuery(String query) {
    setState(() {
      _searchQuery = query.trim();
      // Kein Zurücksetzen von _allScannedPricesFromFirestore oder _lastDocument mehr
      // _allScannedPricesFromFirestore behält alle bisher geladenen Daten
    });
    print("_updateSearchQuery: Neuer Suchbegriff: $_searchQuery");
    // Kein erneutes Laden aus der Datenbank, sondern nur lokale Filterung
    _applyFilters();
  }

  void _updateFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _allScannedPricesFromFirestore.clear(); // Lösche alle bisher geladenen Daten
      _filteredScannedPrices.clear(); // Lösche die Anzeigeliste
      _lastDocument = null; // Setze den Startpunkt zurück
      _hasReachedEnd = false; // Setze den End-Status zurück
    });
    _loadMorePrices(); // Lade neue Daten basierend auf dem Filter
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Filter auswählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Meine Scans'),
              onTap: () {
                Navigator.pop(context);
                _updateFilter('meine_scans');
              },
            ),
            ListTile(
              leading: Icon(Icons.group),
              title: Text('Alle Scans'),
              onTap: () {
                Navigator.pop(context);
                _updateFilter('alle_scans');
              },
            ),
            ListTile(
              leading: Icon(Icons.update),
              title: Text('Aktuelle Scans'),
              onTap: () {
                Navigator.pop(context);
                _updateFilter('aktuelle_scans');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gescannte Produkte',
              style: textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              _activeFilter == 'meine_scans'
                  ? 'Meine Scans'
                  : _activeFilter == 'alle_scans'
                      ? 'Alle Scans'
                      : 'Aktuelle Scans',
              style: textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.7),
              ),
            ),
          ],
        ),
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: TextField(
              onChanged: _updateSearchQuery,
              decoration: InputDecoration(
                labelText: 'Produkt oder Stadt suchen',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _filteredScannedPrices.isEmpty
                ? _isLoading // Zeige Ladeanzeige nur beim ersten Laden
                    ? Center(child: CircularProgressIndicator())
                    : Center(
                        child: Text(
                          'Keine gescannten Produkte gefunden.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredScannedPrices.length + (_isLoadingMore ? 1 : 0), // +1 für Ladebalken am Ende
                    itemBuilder: (context, index) {
                      if (index == _filteredScannedPrices.length) {
                        // Zeige Ladebalken am Ende, wenn mehr geladen wird
                        return Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: CircularProgressIndicator(),
                        ));
                      }

                      final priceEntry = _filteredScannedPrices[index];
                      return ProductListItem(
                        productImageUrl: priceEntry.productImageURL,
                        productName: priceEntry.productName,
                        manufacturer: priceEntry.brands,
                        price: priceEntry.price,
                        city: priceEntry.city,
                        storeName: priceEntry.store,
                        onTap: () async {
                          try {
                            final product =
                                await OpenFoodFactsService.fetchProduct(
                              priceEntry.barcode,
                            );

                            if (product.barcode != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ComparisonScreen(product: product),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Produkt mit Barcode ${priceEntry.barcode} nicht gefunden.',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Fehler: $e'),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}