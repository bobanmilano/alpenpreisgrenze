import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:community_material_icon/community_material_icon.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/models/product.dart';
import 'package:my_price_tracker_app/screens/comparison_screen.dart';
import 'package:my_price_tracker_app/services/openfoodfacts_service.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import 'package:my_price_tracker_app/theme/app_theme_config.dart';
import 'package:my_price_tracker_app/utils/app_constants.dart';
import 'package:my_price_tracker_app/utils/string_utils.dart';
import 'scan_screen.dart';
import 'settings_screen.dart';
import 'scanned_prices_screen.dart';
import 'about_screen.dart';

import '../services/firebase_service.dart';
import '../models/price_entry.dart';
import '../utils/price_utils.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    _HomePageContent(),
    ScanScreen(),
    ScannedPricesScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Verlauf'),
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
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.background,
      ),
    );
  }
}

class _HomePageContent extends StatefulWidget {
  @override
  __HomePageContentState createState() => __HomePageContentState();
}

class __HomePageContentState extends State<_HomePageContent> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isLoadingTopProduct = true;

  String? _topProductBarcode;
  String? _topProductName;
  double? _topAtPrice;
  String? _topAtStore;
  String? _topAtCity;
  String? _topAtQuantity;
  double? _topDePrice;
  String? _topDeStore;
  String? _topDeCity;
  String? _topDeQuantity;
  double? _topPercentageDiff;
  String? _topDisplayUnit;
  String? _topProductImageUrl;

  String _getDisplayString(String? input) {
    if (input == null) return 'Unbekannt';
    return toProperCase(input);
  }

  Future<void> updateUserIds(BuildContext context) async {
    try {
      final String newUserId =
          FirebaseAuth.instance.currentUser?.uid ?? 'UNKNOWN_USER_ID';

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

  Future<void> deleteOldEntries(BuildContext context) async {
    try {
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

  void _calculateTopDifference() {
    _firebaseService.getAllPricesForCurrentMonth().listen((allPrices) {
      if (allPrices.isEmpty) {
        setState(() {
          _topProductBarcode = null;
          _topProductName = null;
          _topAtPrice = null;
          _topAtStore = null;
          _topAtCity = null;
          _topAtQuantity = null;
          _topDePrice = null;
          _topDeStore = null;
          _topDeCity = null;
          _topDeQuantity = null;
          _topPercentageDiff = null;
          _topDisplayUnit = null;
          _topProductImageUrl = null;
          _isLoadingTopProduct = false;
        });
        return;
      }

      Map<String, List<PriceEntry>> pricesByBarcode = {};
      for (var priceEntry in allPrices) {
        String barcode = priceEntry.barcode;
        pricesByBarcode.putIfAbsent(barcode, () => []).add(priceEntry);
      }

      double maxDiff = 0;
      PriceEntry? topAtPrice;
      PriceEntry? topDePrice;
      String? topBarcode;
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
          topBarcode = currentAtPrice.barcode;
          topDisplayUnit = getDisplayUnit(atProductWeight);

          _topAtCity = currentAtPrice.city;
          _topDeCity = currentDePrice.city;
          _topAtQuantity = currentAtPrice.quantity;
          _topDeQuantity = currentDePrice.quantity;
          _topProductImageUrl = currentAtPrice.productImageURL;
        }
      }

      setState(() {
        if (topAtPrice != null && topDePrice != null && topBarcode != null) {
          _topProductBarcode = topBarcode;
          _topProductName = topAtPrice.productName;
          _topAtPrice = topAtPrice.price;
          _topAtStore = topAtPrice.store;
          _topDePrice = topDePrice.price;
          _topDeStore = topDePrice.store;
          _topPercentageDiff = maxDiff;
          _topDisplayUnit = topDisplayUnit ?? 'Stück';
          _isLoadingTopProduct = false;
        } else {
          _topProductBarcode = null;
          _topProductName = null;
          _topAtPrice = null;
          _topAtStore = null;
          _topAtCity = null;
          _topAtQuantity = null;
          _topDePrice = null;
          _topDeStore = null;
          _topDeCity = null;
          _topDeQuantity = null;
          _topPercentageDiff = null;
          _topDisplayUnit = null;
          _topProductImageUrl = null;
        }
        _isLoadingTopProduct = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    setState(() {
      _isLoadingTopProduct = true;
    });

    _calculateTopDifference();
  }

  Future<void> _normalizeStrings(BuildContext context) async {
    int updatedCount = 0;
    int totalCount = 0;

    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('prices')
          .get();

      totalCount = querySnapshot.docs.length;

      for (final doc in querySnapshot.docs) {
        final docId = doc.id;
        final data = doc.data();

        if (data is Map<String, dynamic>) {
          bool needsUpdate = false;
          Map<String, dynamic> updateData = {};

          final city = data['city'];
          if (city != null && city is String) {
            final lowerCity = city.toLowerCase();
            if (city != lowerCity) {
              updateData['city'] = lowerCity;
              needsUpdate = true;
            }
          }

          final productName = data['product_name'];
          if (productName != null && productName is String) {
            final lowerProductName = productName.toLowerCase();
            if (productName != lowerProductName) {
              updateData['product_name'] = lowerProductName;
              needsUpdate = true;
            }
          }

          final store = data['store'];
          if (store != null && store is String) {
            final lowerStore = store.toLowerCase();
            if (store != lowerStore) {
              updateData['store'] = lowerStore;
              needsUpdate = true;
            }
          }

          if (needsUpdate) {
            await FirebaseFirestore.instance
                .collection('prices')
                .doc(docId)
                .update(updateData);
            updatedCount++;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$updatedCount von $totalCount Einträgen erfolgreich in Kleinbuchstaben umgewandelt.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Normalisieren der Strings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/logos/alpenpreisgrenze.png', height: 60),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        elevation: 0,
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

          child: Padding(
            padding: EdgeInsets.all(AppSpacing.m),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Gemeinsam gegen den Österreich-Aufschlag.',
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppSpacing.l),
                Text(
                  'Schließ dich der AlpenPreisGrenze Community an und finde Österreich-Aufschläge '
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

                Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.m),
                  child: Container(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s),
                      child: _isLoadingTopProduct
                          ? Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            )
                          : _topProductName != null &&
                                _topAtPrice != null &&
                                _topDePrice != null &&
                                _topPercentageDiff != null &&
                                _topProductBarcode != null
                          ? GestureDetector(
                              onTap: () async {
                                try {
                                  final Product loadedProduct =
                                      await OpenFoodFactsService.fetchProduct(
                                        _topProductBarcode!,
                                      );
                                  if (loadedProduct.barcode != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ComparisonScreen(
                                          product: loadedProduct,
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Produkt mit Barcode $_topProductBarcode konnte nicht geladen werden.',
                                        ),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  print(
                                    "Fehler beim Laden des Produkts aus OpenFoodFacts: $e",
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Fehler beim Laden des Produkts: $e',
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(height: AppSpacing.l),
                                  Text(
                                    'Anwärter auf den "Grenzenlose Gier" Award ${formatMonthYear(DateTime.now())}:',
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  'Produkt: ${_getDisplayString(_topAtQuantity)} ${_getDisplayString(_topProductName)}',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.titleMedium,
                                                ),
                                              ),

                                              Icon(
                                                Icons.arrow_forward_ios,
                                                size: 16,
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant
                                                    .withOpacity(0.6),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: AppSpacing.xs),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              if (_topProductImageUrl != null)
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.s,
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.0,
                                                        ),
                                                    child: Image.network(
                                                      _topProductImageUrl!,
                                                      width: 60,
                                                      height: 60,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Icon(
                                                              Icons
                                                                  .image_not_supported,
                                                              size: 40,
                                                              color:
                                                                  Colors.grey,
                                                            );
                                                          },
                                                    ),
                                                  ),
                                                )
                                              else
                                                Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: AppSpacing.s,
                                                  ),
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        SizedBox(width: 20),
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

                                                        if (_topAtCity != null)
                                                          Text(
                                                            '${_getDisplayString(_topAtCity)}',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[800],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    SizedBox(height: AppSpacing.xs),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 20.0,
                                                      ),
                                                      child: RichText(
                                                        text: TextSpan(
                                                          style:
                                                              DefaultTextStyle.of(
                                                                context,
                                                              ).style,
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
                                                                    1.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Theme.of(
                                                                  context,
                                                                ).colorScheme.onSurface,
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
                                                                    0.75,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                color: Theme.of(context)
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 20.0,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          _buildStoreLogoOrText(
                                                            context,
                                                            _topAtStore ??
                                                                'Unbekannt',
                                                          ),
                                                          if (_topAtPrice !=
                                                                  null &&
                                                              _topAtQuantity !=
                                                                  null)
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

                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        SizedBox(width: 20),
                                                        Image.asset(
                                                          'assets/logos/de-fahne.png',
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
                                                            _getDisplayString(
                                                              _topDeCity,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              color: Colors
                                                                  .grey[800],
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    SizedBox(height: AppSpacing.xs),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 20.0,
                                                      ),
                                                      child: RichText(
                                                        text: TextSpan(
                                                          style:
                                                              DefaultTextStyle.of(
                                                                context,
                                                              ).style,
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
                                                                    1.5,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: Theme.of(
                                                                  context,
                                                                ).colorScheme.onSurface,
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
                                                                    0.75,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                                color: Theme.of(context)
                                                                    .colorScheme
                                                                    .onSurfaceVariant,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                        left: 20.0,
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          _buildStoreLogoOrText(
                                                            context,
                                                            _topDeStore ??
                                                                'Unbekannt',
                                                          ),
                                                          if (_topDePrice !=
                                                                  null &&
                                                              _topDeQuantity !=
                                                                  null)
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
                            )
                          : Container(
                              padding: EdgeInsets.all(AppSpacing.m),
                              child: Text(
                                'Kein aktueller Hall of Shame-Eintrag verfügbar.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.l),
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

      floatingActionButton: currentUserId == AppConstants.adminUserId
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
                            Navigator.pop(context);
                            updateUserIds(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Alte Einträge löschen'),
                          onTap: () {
                            Navigator.pop(context);
                            deleteOldEntries(context);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.text_fields),
                          title: Text('Strings normalisieren'),
                          onTap: () {
                            Navigator.pop(context);
                            _normalizeStrings(context);
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
          : null,
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

  Widget _buildStoreLogoOrText(BuildContext context, String storeName) {
    String lowerCaseName = storeName.toLowerCase();
    if (lowerCaseName == 'aldisüd') {
      lowerCaseName = 'aldisued';
    }
    String logoPath = 'assets/logos/$lowerCaseName.jpg';
    String logoPathUpper = 'assets/logos/$lowerCaseName.JPG';

    return Image.asset(
      logoPath,
      height: 32,
      width: 72,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          logoPathUpper,
          height: 32,
          width: 72,
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

  Widget _buildPricePerUnitInfo(double price, String quantity) {
    final pricePerUnit = calculatePricePerUnit(price, quantity);
    final displayUnit = getDisplayUnit(quantity) ?? 'Stück';

    if (pricePerUnit != null) {
      return Text(
        '€${pricePerUnit.toStringAsFixed(3)} / $displayUnit',
        style: TextStyle(fontSize: 12, color: Colors.blue),
      );
    } else {
      return Text(
        'Menge: $quantity',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }
  }
}
