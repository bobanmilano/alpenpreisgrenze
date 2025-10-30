// lib/screens/scanned_prices_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import 'package:my_price_tracker_app/widgets/product_list_item.dart';
import '../services/firebase_service.dart';
import '../models/price_entry.dart';
import '../services/openfoodfacts_service.dart';
import '../screens/comparison_screen.dart';
import 'package:my_price_tracker_app/theme/app_theme_config.dart';

class ScannedPricesScreen extends StatefulWidget {
  @override
  _ScannedPricesScreenState createState() => _ScannedPricesScreenState();
}

class _ScannedPricesScreenState extends State<ScannedPricesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 15;
  final TextEditingController _searchController = TextEditingController();

  String _userId = '';
  DocumentSnapshot? _lastDocument;
  bool _hasReachedEnd = false;
  bool _isLoading = false;

  String _activeFilter = 'alle_scans';
  List<PriceEntry> _displayedPrices = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadUserId() async {
    try {
      final userId = _firebaseService.getCurrentUserId();
      if (mounted) setState(() => _userId = userId);
    } catch (e) {
      print('Fehler beim Abrufen der Benutzer-ID: $e');
    }
  }

  Future<void> _loadInitialData() async {
    if (_userId.isEmpty) return;
    setState(() => _isLoading = true);
    await _loadFilterData(isInitialLoad: true);
  }

  Future<void> _loadFilterData({bool isInitialLoad = false}) async {
    if (_userId.isEmpty) return;

    try {
      final querySnapshot = await _firebaseService
          .getUserScannedPricesWithFilter(
            _userId,
            _pageSize,
            searchQuery: '',
            activeFilter: _activeFilter,
            startAfterDocument: isInitialLoad ? null : _lastDocument,
          )
          .first;

      final newPrices = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return PriceEntry.fromMap(data, doc.id);
      }).toList();

      if (mounted) {
        setState(() {
          if (isInitialLoad) {
            _displayedPrices = newPrices;
            _lastDocument = querySnapshot.docs.last;
            _hasReachedEnd = querySnapshot.docs.length < _pageSize;
          } else {
            _displayedPrices.addAll(newPrices);
            _lastDocument = querySnapshot.docs.last;
            if (querySnapshot.docs.length < _pageSize) _hasReachedEnd = true;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        if (isInitialLoad) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Fehler beim Laden: $e')));
        }
      }
    }
  }

  // 🔍 LUPEN-BUTTON: Suche ODER Zurücksetzen
  void _onSearchPressed() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      // Leeres Feld → zeige alle Scans
      _resetToFullList();
    } else {
      // Führe Suche durch
      _performSearch(query);
    }
  }

  // 🗙 X-BUTTON: Immer zurücksetzen
  void _onResetPressed() {
    _searchController.clear();
    _resetToFullList();
  }

  void _resetToFullList() {
    setState(() => _isLoading = true);
    _loadInitialData(); // Lädt "Alle Scans" etc.
  }

  Future<void> _performSearch(String query) async {
    if (_userId.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final results = await _firebaseService.searchPricesByPrefix(
        _userId,
        50,
        query,
        _activeFilter,
      );
      if (mounted) {
        setState(() {
          _displayedPrices = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Fehler bei der Suche: $e')));
      }
    }
  }

  void _onScroll() {
    // Paginierung nur im Filtermodus (niemals bei Suche)
    if (_searchController.text.trim().isNotEmpty) return;

    if (_searchController.text.trim().isNotEmpty) {
      FocusScope.of(context).unfocus();
    }

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 100 &&
        !_isLoading &&
        !_hasReachedEnd) {
      _loadFilterData();
    }
  }

  void _updateFilter(String filter) {
    if (filter == _activeFilter) return;
    _activeFilter = filter;
    _resetToFullList(); // Filterwechsel → immer volle Liste
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
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
            icon: Icon(Icons.filter_alt),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
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
          child: Column(
            children: [
              // 🔍 SUCHZEILE MIT ZWEI BUTTONS VORNE
              Padding(
                padding: EdgeInsets.all(AppSpacing.m),
                child: Row(
                  children: [
                    // 🗙 RESET-BUTTON (links)
                    ElevatedButton(
                      onPressed: _onResetPressed,
                      style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.all(AppSpacing.s), // z. B. 8.0
                        elevation: 0,
                      ),
                      child: Icon(
                        Icons.clear,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        size: 20,
                      ),
                    ),
                    SizedBox(width: AppSpacing.s),
                    // 🔍 SUCH-BUTTON (rechts davon)
                    ElevatedButton(
                      onPressed: _onSearchPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        padding: EdgeInsets.all(AppSpacing.s),
                        elevation: 0,
                      ),
                      child: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: AppSpacing.s),
                    // TEXTFELD
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Produkt, Händler oder Stadt',
                          border: OutlineInputBorder(),
                        ),
                        
                      ),
                    ),
                  ],
                ),
              ),
              // 📋 LISTE
              Expanded(
                child: _displayedPrices.isEmpty
                    ? _isLoading
                          ? Center(child: CircularProgressIndicator())
                          : Center(
                              child: Text(
                                _searchController.text.trim().isNotEmpty
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
                        itemCount: _displayedPrices.length,
                        itemBuilder: (context, index) {
                          final entry = _displayedPrices[index];
                          return ProductListItem(
                            key: ValueKey(entry.id),
                            productImageUrl: entry.productImageURL,
                            productName: entry.productName,
                            manufacturer: entry.brands,
                            price: entry.price,
                            city: entry.city,
                            storeName: entry.store,
                            onTap: () async {
                              try {
                                final product =
                                    await OpenFoodFactsService.fetchProduct(
                                      entry.barcode,
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
                                        'Produkt mit Barcode ${entry.barcode} nicht gefunden.',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Fehler: $e')),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
