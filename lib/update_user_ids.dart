import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:my_price_tracker_app/services/firebase_service.dart';
import 'dart:ui';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final FirebaseService _firebaseService = FirebaseService();

  late String newUserId = _firebaseService.getCurrentUserId();

  try {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('prices')
        .where('user_id', isEqualTo: 'test_user_id')
        .get();

    print(
      'Anzahl der zu aktualisierenden Einträge: ${querySnapshot.docs.length}',
    );

    for (final doc in querySnapshot.docs) {
      final docId = doc.id;
      print('Aktualisiere Dokument mit ID: $docId');

      await FirebaseFirestore.instance.collection('prices').doc(docId).update({
        'user_id': newUserId,
      });

      print('Dokument mit ID $docId erfolgreich aktualisiert.');
    }

    print('Alle Einträge wurden erfolgreich aktualisiert.');
  } catch (e) {
    print('Fehler beim Aktualisieren der Einträge: $e');
  }
}
