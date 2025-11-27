import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/screens/add_price_screen.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
import 'package:my_price_tracker_app/utils/app_constants.dart';
import 'package:my_price_tracker_app/utils/string_utils.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../widgets/expandable_fab.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import '../models/product.dart';
import '../models/price_entry.dart';
import '../services/firebase_service.dart';
import '../utils/price_utils.dart';
import '../widgets/info_message.dart';
import '../widgets/price_card.dart';
import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';

import 'package:my_price_tracker_app/theme/app_theme_config.dart';

class ComparisonScreen extends StatefulWidget {
  final Product product;
  final bool fromScan;

  const ComparisonScreen({
    Key? key,
    required this.product,
    this.fromScan = false,
  }) : super(key: key);

  @override
  _ComparisonScreenState createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late ScreenshotController _screenshotController;
  late String _userId;
  final ValueNotifier<PriceEntry?> _currentATPrice = ValueNotifier(null);
  final ValueNotifier<PriceEntry?> _currentDEPrice = ValueNotifier(null);
  bool _isFabExpanded = false;
  bool _dialogShown = false;
  bool _initialCheckDone = false;
  List<PriceEntry> _allPrices = [];

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _screenshotController = ScreenshotController();
    print('[ComparisonScreen] initState aufgerufen - fromScan: ${widget.fromScan}');
    print('[ComparisonScreen] Product Barcode: ${widget.product.barcode}');
    print('[ComparisonScreen] Initial _currentATPrice.value: ${_currentATPrice.value}');
    print('[ComparisonScreen] Initial _currentDEPrice.value: ${_currentDEPrice.value}');
  }

  Future<void> _loadUserId() async {
    try {
      final userId = _firebaseService.getCurrentUserId();
      print('[ComparisonScreen] _loadUserId - Benutzer-ID geladen: $userId');
      setState(() {
        _userId = userId;
      });
    } catch (e) {
      print('[ComparisonScreen] Fehler beim Abrufen der Benutzer-ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Abrufen der Benutzer-ID.')),
      );
    }
  }

  void _updateCurrentATPrice(PriceEntry? price) {
    print('[ComparisonScreen] _updateCurrentATPrice aufgerufen mit: ${price?.price} in ${price?.country}');
    _currentATPrice.value = price;
    print('[ComparisonScreen] _currentATPrice.value nach Update: ${_currentATPrice.value?.price} in ${_currentATPrice.value?.country}');
  }

  void _updateCurrentDEPrice(PriceEntry? price) {
    print('[ComparisonScreen] _updateCurrentDEPrice aufgerufen mit: ${price?.price} in ${price?.country}');
    _currentDEPrice.value = price;
    print('[ComparisonScreen] _currentDEPrice.value nach Update: ${_currentDEPrice.value?.price} in ${_currentDEPrice.value?.country}');
  }

  void _showPriceExistsDialog(PriceEntry atPrice, PriceEntry dePrice) {
    print('[ComparisonScreen] _showPriceExistsDialog aufgerufen');
    print('[ComparisonScreen] AT Preis: ${atPrice.price} in ${atPrice.country} von ${atPrice.displayStore}');
    print('[ComparisonScreen] DE Preis: ${dePrice.price} in ${dePrice.country} von ${dePrice.displayStore}');
    
    if (!_dialogShown) {
      setState(() {
        _dialogShown = true;
      });

      final atPriceValue = atPrice.price;
      final dePriceValue = dePrice.price;

      final atStore = atPrice.displayStore;
      final deStore = dePrice.displayStore;

      print('[ComparisonScreen] Dialog wird angezeigt - AT: €${atPriceValue.toStringAsFixed(2)} (${atStore}), DE: €${dePriceValue.toStringAsFixed(2)} (${deStore})');

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Neuen Preis hinzufügen?'),
          content: Text(
            'Für dieses Produkt existieren bereits aktuelle Preise:\n\n'
            'Höchster Preis in Österreich: €${atPriceValue.toStringAsFixed(2)} (${atStore})\n'
            'Niedrigster Preis in Deutschland: €${dePriceValue.toStringAsFixed(2)} (${deStore})\n\n'
            'Bitte füge nur einen neuen Preis hinzu, wenn du den aktuellen Österreich-Aufschlag übertreffen möchtest, '
            'also die Preisdifferenz zum deutschen Preis noch größer ist.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                print('[ComparisonScreen] Dialog - ABBRECHEN gedrückt');
                Navigator.of(context).pop();
              },
              child: Text('ABBRECHEN'),
            ),
            TextButton(
              onPressed: () {
                print('[ComparisonScreen] Dialog - PREIS HINZUFÜGEN gedrückt');
                Navigator.of(context).pop();
                _showAddPriceDialog(context);
              },
              child: Text('PREIS HINZUFÜGEN'),
            ),
          ],
        ),
      );
    } else {
      print('[ComparisonScreen] Dialog wurde bereits gezeigt, wird übersprungen');
    }
  }

  Future<void> _onSharePressed() async {
    final atPrice = _currentATPrice.value;
    final dePrice = _currentDEPrice.value;

    print('[ComparisonScreen] _onSharePressed aufgerufen');
    print('[ComparisonScreen] Aktuelle AT Preis: ${atPrice?.price} in ${atPrice?.country}');
    print('[ComparisonScreen] Aktuelle DE Preis: ${dePrice?.price} in ${dePrice?.country}');

    if (atPrice == null || dePrice == null) {
      print('[ComparisonScreen] _onSharePressed - Nicht genügend Daten zum Teilen verfügbar');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nicht genügend Daten zum Teilen verfügbar.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.email),
                title: Text('Beschwerde-E-Mail senden'),
                onTap: () async {
                  print('[ComparisonScreen] E-Mail senden ausgewählt');
                  Navigator.pop(context);
                  await _sendComplaintEmail(atPrice, dePrice);
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Auf Social Media teilen'),
                onTap: () async {
                  print('[ComparisonScreen] Social Media teilen ausgewählt');
                  Navigator.pop(context);
                  await _captureAndShareScreenshot(atPrice, dePrice);
                },
              ),
              ListTile(
                leading: Icon(Icons.screenshot),
                title: Text('Screenshot machen'),
                onTap: () async {
                  print('[ComparisonScreen] Screenshot machen ausgewählt');
                  Navigator.pop(context);
                  await _captureScreenshotOnly();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _sendComplaintEmail(
    PriceEntry atPrice,
    PriceEntry dePrice,
  ) async {
    try {
      print('[ComparisonScreen] _sendComplaintEmail aufgerufen');
      print('[ComparisonScreen] AT Preis: ${atPrice.price} in ${atPrice.country} von ${atPrice.displayStore}');
      print('[ComparisonScreen] DE Preis: ${dePrice.price} in ${dePrice.country} von ${dePrice.displayStore}');

      if (atPrice.displayStore.isEmpty) {
        print('[ComparisonScreen] Fehler: Der österreichische Shop ist unbekannt');
        throw Exception('Der österreichische Shop ist unbekannt.');
      }

      final emailMap = await _firebaseService.getSupportEmails().first;
      print('[ComparisonScreen] Support E-Mails geladen: $emailMap');

      final supportEmail = emailMap[atPrice.displayStore];
      if (supportEmail == null) {
        print('[ComparisonScreen] Keine E-Mail-Adresse für ${atPrice.displayStore} gefunden');
        throw Exception(
          'Keine E-Mail-Adresse für ${atPrice.displayStore} gefunden.',
        );
      }

      final emailTemplate = await _firebaseService.getEmailTemplate();
      if (emailTemplate == null) {
        print('[ComparisonScreen] E-Mail-Vorlage konnte nicht geladen werden');
        throw Exception('E-Mail-Vorlage konnte nicht geladen werden.');
      }

      final atProductWeight = atPrice.quantity ?? 'N/A';
      final deProductWeight = dePrice.quantity ?? 'N/A';

      final atPricePerUnit = calculatePricePerUnit(
        atPrice.price,
        atProductWeight,
      );
      final dePricePerUnit = calculatePricePerUnit(
        dePrice.price,
        deProductWeight,
      );

      final percentageDiff = atPricePerUnit != null && dePricePerUnit != null
          ? ((atPricePerUnit - dePricePerUnit) / dePricePerUnit) * 100
          : ((atPrice.price - dePrice.price) / dePrice.price) * 100;

      final displayUnit = getDisplayUnit(atProductWeight) ?? 'Stück';
      final percentageDiffText =
          atPricePerUnit != null && dePricePerUnit != null
          ? '${percentageDiff.abs().toStringAsFixed(2)} % höher (pro $displayUnit)'
          : '${percentageDiff.abs().toStringAsFixed(2)} % höher';

      print('[ComparisonScreen] Berechnete Prozentdifferenz: $percentageDiffText');

      final emailBody = _buildEmailBody(
        emailTemplate,
        atPrice.displayStore,
        atPrice.price,
        dePrice.price,
        atProductWeight,
        deProductWeight,
        percentageDiffText,
      );

      final emailUrl =
          'mailto:$supportEmail?subject=${Uri.encodeComponent('Preisunterschied bei ${widget.product.productName}')}&body=${Uri.encodeComponent(emailBody)}';

      if (await canLaunch(emailUrl)) {
        await launch(emailUrl);
      } else {
        throw Exception('E-Mail konnte nicht geöffnet werden.');
      }
    } catch (e) {
      print('[ComparisonScreen] Fehler in _sendComplaintEmail: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler: $e')));
    }
  }

  String _buildEmailBody(
    Map<String, String>? emailTemplate,
    String store,
    double atPriceValue,
    double dePriceValue,
    String atProductWeight,
    String deProductWeight,
    String percentageDiffText,
  ) {
    final atPriceText = '€${atPriceValue.toStringAsFixed(2)}';
    final dePriceText = '€${dePriceValue.toStringAsFixed(2)}';

    bool isShrinkflationDetected = false;
    if (atProductWeight.isNotEmpty && deProductWeight.isNotEmpty) {
      final atQuantityNum = parseQuantity(atProductWeight);
      final deQuantityNum = parseQuantity(deProductWeight);

      print('[ComparisonScreen] Mengenvergleich - AT: $atQuantityNum, DE: $deQuantityNum');

      if (atQuantityNum != null &&
          deQuantityNum != null &&
          atQuantityNum < deQuantityNum) {
        isShrinkflationDetected = true;
        print('[ComparisonScreen] Shrinkflation erkannt - AT Menge kleiner als DE Menge');
      }
    }

    return [
      emailTemplate?['salutation']?.replaceAll('\$store', store),
      emailTemplate?['bodyprice']
          ?.replaceAll('\$productName', widget.product.productName ?? '')
          ?.replaceAll('\$atPriceText', atPriceText)
          ?.replaceAll('\$dePriceText', dePriceText)
          ?.replaceAll('\$percentageDiffText', percentageDiffText),
      if (isShrinkflationDetected)
        emailTemplate?['bodyshrinkflation']
            ?.replaceAll('\$atProductWeight', atProductWeight)
            ?.replaceAll('\$deProductWeight', deProductWeight),
      emailTemplate?['bodycomplaint'],
      emailTemplate?['greeting'],
    ].where((part) => part != null).join('\n\n');
  }

  Future<void> _captureAndShareScreenshot(
    PriceEntry atPrice,
    PriceEntry dePrice,
  ) async {
    try {
      print('[ComparisonScreen] _captureAndShareScreenshot aufgerufen');
      print('[ComparisonScreen] AT Preis: ${atPrice.price} in ${atPrice.country}');
      print('[ComparisonScreen] DE Preis: ${dePrice.price} in ${dePrice.country}');

      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        throw Exception('Screenshot konnte nicht erstellt werden.');
      }

      final tempDir = await getTemporaryDirectory();
      final fileName =
          'alpenpreisgrenze_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';
      final imageFile = await File(filePath).create();
      await imageFile.writeAsBytes(imageBytes);

      final shareText =
          'Österreich-Aufschlag für "${widget.product.productName}" bei ${atPrice.displayStore}:\n'
          'Österreich: €${atPrice.price.toStringAsFixed(2)} (${atPrice.quantity})\n'
          'Deutschland: €${dePrice.price.toStringAsFixed(2)} (${dePrice.quantity})\n'
          '#ÖsterreichAufschlag #Preisvergleich';

      print('[ComparisonScreen] Share Text: $shareText');

      await Share.shareXFiles([XFile(filePath)], text: shareText);
    } catch (e) {
      print('[ComparisonScreen] Fehler in _captureAndShareScreenshot: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Teilen: $e')));
    }
  }

  Future<void> _captureScreenshotOnly() async {
    try {
      print('[ComparisonScreen] _captureScreenshotOnly aufgerufen');
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        throw Exception('Screenshot konnte nicht erstellt werden.');
      }

      await FlutterImageGallerySaver.saveImage(imageBytes);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Screenshot gespeichert'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Der Screenshot wurde erfolgreich in der Galerie gespeichert.',
                ),
                SizedBox(height: 16),
                Text(
                  'Danke, dass du den Screenshot auf deinen Social-Media-Kanälen teilst '
                  'und die AlpenPreisGrenze-Community unterstützt!',
                  style: TextStyle(fontSize: 14, color: Colors.green),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Schließen'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('[ComparisonScreen] Fehler in _captureScreenshotOnly: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Erstellen/Speichern des Screenshots: $e'),
        ),
      );
    }
  }

  void _showAddPriceDialog(BuildContext context) {
    print('[ComparisonScreen] _showAddPriceDialog aufgerufen');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preis hinzufügen'),
        content: Text('Für welches Land möchtest du einen Preis hinzufügen?'),
        actions: [
          TextButton(
            onPressed: () {
              print('[ComparisonScreen] Österreich ausgewählt in Dialog');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPriceScreen(
                    barcode: widget.product.barcode!,
                    targetCountry: 'Österreich',
                  ),
                ),
              );
            },
            child: Text('Österreich'),
          ),
          TextButton(
            onPressed: () {
              print('[ComparisonScreen] Deutschland ausgewählt in Dialog');
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddPriceScreen(
                    barcode: widget.product.barcode!,
                    targetCountry: 'Deutschland',
                  ),
                ),
              );
            },
            child: Text('Deutschland'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('[ComparisonScreen] build aufgerufen');
    print('[ComparisonScreen] Aktuelle _currentATPrice.value: ${_currentATPrice.value?.price} in ${_currentATPrice.value?.country}');
    print('[ComparisonScreen] Aktuelle _currentDEPrice.value: ${_currentDEPrice.value?.price} in ${_currentDEPrice.value?.country}');

    final maxHeight = MediaQuery.of(context).size.height / 3;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Preisvergleich'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
          child: Screenshot(
            controller: _screenshotController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: Card(
                    margin: EdgeInsets.all(AppSpacing.s),
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s),
                      child: Column(
                        children: [
                          if (widget.product.imageUrl != null)
                            Expanded(
                              child: Image.network(
                                widget.product.imageUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported,
                                    size: 100,
                                  );
                                },
                              ),
                            ),
                          if (widget.product.imageUrl == null)
                            Icon(Icons.image_not_supported, size: 100),

                          SizedBox(height: AppSpacing.s),
                          Text(
                            widget.product.productName ?? 'Kein Name',
                            style: Theme.of(context).textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Hersteller: ${widget.product.brands ?? 'N/A'}',
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Menge: ${widget.product.quantity ?? 'N/A'}',
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Barcode: ${widget.product.barcode ?? 'N/A'}',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                SizedBox(height: AppSpacing.s),
                StreamBuilder<List<PriceEntry>>(
                  stream: _firebaseService.getAllPriceEntriesForBarcode(
                    widget.product.barcode!,
                  ),
                  builder: (context, snapshot) {
                    print('[ComparisonScreen] StreamBuilder - ConnectionState: ${snapshot.connectionState}');
                    print('[ComparisonScreen] StreamBuilder - HasError: ${snapshot.hasError}');
                    if (snapshot.hasError) {
                      print('[ComparisonScreen] StreamBuilder - Error: ${snapshot.error}');
                    }
                    if (snapshot.hasData) {
                      print('[ComparisonScreen] StreamBuilder - Anzahl Preise erhalten: ${snapshot.data!.length}');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      print('[ComparisonScreen] StreamBuilder - Wartet auf Daten...');
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      print('[ComparisonScreen] StreamBuilder - Fehler beim Laden der Preise: ${snapshot.error}');
                      return Text('Fehler: ${snapshot.error}');
                    }

                    final allPrices = snapshot.data ?? [];
                    _allPrices = allPrices; // Speichere die Preise lokal
                    print('[ComparisonScreen] StreamBuilder - Alle Preise erhalten: ${allPrices.length}');
                    for (int i = 0; i < allPrices.length; i++) {
                      final price = allPrices[i];
                      print('[ComparisonScreen] Preis $i: ${price.price} in ${price.country} am ${price.timestamp} von ${price.displayStore}');
                    }

                    final now = DateTime.now();
                    final oneMonthAgo = now.subtract(Duration(days: 365));

                    final filteredPrices = allPrices
                        .where((price) => price.timestamp.isAfter(oneMonthAgo))
                        .toList();

                    print('[ComparisonScreen] StreamBuilder - Preise nach Filter (letzte 365 Tage): ${filteredPrices.length}');
                    for (int i = 0; i < filteredPrices.length; i++) {
                      final price = filteredPrices[i];
                      print('[ComparisonScreen] Gefilterter Preis $i: ${price.price} in ${price.country} am ${price.timestamp}');
                    }

                    final atPrices =
                        filteredPrices
                            .where((price) => price.country == 'Österreich')
                            .toList()
                          ..sort((a, b) => b.price.compareTo(a.price));

                    final dePrices =
                        filteredPrices
                            .where((price) => price.country == 'Deutschland')
                            .toList()
                          ..sort((a, b) => a.price.compareTo(b.price));

                    print('[ComparisonScreen] StreamBuilder - AT Preise: ${atPrices.length}');
                    for (int i = 0; i < atPrices.length; i++) {
                      final price = atPrices[i];
                      print('[ComparisonScreen] AT Preis $i: ${price.price} in ${price.country} am ${price.timestamp} von ${price.displayStore}');
                    }
                    
                    print('[ComparisonScreen] StreamBuilder - DE Preise: ${dePrices.length}');
                    for (int i = 0; i < dePrices.length; i++) {
                      final price = dePrices[i];
                      print('[ComparisonScreen] DE Preis $i: ${price.price} in ${price.country} am ${price.timestamp} von ${price.displayStore}');
                    }

                    if (!_initialCheckDone && widget.fromScan) {
                      print('[ComparisonScreen] Initialer Check - fromScan ist true, initialCheckDone ist false');
                      _initialCheckDone = true;

                      if (atPrices.isNotEmpty && dePrices.isNotEmpty) {
                        print('[ComparisonScreen] Initialer Check - Beide Länder haben Preise');
                        final newATPrice = atPrices.first;
                        final newDEPrice = dePrices.first;
                        
                        print('[ComparisonScreen] Initialer Check - Setze AT Preis: ${newATPrice.price} in ${newATPrice.country}');
                        print('[ComparisonScreen] Initialer Check - Setze DE Preis: ${newDEPrice.price} in ${newDEPrice.country}');
                        
                        _currentATPrice.value = newATPrice;
                        _currentDEPrice.value = newDEPrice;
                        
                        print('[ComparisonScreen] Initialer Check - Nach Setzen - AT: ${_currentATPrice.value?.price}, DE: ${_currentDEPrice.value?.price}');

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          print('[ComparisonScreen] PostFrameCallback - Prüfe Dialog Anzeige');
                          if (!_dialogShown) {
                            print('[ComparisonScreen] PostFrameCallback - Zeige Preis Exists Dialog');
                            _showPriceExistsDialog(newATPrice, newDEPrice);
                          } else {
                            print('[ComparisonScreen] PostFrameCallback - Dialog bereits gezeigt');
                          }
                        });
                      } else {
                        print('[ComparisonScreen] Initialer Check - Keine Preise für beide Länder vorhanden');
                        if (atPrices.isNotEmpty) {
                          final newATPrice = atPrices.first;
                          print('[ComparisonScreen] Initialer Check - Setze AT Preis: ${newATPrice.price}');
                          _currentATPrice.value = newATPrice;
                        }
                        if (dePrices.isNotEmpty) {
                          final newDEPrice = dePrices.first;
                          print('[ComparisonScreen] Initialer Check - Setze DE Preis: ${newDEPrice.price}');
                          _currentDEPrice.value = newDEPrice;
                        }
                      }
                    } else {
                      print('[ComparisonScreen] Initialer Check - Kein initialer Check (fromScan: ${widget.fromScan}, initialCheckDone: $_initialCheckDone)');
                      
                      if (atPrices.isNotEmpty && _currentATPrice.value == null) {
                        final newATPrice = atPrices.first;
                        print('[ComparisonScreen] Setze AT Preis weil aktueller Wert null: ${newATPrice.price}');
                        _currentATPrice.value = newATPrice;
                      }
                      if (dePrices.isNotEmpty && _currentDEPrice.value == null) {
                        final newDEPrice = dePrices.first;
                        print('[ComparisonScreen] Setze DE Preis weil aktueller Wert null: ${newDEPrice.price}');
                        _currentDEPrice.value = newDEPrice;
                      }
                    }

                    print('[ComparisonScreen] Vor InfoMessage - AT: ${_currentATPrice.value?.price}, DE: ${_currentDEPrice.value?.price}');
                    print('[ComparisonScreen] Vor InfoMessage - AT Country: ${_currentATPrice.value?.country}, DE Country: ${_currentDEPrice.value?.country}');

                    return Column(
                      children: [
                        ValueListenableBuilder<PriceEntry?>(
                          valueListenable: _currentATPrice,
                          builder: (context, atPrice, _) {
                            print('[ComparisonScreen] ValueListenableBuilder AT - atPrice: ${atPrice?.price} in ${atPrice?.country}');
                            return ValueListenableBuilder<PriceEntry?>(
                              valueListenable: _currentDEPrice,
                              builder: (context, dePrice, _) {
                                print('[ComparisonScreen] ValueListenableBuilder DE - dePrice: ${dePrice?.price} in ${dePrice?.country}');
                                
                                if (atPrice == null || dePrice == null) {
                                  print('[ComparisonScreen] InfoMessage mit filteredPrices (null Preise)');
                                  return InfoMessage(allPrices: filteredPrices);
                                }
                                print('[ComparisonScreen] InfoMessage mit [atPrice, dePrice] (beide nicht null)');
                                return InfoMessage(
                                  allPrices: [atPrice, dePrice],
                                );
                              },
                            );
                          },
                        ),
                        SizedBox(height: AppSpacing.s),
                        Row(
                          children: [
                            Expanded(
                              child: PriceCard(
                                key: ValueKey('AT_PriceCard'),
                                title: 'Österreich',
                                targetCountry: 'Österreich',
                                barcode: widget.product.barcode!,
                                userId: _userId,
                                userPriceStream: _firebaseService
                                    .getPriceEntriesForUserForBarcode(
                                      _userId,
                                      widget.product.barcode!,
                                    ),
                                cheapestOtherPriceStream: _firebaseService
                                    .getCheapestPriceInGermanyForBarcode(
                                      widget.product.barcode!,
                                    ),
                                onNavigate: (fn) => fn(),
                                allPricesStream: _firebaseService
                                    .getAllPriceEntriesForBarcode(
                                      widget.product.barcode!,
                                    ),
                                firebaseService: _firebaseService,
                                onPriceChanged: _updateCurrentATPrice,
                                preloadedPrices: atPrices, // Übergib die bereits geladenen AT Preise
                              ),
                            ),
                            Expanded(
                              child: PriceCard(
                                key: ValueKey('DE_PriceCard'),
                                title: 'Deutschland',
                                targetCountry: 'Deutschland',
                                barcode: widget.product.barcode!,
                                userId: _userId,
                                userPriceStream: _firebaseService
                                    .getPriceEntriesForUserForBarcode(
                                      _userId,
                                      widget.product.barcode!,
                                    ),
                                cheapestOtherPriceStream: _firebaseService
                                    .getCheapestPriceInGermanyForBarcode(
                                      widget.product.barcode!,
                                    ),
                                onNavigate: (fn) => fn(),
                                allPricesStream: _firebaseService
                                    .getAllPriceEntriesForBarcode(
                                      widget.product.barcode!,
                                    ),
                                firebaseService: _firebaseService,
                                onPriceChanged: _updateCurrentDEPrice,
                                preloadedPrices: dePrices, // Übergib die bereits geladenen DE Preise
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: ExpandableFab(
        onAddPressed: () {
          print('[ComparisonScreen] FAB Add gedrückt');
          _showAddPriceDialog(context);
        },
        onSharePressed: () {
          print('[ComparisonScreen] FAB Share gedrückt');
          final atPrice = _currentATPrice.value;
          final dePrice = _currentDEPrice.value;

          print('[ComparisonScreen] FAB Share - AT Preis: ${atPrice?.price} in ${atPrice?.country}');
          print('[ComparisonScreen] FAB Share - DE Preis: ${dePrice?.price} in ${dePrice?.country}');

          if (atPrice == null || dePrice == null) {
            print('[ComparisonScreen] FAB Share - Nicht genügend Daten zum Teilen verfügbar');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Nicht genügend Daten zum Teilen verfügbar.'),
              ),
            );
            return;
          }

          _onSharePressed();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}