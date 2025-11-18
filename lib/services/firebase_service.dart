import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/price_entry.dart';

class FirebaseService {
  static const String collectionName = 'prices';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String getCurrentUserId() {
    final User? user = _auth.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      throw Exception('Kein Benutzer angemeldet.');
    }
  }

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
        .where('timestamp', isLessThan: Timestamp.fromDate(oneMonthAgo))
        .limit(1)
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

    if (activeFilter == 'meine_scans') {
      query = query.where('user_id', isEqualTo: userId);
    } else if (activeFilter == 'aktuelle_scans') {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      query = query.where('timestamp', isGreaterThanOrEqualTo: sevenDaysAgo);
    }

    if (searchQuery.isNotEmpty) {
      query = query.orderBy('product_name', descending: false);
    } else {
      query = query.orderBy('timestamp', descending: true);
    }

    if (searchQuery.isNotEmpty) {
      query = query
          .where('product_name', isGreaterThanOrEqualTo: searchQuery)
          .where('product_name', isLessThanOrEqualTo: "$searchQuery\uf8ff");
    }

    query = query.limit(limit);

    if (startAfterDocument != null) {
      query = query.startAfterDocument(startAfterDocument);
    }

    return query.snapshots();
  }

  Stream<List<QueryDocumentSnapshot>> getUserScannedPrices(
    String userId,
    int limit, {
    DocumentSnapshot? startAfterDocument,
  }) {
    print(
      "getUserScannedPrices: Abfrage mit userId = $userId, limit = $limit, startAfterDocument = ${startAfterDocument?.id}",
    );

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
      );
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
      final querySnapshot = await FirebaseFirestore.instance
          .collection('supportemailtext')
          .get();

      if (querySnapshot.docs.isEmpty) {
        print("Keine Dokumente in der supportemailtext-Collection gefunden.");
        return null;
      }

      final document = querySnapshot.docs.first;
      final data = document.data();
      print("Geladene Vorlage: $data");

      return Map<String, String>.from(data);
    } catch (e) {
      print("Fehler beim Laden der E-Mail-Vorlage: $e");
      return null;
    }
  }

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

  Future<String?> savePriceEntry(PriceEntry priceEntry) async {
    try {
      final querySnapshot = await _firestore
          .collection(collectionName)
          .where('barcode', isEqualTo: priceEntry.barcode)
          .where('store', isEqualTo: priceEntry.store)
          .where('country', isEqualTo: priceEntry.country)
          .where('user_id', isEqualTo: priceEntry.userId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final existingDoc = querySnapshot.docs.first;
        final existingPrice =
            (existingDoc.data() as Map<String, dynamic>)['price'] as double;
        final existingTimestamp =
            (existingDoc.data() as Map<String, dynamic>)['timestamp']
                as Timestamp;

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
          return null;
        }

        if (canOverride) {
          await _firestore
              .collection(collectionName)
              .doc(existingDoc.id)
              .update({
                'price': priceEntry.price,
                'quantity': priceEntry.quantity,
                'city': priceEntry.city,
                'product_image_url': priceEntry.productImageURL,
                'timestamp': FieldValue.serverTimestamp(),
              });
          return existingDoc.id;
        } else {
          return null;
        }
      } else {
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
          'timestamp': FieldValue.serverTimestamp(),
        });
        return docRef.id;
      }
    } catch (e) {
      print('Fehler beim Speichern des Preises: $e');
      return null;
    }
  }

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
        .where('timestamp', isGreaterThan: Timestamp.fromDate(oneMonthAgo))
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty;
  }

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

  Future<void> deletePriceEntryById(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('prices').doc(docId).delete();
      print("DEBUG: Preis-Eintrag mit ID $docId erfolgreich gelöscht.");
    } catch (e) {
      print("Fehler beim Löschen des Preis-Eintrags mit ID $docId: $e");
      rethrow;
    }
  }

  Future<List<PriceEntry>> searchPricesByPrefix(
    String userId,
    int limit,
    String searchQuery,
    String activeFilter,
  ) async {
    if (searchQuery.isEmpty) {
      return [];
    }

    Set<DocumentSnapshot> allResults = {};

    Query queryProduct = _firestore.collection(collectionName);
    if (activeFilter == 'meine_scans') {
      queryProduct = queryProduct.where('user_id', isEqualTo: userId);
    } else if (activeFilter == 'aktuelle_scans') {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      queryProduct = queryProduct.where(
        'timestamp',
        isGreaterThanOrEqualTo: sevenDaysAgo,
      );
    }
    queryProduct = queryProduct
        .orderBy('product_name', descending: false)
        .where('product_name', isGreaterThanOrEqualTo: searchQuery)
        .where('product_name', isLessThanOrEqualTo: "$searchQuery\uf8ff")
        .limit(limit);

    final productSnapshot = await queryProduct.get();
    allResults.addAll(productSnapshot.docs);

    Query queryStore = _firestore.collection(collectionName);
    if (activeFilter == 'meine_scans') {
      queryStore = queryStore.where('user_id', isEqualTo: userId);
    } else if (activeFilter == 'aktuelle_scans') {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      queryStore = queryStore.where(
        'timestamp',
        isGreaterThanOrEqualTo: sevenDaysAgo,
      );
    }
    queryStore = queryStore
        .orderBy('store', descending: false)
        .where('store', isGreaterThanOrEqualTo: searchQuery)
        .where('store', isLessThanOrEqualTo: "$searchQuery\uf8ff")
        .limit(limit);

    final storeSnapshot = await queryStore.get();
    allResults.addAll(storeSnapshot.docs);

    Query queryCity = _firestore.collection(collectionName);
    if (activeFilter == 'meine_scans') {
      queryCity = queryCity.where('user_id', isEqualTo: userId);
    } else if (activeFilter == 'aktuelle_scans') {
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(Duration(days: 7));
      queryCity = queryCity.where(
        'timestamp',
        isGreaterThanOrEqualTo: sevenDaysAgo,
      );
    }
    queryCity = queryCity
        .orderBy('city', descending: false)
        .where('city', isGreaterThanOrEqualTo: searchQuery)
        .where('city', isLessThanOrEqualTo: "$searchQuery\uf8ff")
        .limit(limit);

    final citySnapshot = await queryCity.get();
    allResults.addAll(citySnapshot.docs);

    List<DocumentSnapshot> sortedResults = allResults.toList();
    sortedResults.sort((a, b) {
      final timestampA =
          (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      final timestampB =
          (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
      return (timestampB?.millisecondsSinceEpoch ?? 0).compareTo(
        timestampA?.millisecondsSinceEpoch ?? 0,
      );
    });

    if (sortedResults.length > limit) {
      sortedResults = sortedResults.take(limit).toList();
    }

    return sortedResults
        .map(
          (doc) =>
              PriceEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id),
        )
        .toList();
  }

  Stream<List<PriceEntry>> getAllPricesForCurrentMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    final startTimestamp = Timestamp.fromDate(startOfMonth);
    final endTimestamp = Timestamp.fromDate(endOfMonth);

    Query query = _firestore
        .collection(collectionName)
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .where('timestamp', isLessThanOrEqualTo: endTimestamp)
        .orderBy('timestamp', descending: true);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                PriceEntry.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

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
