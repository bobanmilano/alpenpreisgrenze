// lib/screens/comparison_screen.dart
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/screens/add_price_screen.dart';
import 'package:my_price_tracker_app/theme/app_theme.dart';
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
// Importiere das Theme, falls AppSpacing verwendet wird
import 'package:my_price_tracker_app/theme/app_theme_config.dart'; 

class ComparisonScreen extends StatefulWidget {
  final Product product;
  final bool fromScan; // Parameter, um zu kennzeichnen, ob der Screen über einen Scan aufgerufen wurde

  const ComparisonScreen({Key? key, required this.product, this.fromScan = false})
      : super(key: key);

  @override
  _ComparisonScreenState createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late ScreenshotController _screenshotController;
  late String _userId; // Dynamische Benutzer-ID
  final ValueNotifier<PriceEntry?> _currentATPrice = ValueNotifier(null);
  final ValueNotifier<PriceEntry?> _currentDEPrice = ValueNotifier(null);
  bool _isFabExpanded = false; // Zustand für den aufklappbaren FAB
  bool _dialogShown = false; // Verhindert, dass der Dialog mehrfach erscheint

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _screenshotController = ScreenshotController();
  }

  Future<void> _loadUserId() async {
    try {
      setState(() {
        _userId = _firebaseService.getCurrentUserId(); // Verwende die neue Methode
      });
    } catch (e) {
      print('Fehler beim Abrufen der Benutzer-ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Abrufen der Benutzer-ID.')),
      );
    }
  }

  void _updateCurrentATPrice(PriceEntry? price) {
    _currentATPrice.value = price;
  }

  void _updateCurrentDEPrice(PriceEntry? price) {
    _currentDEPrice.value = price;
  }

  void _showPriceExistsDialog(PriceEntry atPrice, PriceEntry dePrice) {
    // Setze den Zustand, dass der Dialog gezeigt wurde, um Doppelaufrufe zu verhindern
    if (!_dialogShown) {
      setState(() {
        _dialogShown = true;
      });

      final atPriceValue = atPrice.price;
      final dePriceValue = dePrice.price;
      final atStore = atPrice.store ?? 'Unbekannt';
      final deStore = dePrice.store ?? 'Unbekannt';

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
                Navigator.of(context).pop(); // Dialog schließen
              },
              child: Text('ABBRECHEN'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dialog schließen
                _showAddPriceDialog(context); // AddPriceScreen öffnen
              },
              child: Text('PREIS HINZUFÜGEN'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _onSharePressed() async {
    final atPrice = _currentATPrice.value;
    final dePrice = _currentDEPrice.value;

    if (atPrice == null || dePrice == null) {
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
                  Navigator.pop(context);
                  await _sendComplaintEmail(atPrice, dePrice);
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Auf Social Media teilen'),
                onTap: () async {
                  Navigator.pop(context);
                  await _captureAndShareScreenshot(atPrice, dePrice);
                },
              ),
              ListTile(
                leading: Icon(Icons.screenshot),
                title: Text('Screenshot machen'),
                onTap: () async {
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
      // Überprüfen, ob der österreichische Shop bekannt ist
      if (atPrice.store == null || atPrice.store!.isEmpty) {
        throw Exception('Der österreichische Shop ist unbekannt.');
      }

      // Laden der Support-E-Mail-Adresse für den Shop
      final emailMap = await _firebaseService.getSupportEmails().first;
      final supportEmail = emailMap[atPrice.store];
      if (supportEmail == null) {
        throw Exception('Keine E-Mail-Adresse für ${atPrice.store} gefunden.');
      }

      // Laden der E-Mail-Vorlage
      final emailTemplate = await _firebaseService.getEmailTemplate();
      if (emailTemplate == null) {
        throw Exception('E-Mail-Vorlage konnte nicht geladen werden.');
      }

      // Berechnen des Preisunterschieds
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

      // Aufbau der E-Mail
      final emailBody = _buildEmailBody(
        emailTemplate,
        atPrice.store!,
        atPrice.price,
        dePrice.price,
        atProductWeight,
        deProductWeight,
        percentageDiffText,
      );

      // Erstellen der E-Mail-URL
      final emailUrl =
          'mailto:$supportEmail?subject=${Uri.encodeComponent('Preisunterschied bei ${widget.product.productName}')}&body=${Uri.encodeComponent(emailBody)}';

      // Öffnen der E-Mail-App
      if (await canLaunch(emailUrl)) {
        await launch(emailUrl);
      } else {
        throw Exception('E-Mail konnte nicht geöffnet werden.');
      }
    } catch (e) {
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
    // Formatieren der Preise
    final atPriceText = '€${atPriceValue.toStringAsFixed(2)}';
    final dePriceText = '€${dePriceValue.toStringAsFixed(2)}';

    // Prüfen, ob Shrinkflation vorliegt
    bool isShrinkflationDetected = false;
    if (atProductWeight.isNotEmpty && deProductWeight.isNotEmpty) {
      final atQuantityNum = parseQuantity(
        atProductWeight,
      ); // Hilfsfunktion zur Umwandlung in Zahl
      final deQuantityNum = parseQuantity(
        deProductWeight,
      ); // Hilfsfunktion zur Umwandlung in Zahl

      if (atQuantityNum != null &&
          deQuantityNum != null &&
          atQuantityNum < deQuantityNum) {
        isShrinkflationDetected = true;
      }
    }

    // Aufbau der E-Mail
    return [
      emailTemplate?['salutation']?.replaceAll('\$store', store),
      emailTemplate?['bodyprice']
          ?.replaceAll('\$productName', widget.product.productName ?? '')
          ?.replaceAll('\$atPriceText', atPriceText)
          ?.replaceAll('\$dePriceText', dePriceText)
          ?.replaceAll('\$percentageDiffText', percentageDiffText),
      if (isShrinkflationDetected) // Nur hinzufügen, wenn Shrinkflation erkannt wurde
        emailTemplate?['bodyshrinkflation']
            ?.replaceAll('\$atProductWeight', atProductWeight)
            ?.replaceAll('\$deProductWeight', deProductWeight),
      emailTemplate?['bodycomplaint'],
      emailTemplate?['greeting'],
    ]
        .where((part) => part != null) // Entferne null-Werte
        .join('\n\n'); // Füge die Teile mit Zeilenumbrüchen zusammen
  }

  Future<void> _captureAndShareScreenshot(
    PriceEntry atPrice,
    PriceEntry dePrice,
  ) async {
    try {
      // Erstellen des Screenshots
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        throw Exception('Screenshot konnte nicht erstellt werden.');
      }

      // Speichern des Screenshots in einem temporären Verzeichnis
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'alpenpreisgrenze_${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = '${tempDir.path}/$fileName';
      final imageFile = await File(filePath).create();
      await imageFile.writeAsBytes(imageBytes);

      // Erstellen der Teilen-Nachricht
      final shareText =
          'Preisunterschied für "${widget.product.productName}":\n'
          'Österreich: €${atPrice.price.toStringAsFixed(2)}\n'
          'Deutschland: €${dePrice.price.toStringAsFixed(2)}\n'
          '#ÖsterreichAufschlag #Preisvergleich';

      // Teilen des Screenshots mit der Nachricht
      await Share.shareXFiles([XFile(filePath)], text: shareText);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Teilen: $e')));
    }
  }

  Future<void> _captureScreenshotOnly() async {
    try {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Erstellen/Speichern des Screenshots: $e'),
        ),
      );
    }
  }

  void _showAddPriceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Preis hinzufügen'),
        content: Text('Für welches Land möchtest du einen Preis hinzufügen?'),
        actions: [
          TextButton(
            onPressed: () {
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
    // Berechne die maximale Höhe für die erste Karte
    final maxHeight = MediaQuery.of(context).size.height / 3;

    return Scaffold(
      appBar: AppBar(
        title: Text('Preisvergleich'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Screenshot(
          controller: _screenshotController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Produktinformationen - Höhe begrenzt
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight,
                ),
                child: Card(
                  // Reduzierter äußerer Rand
                  margin: EdgeInsets.all(AppSpacing.s), // z.B. 4.0
                  child: Padding(
                    // Reduziertes Padding innerhalb der Karte
                    padding: EdgeInsets.all(AppSpacing.s), // z.B. 8.0
                    child: Column(
                      children: [
                        if (widget.product.imageUrl != null)
                          Expanded( // Bild nimmt verfügbaren Platz innerhalb der Höhe ein
                            child: Image.network(
                              widget.product.imageUrl!,
                              fit: BoxFit.contain, // Bild passt sich an den Container an
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(Icons.image_not_supported, size: 100);
                              },
                            ),
                          ),
                        if (widget.product.imageUrl == null) // Falls kein Bild, Icon anzeigen
                          Icon(Icons.image_not_supported, size: 100),
                        // Reduzierter Abstand zum Text
                        SizedBox(height: AppSpacing.s), // z.B. 4.0
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
                      ],
                    ),
                  ),
                ),
              ),
              // Reduzierter Abstand zur nächsten Komponente
              SizedBox(height: AppSpacing.s), // z.B. 4.0
              StreamBuilder<List<PriceEntry>>(
                stream: _firebaseService.getAllPriceEntriesForBarcode(
                  widget.product.barcode!,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Fehler: ${snapshot.error}');
                  }

                  final allPrices = snapshot.data ?? [];
                  final now = DateTime.now();
                  final oneMonthAgo = now.subtract(Duration(days: 365));

                  // Filtere nur aktuelle Preise
                  final filteredPrices = allPrices
                      .where((price) => price.timestamp.isAfter(oneMonthAgo))
                      .toList();

                  // Sortiere AT-Preise nach Preis absteigend (höchster Preis zuerst)
                  final atPrices =
                      filteredPrices
                          .where((price) => price.country == 'Österreich')
                          .toList()
                        ..sort((a, b) => b.price.compareTo(a.price));

                  // Sortiere DE-Preise nach Preis aufsteigend (niedrigster Preis zuerst)
                  final dePrices =
                      filteredPrices
                          .where((price) => price.country == 'Deutschland')
                          .toList()
                        ..sort((a, b) => a.price.compareTo(b.price));

                  // Initialisiere _currentATPrice und _currentDEPrice
                  // Prüfe hier, *nachdem* die Listen sortiert sind, ob beide existieren
                  if (_currentATPrice.value == null && atPrices.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _currentATPrice.value = atPrices.first;
                      // Nachdem AT-Preis gesetzt wurde, prüfe auf beide und zeige ggf. Dialog
                      if (widget.fromScan && _currentATPrice.value != null && _currentDEPrice.value != null && !_dialogShown) {
                        _showPriceExistsDialog(_currentATPrice.value!, _currentDEPrice.value!);
                      }
                    });
                  }
                  if (_currentDEPrice.value == null && dePrices.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _currentDEPrice.value = dePrices.first;
                      // Nachdem DE-Preis gesetzt wurde, prüfe auf beide und zeige ggf. Dialog
                      if (widget.fromScan && _currentATPrice.value != null && _currentDEPrice.value != null && !_dialogShown) {
                        _showPriceExistsDialog(_currentATPrice.value!, _currentDEPrice.value!);
                      }
                    });
                  }

                  return Column(
            
                    children: [
                      ValueListenableBuilder<PriceEntry?>(
                        valueListenable: _currentATPrice,
                        builder: (context, atPrice, _) {
                          return ValueListenableBuilder<PriceEntry?>(
                            valueListenable: _currentDEPrice,
                            builder: (context, dePrice, _) {
                              if (atPrice == null || dePrice == null) {
                                return InfoMessage(allPrices: filteredPrices);
                              }
                              return InfoMessage(allPrices: [atPrice, dePrice]);
                            },
                          );
                        },
                      ),
                      // Reduzierter Abstand zu den PriceCards
                      SizedBox(height: AppSpacing.s), // z.B. 4.0
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
      floatingActionButton: ExpandableFab(
        onAddPressed: () {
          _showAddPriceDialog(context);
        },
        onSharePressed: () {
          final atPrice = _currentATPrice.value;
          final dePrice = _currentDEPrice.value;

          if (atPrice == null || dePrice == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Nicht genügend Daten zum Teilen verfügbar.')),
            );
            return;
          }

          _onSharePressed(); // Direkt die aktuellen Preise verwenden
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}