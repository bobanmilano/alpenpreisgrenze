// lib/screens/add_price_screen.dart
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/models/price_entry.dart';
import 'package:my_price_tracker_app/models/product.dart';
import 'package:my_price_tracker_app/services/firebase_service.dart';
import 'package:my_price_tracker_app/services/openfoodfacts_service.dart';
import 'package:path_provider/path_provider.dart';
import '../services/local_location_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Hinzugefügt für Auth-Check

class AddPriceScreen extends StatefulWidget {
  final String barcode;
  final String? targetCountry;

  const AddPriceScreen({Key? key, required this.barcode, this.targetCountry})
    : super(key: key);

  @override
  _AddPriceScreenState createState() => _AddPriceScreenState();
}

class _AddPriceScreenState extends State<AddPriceScreen> {
  Product? _product;
  bool _isLoading = true;
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late String _userId; // Dynamische Benutzer-ID

  final TextEditingController _cityController = TextEditingController();
  String? _selectedCountry;
  String? _selectedStore;

  List<String> _suggestions = [];
  bool _isSearching = false;
  bool _isSaving = false; // ✅ Neuer Zustand: Speichervorgang läuft

  File? _selectedImage;

  static const List<String> _countries = ['Österreich', 'Deutschland'];
  static const List<String> _stores = [
    'Spar',
    'Billa',
    'BillaPlus',
    'Adeg',
    'Edeka',
    'Kaufland',
    'MPreis',
    'Nah&Frisch',
    'Netto',
    'Sutterlüty',
    'REWE',
    'Lidl',
    'Penny',
    'Hofer',
    'DM',
    'AldiSüd',
  ];

  @override
  void initState() {
    super.initState();
    _loadUserId();
    if (widget.targetCountry != null) {
      _selectedCountry = widget.targetCountry;
    }
    _loadProductAndOpposingPrice();
  }

