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
  @override
  void initState() {
    super.initState();
    _loadUserId();
    _screenshotController = ScreenshotController();
  }

  Future<void> _loadUserId() async {
    try {
      setState(() {
        _userId = _firebaseService.getCurrentUserId();
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
    if (!_dialogShown) {
      setState(() {
        _dialogShown = true;
      });

      final atPriceValue = atPrice.price;
      final dePriceValue = dePrice.price;

      final atStore = atPrice.displayStore;
      final deStore = dePrice.displayStore;

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
                Navigator.of(context).pop();
              },
              child: Text('ABBRECHEN'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showAddPriceDialog(context);
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
      if (atPrice.displayStore.isEmpty) {
        throw Exception('Der österreichische Shop ist unbekannt.');
      }

      final emailMap = await _firebaseService.getSupportEmails().first;
      print(emailMap);

      final supportEmail = emailMap[atPrice.displayStore];
      if (supportEmail == null) {
        throw Exception(
          'Keine E-Mail-Adresse für ${atPrice.displayStore} gefunden.',
        );
      }

      final emailTemplate = await _firebaseService.getEmailTemplate();
      if (emailTemplate == null) {
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

      if (atQuantityNum != null &&
          deQuantityNum != null &&
          atQuantityNum < deQuantityNum) {
        isShrinkflationDetected = true;
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
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Fehler: ${snapshot.error}');
                    }

                    final allPrices = snapshot.data ?? [];
                    final now = DateTime.now();
                    final oneMonthAgo = now.subtract(Duration(days: 365));

                    final filteredPrices = allPrices
                        .where((price) => price.timestamp.isAfter(oneMonthAgo))
                        .toList();

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

                    if (!_initialCheckDone && widget.fromScan) {
                      _initialCheckDone = true;

                      if (atPrices.isNotEmpty && dePrices.isNotEmpty) {
                        _currentATPrice.value = atPrices.first;
                        _currentDEPrice.value = dePrices.first;

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!_dialogShown) {
                            _showPriceExistsDialog(
                              atPrices.first,
                              dePrices.first,
                            );
                          }
                        });
                      } else {
                        if (atPrices.isNotEmpty)
                          _currentATPrice.value = atPrices.first;
                        if (dePrices.isNotEmpty)
                          _currentDEPrice.value = dePrices.first;
                      }
                    } else {
                      if (atPrices.isNotEmpty &&
                          _currentATPrice.value == null) {
                        _currentATPrice.value = atPrices.first;
                      }
                      if (dePrices.isNotEmpty &&
                          _currentDEPrice.value == null) {
                        _currentDEPrice.value = dePrices.first;
                      }
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
