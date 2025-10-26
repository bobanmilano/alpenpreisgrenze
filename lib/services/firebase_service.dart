// lib/services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/price_entry.dart';

class FirebaseService {
  static const String collectionName = 'prices';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Methode zum Abrufen der aktuellen Benutzer-ID
  String getCurrentUserId() {
    final User? user = _auth.currentUser;
    if (user != null) {
      return user.uid; // Die eindeutige Firebase-Benutzer-ID
    } else {
      throw Exception('Kein Benutzer angemeldet.');
    }
  }

  // Methode zum Finden eines alten Preis-Eintrags, der überschrieben werden kann
  // WICHTIG: user_id wird NICHT als Filter verwendet
  Future<DocumentSnapshot<Map<String, dynamic>>?> findOldPriceEntryToReplace(
    String barcode,
    String country,
    double price,
  ) async {
    final oneMonthAgo = DateTime.now().subtract(Duration(days: 30));
    final querySnapshot = await _firestore
        .collection(collectionName)
        .where('barcode', isEqualTo: barcode)
        .where('country', isEqualTo: country)
        .where('price', isEqualTo: price)
        // Kein Filter für 'user_id'
        .where('timestamp', isLessThan: Timestamp.fromDate(oneMonthAgo))
        .limit(1) // Nimm nur den ersten gefundenen alten Eintrag
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    } else {
      return null;
    }
  }

  Future<PriceEntry?> getPriceEntryByUniqueKey(
    String barcode,
    String country,
    String store,
    String quantity,
  ) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('prices')
          .where('barcode', isEqualTo: barcode)
          .where('country', isEqualTo: country)
          .where('store', isEqualTo: store)
          .where('quantity', isEqualTo: quantity)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data();
        return PriceEntry.fromMap(data, querySnapshot.docs.first.id);
      }
      return null;
    } catch (e) {
      print('Fehler beim Abrufen des Preis-Eintrags: $e');
      return null;
    }
  }

  Stream<QuerySnapshot> getUserScannedPricesWithFilter(
    String userId,
    int limit, {
    required String searchQuery,
    required String activeFilter,
    DocumentSnapshot? startAfterDocument,
  }) {
    Query query = FirebaseFirestore.instance.collection('prices');

    // Filtern nach aktuellem Benutzer oder allen Benutzern
    if (activeFilter == 'meine_scans') {
      query = query.where('user_id', isEqualTo: userId);
    } else if (activeFilter == 'aktuelle_scans') {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      query = query.where('timestamp', isGreaterThanOrEqualTo: sevenDaysAgo);
    }

    // Sortierung nach dem Zeitstempel
    query = query.orderBy('timestamp', descending: true);

    // Suchfilter (nach Produktnamen oder Stadt)
    if (searchQuery.isNotEmpty) {
      query = query.where(
        'searchKeywords',
        arrayContains: searchQuery.toLowerCase(),
      );
    }

    // Begrenzung der Ergebnisse
    query = query.limit(limit);

    // Starte nach einem bestimmten Dokument
    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    return query.snapshots();
  }

  // Methode zum Abrufen der gescannten Preise eines Benutzers mit Pagination
  Stream<List<QueryDocumentSnapshot>> getUserScannedPrices(
    String userId,
    int limit, {
    DocumentSnapshot? startAfterDocument,
  }) {
    print(
      "getUserScannedPrices: Abfrage mit userId = $userId, limit = $limit, startAfterDocument = ${startAfterDocument?.id}",
    ); // ✅ Debug-Ausgabe

    Query query = _firestore
        .collection(collectionName)
        .where('user_id', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    return query.snapshots().map((snapshot) {
      print(
        "getUserScannedPrices: ${snapshot.docs.length} Dokumente gefunden (gesamt: ${snapshot.size})",
      ); // ✅ Debug-Ausgabe
      return snapshot.docs;
    });
  }

  Stream<Map<String, String>> getSupportEmails() {
    return FirebaseFirestore.instance
        .collection('supportemails')
        .snapshots()
        .map((snapshot) {
          final emailMap = <String, String>{};
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final name = data['name'] as String?;
            final email = data['email'] as String?;
            if (name != null && email != null) {
              emailMap[name] = email;
            }
          }
          return emailMap;
        });
  }

  Future<Map<String, String>?> getEmailTemplate() async {
    try {
      // Lade alle Dokumente aus der Collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('supportemailtext')
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Keine Dokumente in der supportemailtext-Collection gefunden.");
        return null;
      }

      // Nehme das erste Dokument
      final document = querySnapshot.docs.first;
      final data = document.data();
      print("Geladene Vorlage: $data"); // Debugging-Ausgabe

      return Map<String, String>.from(data);
    } catch (e) {
      print("Fehler beim Laden der E-Mail-Vorlage: $e");
      return null;
    }
  }

  // Methode zum Abrufen des günstigsten Preises für einen Barcode in einem bestimmten Land (nicht älter als 1 Monat)
  Stream<PriceEntry?> getPriceInSpecificCountryForBarcode(
    String barcode,
    String country,
  ) {
    final oneMonthAgo = DateTime.now().subtract(Duration(days: 30));
    return _firestore
        .collection(collectionName)
        .where('barcode', isEqualTo: barcode)
        .where('country', isEqualTo: country)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(oneMonthAgo))
        .orderBy(
          'price',
          descending: false,
        ) // Optional: z.B. günstigsten nehmen
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return PriceEntry.fromMap(
              snapshot.docs.first.data(),
              snapshot.docs.first.id,
            );
          } else {
            return null;
          }
        });
  }

  Stream<List<PriceEntry>> getAllPricesForCountryAndBarcode(
    String country,
    String barcode,
  ) {
    Query query = _firestore
        .collection(collectionName)
        .where('country', isEqualTo: country)
        .where('barcode', isEqualTo: barcode)
        .orderBy('timestamp', descending: true);

    return query.snapshots().map((snapshot) {
      final now = DateTime.now();
      final oneMonthAgo = now.subtract(Duration(days: 30));
      return snapshot.docs
          .map(
            (doc) =>
                PriceEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .where((price) => price.timestamp.isAfter(oneMonthAgo))
          .toList();
    });
  }

  // Methode zum Speichern/Überschreiben eines neuen Preis-Eintrags
  Future<String?> savePriceEntry(PriceEntry priceEntry) async {
    try {
      // Suche nach vorhandenem Eintrag für denselben Händler
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('barcode', isEqualTo: priceEntry.barcode)
          .where('store', isEqualTo: priceEntry.store)
          .where('country', isEqualTo: priceEntry.country)
          .where('user_id', isEqualTo: priceEntry.userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Eintrag existiert bereits
        final existingDoc = querySnapshot.docs.first;
        final existingPrice =
            (existingDoc.data() as Map<String, dynamic>)['price'] as double;
        final existingTimestamp =
            (existingDoc.data() as Map<String, dynamic>)['timestamp']
                as Timestamp;

        // Prüfe, ob überschrieben werden darf
        bool canOverride = false;
        String reason = '';

        if (priceEntry.country == 'Österreich' &&
            priceEntry.price > existingPrice) {
          canOverride = true;
          reason = 'Neuer Preis ist höher als der alte Preis.';
        } else if (priceEntry.country == 'Deutschland' &&
            priceEntry.price < existingPrice) {
          canOverride = true;
          reason = 'Neuer Preis ist niedriger als der alte Preis.';
        } else {
          // Preis darf nicht überschrieben werden
          return null; // Signalisiert, dass nicht gespeichert wurde
        }

        if (canOverride) {
          // Überschreibe den bestehenden Eintrag
          await _firestore
              .collection(collectionName)
              .doc(existingDoc.id)
              .update({
                'price': priceEntry.price,
                'quantity': priceEntry.quantity,
                'city': priceEntry.city,
                'product_image_url': priceEntry.productImageURL,
                'timestamp': FieldValue.serverTimestamp(), // Server-Zeit
              });
          return existingDoc
              .id; // Rückgabe der ID des überschriebenen Dokuments
        } else {
          // Preis darf nicht überschrieben werden
          return null; // Signalisiert, dass nicht gespeichert wurde
        }
      } else {
        // Kein bestehender Eintrag → füge neuen hinzu
        final docRef = await _firestore.collection(collectionName).add({
          'barcode': priceEntry.barcode,
          'product_name': priceEntry.productName,
          'brands': priceEntry.brands,
          'quantity': priceEntry.quantity,
          'price': priceEntry.price,
          'user_id': priceEntry.userId,
          'city': priceEntry.city,
          'country': priceEntry.country,
          'store': priceEntry.store,
          'product_image_url': priceEntry.productImageURL,
          'timestamp': FieldValue.serverTimestamp(), // Server-Zeit
        });
        return docRef.id;
      }
    } catch (e) {
      print('Fehler beim Speichern des Preises: $e');
      return null;
    }
  }

  // Methode zum Prüfen, ob ein Preis-Eintrag (für ein Land) bereits existiert und NICHT älter als 1 Monat ist
  // WICHTIG: user_id wird NICHT als Filter verwendet
  Future<bool> checkIfPriceEntryExists(
    String barcode,
    String country,
    double price,
  ) async {
    final oneMonthAgo = DateTime.now().subtract(Duration(days: 30));
    final querySnapshot = await _firestore
        .collection(collectionName)
        .where('barcode', isEqualTo: barcode)
        .where('country', isEqualTo: country)
        .where('price', isEqualTo: price)
        // Kein Filter für 'user_id'
        .where('timestamp', isGreaterThan: Timestamp.fromDate(oneMonthAgo))
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

  // Methode zum Abrufen *aller* Preis-Einträge für einen bestimmten Barcode (ohne Benutzerfilter)
  Stream<List<PriceEntry>> getAllPriceEntriesForBarcode(String barcode) {
    return _firestore
        .collection(collectionName)
        .where('barcode', isEqualTo: barcode)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PriceEntry.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  // Methode zum Abrufen des günstigsten Preises für einen Barcode in Deutschland (nicht älter als 1 Monat)
  Stream<PriceEntry?> getCheapestPriceInGermanyForBarcode(String barcode) {
    final oneMonthAgo = DateTime.now().subtract(Duration(days: 30));
    return _firestore
        .collection(collectionName)
        .where('barcode', isEqualTo: barcode)
        .where('country', isEqualTo: 'Deutschland')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(oneMonthAgo))
        .orderBy('price', descending: false)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isNotEmpty) {
            return PriceEntry.fromMap(
              snapshot.docs.first.data(),
              snapshot.docs.first.id,
            );
          } else {
            return null;
          }
        });
  }

  // Methode zum Abrufen *aller* Preis-Einträge des aktuellen Benutzers für einen Barcode
  Stream<List<PriceEntry>> getPriceEntriesForUserForBarcode(
    String userId,
    String barcode,
  ) {
    return _firestore
        .collection(collectionName)
        .where('user_id', isEqualTo: userId)
        .where('barcode', isEqualTo: barcode)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => PriceEntry.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