  Future<void> _loadUserId() async {
    try {
      setState(() {
        _userId = _firebaseService
            .getCurrentUserId(); // Verwende die neue Methode
      });
    } catch (e) {
      print('Fehler beim Abrufen der Benutzer-ID: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Abrufen der Benutzer-ID.')),
      );
    }
  }

  Future<void> _loadProductAndOpposingPrice() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final product = await OpenFoodFactsService.fetchProduct(widget.barcode);
      if (mounted) {
        setState(() {
          _product = product;
        });
      }

      if (widget.targetCountry != null) {
        final opposingCountry = widget.targetCountry == 'Österreich'
            ? 'Deutschland'
            : 'Österreich';
        final opposingPriceStream = _firebaseService
            .getPriceInSpecificCountryForBarcode(
              widget.barcode,
              opposingCountry,
            );
        await for (final opposingPrice in opposingPriceStream) {
          if (mounted) {
            if (opposingPrice?.quantity != null &&
                opposingPrice!.quantity!.isNotEmpty) {
              _quantityController.text = opposingPrice.quantity!;
            } else {
              if (_product?.quantity != null &&
                  _product!.quantity!.isNotEmpty) {
                _quantityController.text = _product!.quantity!;
              }
            }
            break;
          }
        }
      } else {
        if (_product?.quantity != null && _product!.quantity!.isNotEmpty) {
          _quantityController.text = _product!.quantity!;
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Produkt- oder Preisdaten: $e'),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _searchCities(String query) {
    if (_selectedCountry == null || query.length < 2) {
      setState(() {
        _suggestions = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = LocalLocationService.searchCities(query, _selectedCountry!);
    if (mounted) {
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    }
  }

  Future<void> _pickImage() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Produktfoto hinzufügen'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Text('Kamera'),
                  onTap: () {
                    _selectImage(ImageSource.camera);
                    Navigator.of(context).pop();
                  },
                ),
                Padding(padding: EdgeInsets.symmetric(vertical: 8.0)),
                GestureDetector(
                  child: Text('Galerie'),
                  onTap: () {
                    _selectImage(ImageSource.gallery);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<File> _saveToTempDir(XFile pickedFile) async {
    final tempDir = await getTemporaryDirectory();
    final tempPath = '${tempDir.path}/${pickedFile.name}';
    final file = File(tempPath);
    await file.writeAsBytes(await pickedFile.readAsBytes());
    return file;
  }

  Future<void> _selectImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = await _saveToTempDir(pickedFile);
      if (await file.exists()) {
        print(
          'Bild erfolgreich in temporärem Verzeichnis gespeichert: ${file.path}',
        );
        setState(() {
          _selectedImage = file;
        });
      } else {
        print('Fehler: Die Datei im temporären Verzeichnis existiert nicht.');
      }
    } else {
      print('Kein Bild ausgewählt.');
    }
  }

  File? _resizeImage(File imageFile) {
    try {
      if (!imageFile.existsSync()) {
        print('Fehler: Die Datei zum Skalieren existiert nicht.');
        return null;
      }

      final img.Image? originalImage = img.decodeImage(
        imageFile.readAsBytesSync(),
      );
      if (originalImage == null) {
        print('Fehler beim Dekodieren des Bildes.');
        return null;
      }

      // Skalierung des Bildes
      img.Image resizedImage;
      if (originalImage.width > originalImage.height) {
        resizedImage = originalImage.width > 800
            ? img.copyResize(originalImage, width: 800)
            : originalImage;
      } else {
        resizedImage = originalImage.height > 800
            ? img.copyResize(originalImage, height: 800)
            : originalImage;
      }

      // Qualität anpassen
      int quality = 100;
      List<int> imageBytes = img.encodeJpg(resizedImage, quality: quality);
      File resizedFile = File(imageFile.path);
      resizedFile.writeAsBytesSync(imageBytes);

      while (resizedFile.lengthSync() > 50 * 1024 && quality > 10) {
        quality -= 10;
        imageBytes = img.encodeJpg(resizedImage, quality: quality);
        resizedFile.writeAsBytesSync(imageBytes);
      }

      print('Originalgröße: ${imageFile.lengthSync()} Bytes');
      print(
        'Neue Größe: ${resizedFile.lengthSync()} Bytes, Qualität: $quality',
      );
      return resizedFile;
    } catch (e) {
      print('Fehler beim Skalieren des Bildes: $e');
      return null;
    }
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      print("DEBUG: _uploadImage Methode gestartet.");
      // --- Neuer Debug-Check ---
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print(
          "DEBUG: Kein authentifizierter Benutzer zum Zeitpunkt des Uploads!",
        );
        return null; // oder handle den Fehler wie gewünscht
      } else {
        print("DEBUG: Authentifizierter Benutzer UID: ${user.uid}");
      }
      // --- Ende neuer Debug-Check ---

      if (!imageFile.existsSync()) {
        print('Fehler: Die Datei zum Hochladen existiert nicht.');
        return null;
      }

      File? scaledImage = _resizeImage(imageFile);
      if (scaledImage == null) {
        print('Fehler beim Skalieren des Bildes.');
        return null;
      }

      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${scaledImage.path.split('/').last}';
      String filePath = 'product_images/${widget.barcode}/$fileName';

      print("DEBUG: Versuche, Bild hochzuladen unter: $filePath");
      try {
        await _storage.ref(filePath).putFile(scaledImage);
        print("DEBUG: putFile erfolgreich abgeschlossen.");
        String downloadURL = await _storage.ref(filePath).getDownloadURL();
        print(
          "DEBUG: getDownloadURL erfolgreich abgeschlossen. URL: $downloadURL",
        );
        return downloadURL;
      } catch (e) {
        print('Fehler beim Hochladen des Bildes (putFile/getDownloadURL): $e');
        print('Stack trace: ');
        print(e.toString());
        return null;
      }
    } catch (e) {
      print('Fehler beim Verarbeiten des Bildes (äußerer Catch): $e');
      return null;
    }
  }

  // lib/screens/add_price_screen.dart
// ... (anderer Code) ...

Future<void> _savePrice() async {
  if (_isSaving) return;

  // ✅ Zustand sofort ändern, bevor Validierung startet
  setState(() {
    _isSaving = true;
  });

  try {
    // Grundlegende Validierungen
    if (_priceController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bitte gib einen Preis ein.')));
      setState(() {
        _isSaving = false; // ✅ Zustand zurücksetzen
      });
      return;
    }

    if (_quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte gib eine Menge ein (z.B. 400g).')),
      );
      setState(() {
        _isSaving = false; // ✅ Zustand zurücksetzen
      });
      return;
    }

    if (_cityController.text.isEmpty ||
        _selectedCountry == null ||
        _selectedStore == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte fülle alle Standortfelder aus.')),
      );
      setState(() {
        _isSaving = false; // ✅ Zustand zurücksetzen
      });
      return;
    }

    double price;
    try {
      price = double.parse(_priceController.text.replaceAll(',', '.'));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ungültiger Preis-Format.')));
      setState(() {
        _isSaving = false; // ✅ Zustand zurücksetzen
      });
      return;
    }

    // --- NICHT normalisieren: quantity, country, barcode ---
    String quantity = _quantityController.text.trim();
    String country = _selectedCountry!;
    String barcode = widget.barcode;
    // --- ENDE ---

    if (quantity.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Menge kann nicht leer sein.')));
      setState(() {
        _isSaving = false; // ✅ Zustand zurücksetzen
      });
      return;
    }

    if (_product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Produktinformationen nicht verfügbar.')),
      );
      setState(() {
        _isSaving = false; // ✅ Zustand zurücksetzen
      });
      return;
    }

    // --- Normalisieren für Speicherung und Duplikatsprüfung (nur store!) ---
    String normalizedStore = _selectedStore!.toLowerCase();
    String normalizedCity = _cityController.text.trim().toLowerCase();
    String normalizedProductName = (_product!.productName ?? 'Unbekannt').toLowerCase();
    String? normalizedBrands = _product!.brands?.toLowerCase();
    // --- ENDE ---

    // ✅ Überprüfe, ob bereits ein Eintrag existiert - mit normalisiertem 'store'
    final existingPriceEntry = await _firebaseService
        .getPriceEntryByUniqueKey(
          barcode, // NICHT normalisiert
          country, // NICHT normalisiert
          normalizedStore, // <-- Normalisiert, weil in DB als Kleinbuchstaben gespeichert
          quantity, // NICHT normalisiert
        );

    // --- NEU: Logik für das Überschreiben (Löschen & Neu-Anlegen) ---
    bool shouldOverride = false;
    String? existingDocId = null;

    if (existingPriceEntry != null) {
      final existingPrice = existingPriceEntry.price;
      final existingTimestamp = existingPriceEntry.timestamp;

      // Prüfe, ob der Eintrag älter als 6 Monate ist
      final sixMonthsAgo = DateTime.now().subtract(Duration(days: 183));
      final isOlderThanSixMonths = existingTimestamp.isBefore(sixMonthsAgo);

      // Ausnahmen für AT und DE
      bool canOverride = false;
      if (country == 'Österreich' && price > existingPrice) { // country NICHT normalisiert
        canOverride = true; // AT: Neuer Preis ist höher
      } else if (country == 'Deutschland' && price < existingPrice) { // country NICHT normalisiert
        canOverride = true; // DE: Neuer Preis ist niedriger
      }

      // Falls Überschreiben *nicht* erlaubt (z.B. niedriger Preis in AT)
      if (!isOlderThanSixMonths && !canOverride) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Für dieses Produkt bei ${_selectedStore!} in ${_selectedCountry!} ist bereits ein Eintrag vorhanden. Preis darf nicht überschrieben werden.',
            ),
          ),
        );
        setState(() {
          _isSaving = false; // ✅ Zustand zurücksetzen
        });
        return;
      }

      // Falls Überschreiben *erlaubt* ist (z.B. höherer Preis in AT oder älter als 6 Monate)
      if (isOlderThanSixMonths || canOverride) {
        shouldOverride = true;
        existingDocId = existingPriceEntry.id; // Hole die ID des bestehenden Dokuments
      }
    }
    // --- ENDE NEU ---

    // ✅ Nur wenn der Eintrag gemacht werden kann (und ggf. alter gelöscht wurde), fortfahren mit dem Bildupload
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte gib ein Bild (Kamera, Galerie) an.')),
      );
      setState(() {
        _isSaving = false; // ✅ Zustand zurücksetzen
      });
      return;
    }

    // ✅ Zeige Status: Bild wird hochgeladen
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Bild wird hochgeladen...')));
    String? productImageURL = await _uploadImage(_selectedImage!);
    if (productImageURL == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hochladen des Bildes.')),
        );
      }
      setState(() {
        _isSaving = false; // ✅ Zustand zurücksetzen
      });
      return;
    }

    // ✅ Zeige Status: Preis wird gespeichert
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Preis wird gespeichert...')));

    // ✅ Erstelle das neue Preis-Objekt mit den korrekten Werten
    //     - NICHT-normalisierte Werte für barcode, country, quantity
    //     - Normalisierte Werte für city, store, productName, brands
    final newPriceEntry = PriceEntry(
      id: '',
      barcode: barcode, // NICHT normalisiert
      productName: normalizedProductName, // <- Verwende den normalisierten Wert
      brands: normalizedBrands,           // <- Optional, aber normalisiert
      quantity: quantity,                 // <- NICHT normalisiert
      price: price,
      userId: _userId,
      city: normalizedCity,               // <- Verwende den normalisierten Wert
      country: country,                   // <- NICHT normalisiert
      store: normalizedStore,             // <- Verwende den normalisierten Wert
      productImageURL: productImageURL,
      timestamp: DateTime.now(),
    );

    // --- NEU: Falls Überschreiben aktiviert, lösche zuerst den alten Eintrag ---
    if (shouldOverride && existingDocId != null) {
      try {
        await _firebaseService.deletePriceEntryById(existingDocId);
        print("DEBUG: Altes Preis-Dokument gelöscht: $existingDocId");
      } catch (e) {
        print("Fehler beim Löschen des alten Preis-Eintrags: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen des alten Eintrags: $e')),
          );
        }
        setState(() {
          _isSaving = false; // ✅ Zustand zurücksetzen
        });
        return;
      }
    }
    // --- ENDE NEU ---

    // ✅ Speichere das neue Preis-Objekt
    final savedId = await _firebaseService.savePriceEntry(newPriceEntry);
    if (savedId != null) {
      String message = 'Preis erfolgreich gespeichert!';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        // Dieser Fall sollte jetzt unwahrscheinlicher sein, da wir vorher prüfen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Fehler beim Speichern des neuen Preises.',
            ),
          ),
        );
      }
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fehler beim Speichern: $e')));
    }
  } finally {
    // ✅ Zustand am Ende zurücksetzen
    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }
}

