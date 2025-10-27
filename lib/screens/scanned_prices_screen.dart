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
  List<PriceEntry> _allScannedPricesFromFirestore = []; // Alle abgerufenen Dokumente (vollständige Liste) - für Filter
  List<PriceEntry> _searchResultsFromFirestore = []; // Ergebnisse der Suchabfrage - für Suche
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
    _loadMorePrices(); // Lade Filterergebnisse initial
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

  // Methode: Lade Preise basierend auf dem aktiven Filter (ohne Suchbegriff) mit Paginierung
  Future<void> _loadMorePrices() async {
    // Verhindere parallele Ladevorgänge während des Paginierens
    if (_isLoadingMore || _hasReachedEnd || _searchQuery.isNotEmpty) return; // Kein Laden, wenn Suche aktiv ist

    print("_loadMorePrices: Lade weitere Preise für Filter: $_activeFilter...");
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
            searchQuery: '', // Kein Suchbegriff für Filterabfragen
            activeFilter: _activeFilter,
            startAfterDocument: _lastDocument,
          )
          .first;

      print("Firestore-Filterabfrage: activeFilter=$_activeFilter");
      print("Erhaltene Dokumente: ${querySnapshot.docs.length}");

      if (querySnapshot.docs.isEmpty) {
        print("Keine weiteren Filterdaten verfügbar. Ende der Liste erreicht.");
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasReachedEnd = true; // Markiere, dass keine weiteren Filterdaten vorhanden sind
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

      // Zeige die Filterergebnisse an
      setState(() {
        _filteredScannedPrices = List.from(_allScannedPricesFromFirestore);
      });

    } catch (e) {
      print("Fehler bei der Firestore-Filterabfrage: $e");
      if (_allScannedPricesFromFirestore.isEmpty) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Fehler beim Laden der Filterdaten: $e')),
         );
      }
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  // Methode: Lade Preise basierend auf der Sucheingabe (ohne Paginierung)
  Future<void> _loadSearchResults() async {
    if (_searchQuery.isEmpty) return;

    print("_loadSearchResults: Suche nach: $_searchQuery, Filter: $_activeFilter");
    setState(() => _isLoading = true);

    try {
      final searchResults = await _firebaseService.searchPricesByPrefix(
        _userId,
        50, // Begrenze Suchergebnisse
        _searchQuery,
        _activeFilter,
      );

      print("Erhaltene Suchergebnisse: ${searchResults.length}");

      setState(() {
        _searchResultsFromFirestore = searchResults;
        _filteredScannedPrices = searchResults; // Zeige Suchergebnisse an
        _isLoading = false;
      });

    } catch (e) {
      print("Fehler bei der Firestore-Suchabfrage: $e");
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler bei der Suche: $e')),
      );
    }
  }


  void _onScroll() {
    // Paginierung nur aktiv, wenn *nicht* gesucht wird
    if (_searchQuery.isEmpty && _scrollController.hasClients &&
        _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoadingMore && !_hasReachedEnd) {
      print("_onScroll: Lade weitere Filterergebnisse für Paginierung...");
      _loadMorePrices();
    }
  }

  void _updateSearchQuery(String query) {
    String trimmedQuery = query.trim();
    print("_updateSearchQuery: Neuer Input: '$query', Gecleant: '$trimmedQuery'");

    if (trimmedQuery != _searchQuery) {
        setState(() {
          _searchQuery = trimmedQuery;
        });
        print("_updateSearchQuery: Suchbegriff aktualisiert zu: '$_searchQuery'");

        // Setze Zustand zurück
        setState(() {
          _allScannedPricesFromFirestore.clear(); // Lösche alte Filterdaten
          _searchResultsFromFirestore.clear(); // Lösche alte Suchdaten
          _filteredScannedPrices.clear(); // Lösche Anzeige
          _lastDocument = null; // Setze Paginierung zurück
          _hasReachedEnd = false; // Setze Ende-Zustand zurück
        });

        if (_searchQuery.isNotEmpty) {
            // Wenn Suchbegriff eingegeben wurde, führe die Suchabfrage aus
            _loadSearchResults(); // <--- Rufe die Suchmethode auf
        } else {
            // Wenn Suchbegriff geleert wurde, lade Filterdaten neu
            _loadMorePrices(); // <--- Rufe die Filtermethode auf
        }
    }
  }

  void _updateFilter(String filter) {
    print("_updateFilter: Ändere Filter zu '$filter' und Suchbegriff zu '$_searchQuery'");
    setState(() {
      _activeFilter = filter;
      _allScannedPricesFromFirestore.clear(); // Lösche alle bisher geladenen Filterdaten
      _searchResultsFromFirestore.clear(); // Lösche alle Suchergebnisse
      _filteredScannedPrices.clear(); // Lösche die Anzeigeliste
      _lastDocument = null; // Setze den Startpunkt zurück
      _hasReachedEnd = false; // Setze den End-Status zurück
      // _searchQuery bleibt erhalten, damit nach dem Filterwechsel die Suche fortgesetzt werden kann
    });

    if (_searchQuery.isNotEmpty) {
        // Wenn zuvor gesucht wurde, führe die Suche mit dem neuen Filter neu aus
        _loadSearchResults();
    } else {
        // Wenn nicht gesucht wurde, lade die Filterdaten neu
        _loadMorePrices();
    }
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
                labelText: 'Produkt, Händler oder Stadt suchen',
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
                          _searchQuery.isNotEmpty
                              ? 'Keine Suchergebnisse gefunden.'
                              : 'Keine gescannten Produkte gefunden.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onBackground,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredScannedPrices.length, // Kein extra Platzhalter für Ladebalken, da Suche keine Paginierung hat
                    itemBuilder: (context, index) {
                      // Kein Ladebalken für Suchergebnisse
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