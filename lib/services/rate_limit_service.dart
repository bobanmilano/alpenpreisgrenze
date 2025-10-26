// lib/services/rate_limit_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RateLimitService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Erweiterte Rate-Limiting-Funktion MIT Composite-Index
  static Future<Map<String, bool>> checkUserLimits(
    String userId, {
    String? actionType,
  }) async {
    try {
      final now = DateTime.now();
      final oneDayAgo = now.subtract(Duration(days: 1));
      final oneWeekAgo = now.subtract(Duration(days: 7));
      final limits = {
        'canCreatePrice': true,
        'canSubmitReview': true,
        'canChangeProfileImage': true,
      };

      // Preiserstellung max 200 pro Tag
      if (actionType == 'create_price' || actionType == null) {
        try {
          final apartmentSnapshot = await _firestore
              .collection('prices')
              .where('userId', isEqualTo: userId)
              .where('createdAt', isGreaterThan: oneDayAgo)
              .get();

          print(
            'User $userId hat ${apartmentSnapshot.docs.length} Preise in 24h',
          );
          if (apartmentSnapshot.docs.length >= 200) {
            limits['canCreatePrice'] = false;
          }
        } catch (e) {
          print('Fehler beim Prüfen der Preislimits: $e');
        }
      }

      // Profilbild-Änderung limitieren (max 1 pro Woche)
      if (actionType == 'change_profile_image' || actionType == null) {
        try {
          final userDoc = await _firestore
              .collection('users')
              .doc(userId)
              .get();

          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>?;
            if (userData != null &&
                userData.containsKey('lastProfileImageChange') &&
                userData['lastProfileImageChange'] != null) {
              final lastChange = _getDateTimeFromFirestore(
                userData['lastProfileImageChange'],
              );
              if (lastChange != null && lastChange.isAfter(oneWeekAgo)) {
                limits['canChangeProfileImage'] = false;
              }
            }
          }
        } catch (e) {
          print('Fehler beim Prüfen der Profilbild-Limits: $e');
        }
      }

      //TODO remove
       return {
        'canSubmitPrice': true,
        'canChangeProfileImage': true,
      };
      //return limits;
    } catch (e) {
      print('Allgemeiner Fehler in checkUserLimits: $e');
      // Im Zweifel erlauben
      return {
        'canSubmitPrice': true,
        'canChangeProfileImage': true,
      };
    }
  }

 
  // Hilfsfunktion zum Extrahieren von DateTime aus verschiedenen Firestore-Typen
  static DateTime? _getDateTimeFromFirestore(dynamic dateField) {
    if (dateField == null) return null;

    try {
      if (dateField is Timestamp) {
        return dateField.toDate();
      } else if (dateField is DateTime) {
        return dateField;
      } else if (dateField is String) {
        return DateTime.parse(dateField);
      } else if (dateField is int) {
        return DateTime.fromMillisecondsSinceEpoch(dateField);
      } else if (dateField is double) {
        if (dateField > 10000000000) {
          return DateTime.fromMillisecondsSinceEpoch(dateField.toInt());
        } else {
          return DateTime.fromMillisecondsSinceEpoch(
            (dateField * 1000).toInt(),
          );
        }
      }
    } catch (e) {
      print('Fehler beim Konvertieren des Datums: $e');
    }

    return null;
  }

  // Hilfsfunktionen für spezifische Prüfungen
  static Future<bool> canUserSubmitPrice(String userId) async {
    final limits = await checkUserLimits(
      userId,
      actionType: 'create_price',
    );
    print(
      'canUserCreatePrice für $userId: ${limits['canCreatePrice']}',
    );
    return limits['canCreatePrice']!;
  }

  static Future<bool> canUserChangeProfileImage(String userId) async {
    final limits = await checkUserLimits(
      userId,
      actionType: 'change_profile_image',
    );
    return limits['canChangeProfileImage']!;
  }

  // Funktion zum Aktualisieren des Profilbild-Änderungsdatums
  static Future<void> updateProfileImageChangeDate(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'lastProfileImageChange': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      print('Fehler beim Aktualisieren des Profilbild-Datums: $e');
    }
  }
}