// ... (anderer Code) ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Preis hinzufügen')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_product != null && _product!.imageUrl != null)
                      Center(
                        child: Image.network(
                          _product!.imageUrl!,
                          width: 150,
                          height: 150,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image_not_supported, size: 100);
                          },
                        ),
                      ),
                    SizedBox(height: 16),
                    Text(
                      _product?.productName ?? 'Produktname nicht verfügbar',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text('Menge (aus OFDB): ${_product?.quantity ?? 'N/A'}'),
                    Text('Barcode: ${widget.barcode}'),
                    SizedBox(height: 16),
                    if (widget.targetCountry == null)
                      InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Land',
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountry,
                            isDense: true,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedCountry = newValue;
                                if (_product?.quantity != null &&
                                    _product!.quantity!.isNotEmpty) {
                                  _quantityController.text =
                                      _product!.quantity!;
                                }
                              });
                            },
                            items: _countries.map<DropdownMenuItem<String>>((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      )
                    else
                      Text(
                        'Land: ${widget.targetCountry!}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Preis (€)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Menge (z.B. 400g, 0.5kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: Text(
                        _selectedImage != null
                            ? 'Foto ändern'
                            : 'Produktfoto machen',
                      ),
                    ),
                    if (_selectedImage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Image.file(
                          _selectedImage!,
                          width: 200,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(Icons.image_not_supported, size: 100);
                          },
                        ),
                      ),
                    SizedBox(height: 16),
                    InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Supermarkt',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStore,
                          isDense: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedStore = newValue;
                            });
                          },
                          items: _stores.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        labelText: 'Stadt',
                        border: OutlineInputBorder(),
                        suffixIcon: _isSearching
                            ? CircularProgressIndicator()
                            : null,
                      ),
                      onChanged: (value) {
                        _searchCities(value);
                      },
                    ),
                    if (_suggestions.isNotEmpty)
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.vertical(
                            bottom: Radius.circular(4),
                          ),
                        ),
                        child: ListView.builder(
                          itemCount: _suggestions.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              title: Text(_suggestions[index]),
                              onTap: () {
                                setState(() {
                                  _cityController.text = _suggestions[index];
                                  _suggestions = [];
                                });
                              },
                            );
                          },
                        ),
                      ),
                    SizedBox(height: 16),
                    // ✅ Geänderter Speichern-Button
                    ElevatedButton(
                      onPressed: _isSaving
                          ? null
                          : _savePrice, // ✅ Deaktiviert während Speichern
                      child:
                          _isSaving // ✅ Visuelle Reaktion
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(strokeWidth: 2),
                                SizedBox(width: 8),
                                Text('Speichern...'),
                              ],
                            )
                          : Text('Preis speichern'),
                    ),
                    // ✅ Status-Text unten
                    if (_isSaving)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Bild wird optimiert und hochgeladen...',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _cityController.dispose();
    super.dispose();
  }
}
